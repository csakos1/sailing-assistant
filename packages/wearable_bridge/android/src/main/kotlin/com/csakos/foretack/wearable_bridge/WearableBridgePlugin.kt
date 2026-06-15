package com.csakos.foretack.wearable_bridge

import android.content.Context
import android.net.Uri
import android.util.Log
import com.google.android.gms.tasks.Tasks
import com.google.android.gms.wearable.DataClient
import com.google.android.gms.wearable.DataEvent
import com.google.android.gms.wearable.DataEventBuffer
import com.google.android.gms.wearable.DataItem
import com.google.android.gms.wearable.DataMapItem
import com.google.android.gms.wearable.MessageClient
import com.google.android.gms.wearable.MessageEvent
import com.google.android.gms.wearable.PutDataMapRequest
import com.google.android.gms.wearable.PutDataRequest
import com.google.android.gms.wearable.Wearable
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

private const val WEARABLE_CHANNEL = "com.csakos.foretack/wearable"
private const val WEARABLE_EVENT_CHANNEL = "com.csakos.foretack/wearable/events"
private const val ROUND_MARK_EVENT_CHANNEL = "com.csakos.foretack/wearable/round-mark"
private const val RACE_STATE_PATH = "/race-state"
private const val ROUND_MARK_PATH = "/round-mark"
private const val PAYLOAD_KEY = "payload"
private const val SEND_ROUND_MARK = "sendRoundMark"
private const val TAG = "WearableBridge"

// Kétirányú Wearable Data Layer híd (ADR 0018 + A1, ADR 0024):
//  - push (telefon -> óra): putRaceState -> latched DataItem a /race-state path-ra;
//  - state-vétel (óra): DataClient listener + kezdeti latched olvasás -> EventChannel;
//  - parancs (óra -> telefon): sendRoundMark -> MessageClient a /round-mark path-ra;
//  - parancs-vétel (telefon): MessageClient listener -> round-mark EventChannel.
// A Wearable Tasks/listener-callbackek alapból a fő szálon érkeznek, ezért az
// EventSink hívása a platform-szálon történik (Flutter-konform).
class WearableBridgePlugin :
  FlutterPlugin,
  MethodCallHandler,
  EventChannel.StreamHandler,
  DataClient.OnDataChangedListener,
  MessageClient.OnMessageReceivedListener {

  private lateinit var channel: MethodChannel
  private lateinit var eventChannel: EventChannel
  private lateinit var roundMarkEventChannel: EventChannel
  private lateinit var appContext: Context
  private var eventSink: EventChannel.EventSink? = null
  private var roundMarkSink: EventChannel.EventSink? = null

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    appContext = binding.applicationContext
    channel = MethodChannel(binding.binaryMessenger, WEARABLE_CHANNEL)
    channel.setMethodCallHandler(this)
    eventChannel = EventChannel(binding.binaryMessenger, WEARABLE_EVENT_CHANNEL)
    eventChannel.setStreamHandler(this)
    // Parancs-vétel (telefon-oldal, ADR 0024 D3): külön EventChannel, saját
    // StreamHandlerrel. A MessageClient listenert csak akkor regisztráljuk, ha
    // valaki figyel (a telefon service-izolátuma) — az órán senki sem iratkozik
    // fel rá, ezért ott nem fut listener.
    roundMarkEventChannel =
      EventChannel(binding.binaryMessenger, ROUND_MARK_EVENT_CHANNEL)
    roundMarkEventChannel.setStreamHandler(object : EventChannel.StreamHandler {
      override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        roundMarkSink = events
        Wearable.getMessageClient(appContext)
          .addListener(this@WearableBridgePlugin)
        Log.d(TAG, "round-mark listener attached")
      }

      override fun onCancel(arguments: Any?) {
        Wearable.getMessageClient(appContext)
          .removeListener(this@WearableBridgePlugin)
        roundMarkSink = null
      }
    })
  }

  // --- Push (telefon -> óra) + parancs-küldés (óra -> telefon) ---

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "putRaceState" -> {
        val json = call.arguments as? String
          ?: return result.error("BAD_ARGS", "putRaceState requires a JSON String", null)
        // Latched DataItem: az utolsó állapot perzisztál, az alvó óra ébredéskor a legfrissebbet olvassa.
        val request = PutDataMapRequest.create(RACE_STATE_PATH).apply {
          dataMap.putString(PAYLOAD_KEY, json)
        }.asPutDataRequest().setUrgent()
        Log.d(TAG, "putRaceState -> putDataItem (${json.length} char)")
        Wearable.getDataClient(appContext).putDataItem(request)
          .addOnSuccessListener {
            Log.d(TAG, "putDataItem OK")
            result.success(null)
          }
          .addOnFailureListener { e ->
            Log.w(TAG, "putDataItem FAILED: ${e.message}")
            result.error("WEARABLE_FAILED", e.message, null)
          }
      }
      SEND_ROUND_MARK -> sendRoundMark(result)
      else -> result.notImplemented()
    }
  }

  // Óra -> telefon kézi parancs (ADR 0024 D2/D4): a connected node(ok)ra
  // egyszeri MessageClient-üzenet, üres payloaddal. Siker, ha legalább egy
  // node-ra elment; nincs node / mind hibázott -> hiba (a Dart oldal ebből
  // rajzol „nincs kapcsolat"-ot + haptic).
  private fun sendRoundMark(result: Result) {
    Wearable.getNodeClient(appContext).connectedNodes
      .addOnSuccessListener { nodes ->
        if (nodes.isEmpty()) {
          result.error("NO_NODE", "Nincs connected node (telefon)", null)
          return@addOnSuccessListener
        }
        val messageClient = Wearable.getMessageClient(appContext)
        val tasks = nodes.map { node ->
          messageClient.sendMessage(node.id, ROUND_MARK_PATH, ByteArray(0))
        }
        Tasks.whenAllComplete(tasks).addOnSuccessListener {
          if (tasks.any { it.isSuccessful }) {
            Log.d(TAG, "sendRoundMark OK (${tasks.size} node)")
            result.success(null)
          } else {
            result.error("SEND_FAILED", "sendMessage minden node-ra hibazott", null)
          }
        }
      }
      .addOnFailureListener { e ->
        result.error("NODE_FAILED", e.message, null)
      }
  }

  // --- State-vétel (óra) ---

  override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
    eventSink = events
    val dataClient = Wearable.getDataClient(appContext)
    dataClient.addListener(this)
    Log.d(TAG, "watch listener attached")
    // Kezdeti latched olvasás: a frissen megnyitott / ébredő óra azonnal a
    // legutóbbi /race-state állapotot kapja, nem várja meg a következő pusht.
    val uri = Uri.Builder()
      .scheme(PutDataRequest.WEAR_URI_SCHEME)
      .path(RACE_STATE_PATH)
      .build()
    dataClient.getDataItems(uri).addOnSuccessListener { buffer ->
      for (item in buffer) {
        emit(item)
      }
      buffer.release()
    }
  }

  override fun onCancel(arguments: Any?) {
    Wearable.getDataClient(appContext).removeListener(this)
    eventSink = null
  }

  override fun onDataChanged(dataEvents: DataEventBuffer) {
    for (event in dataEvents) {
      if (event.type == DataEvent.TYPE_CHANGED && event.dataItem.uri.path == RACE_STATE_PATH) {
        emit(event.dataItem)
      }
    }
    dataEvents.release()
  }

  // --- Parancs-vétel (telefon) ---

  // A /round-mark MessageClient-üzenetet jelzi a service-izolátumnak (payload
  // nincs — a parancs maga a jel). Csak a telefon-oldal regisztrál listenert
  // (az onListenben), ezért az órán ez nem fut.
  override fun onMessageReceived(event: MessageEvent) {
    if (event.path == ROUND_MARK_PATH) {
      Log.d(TAG, "round-mark received -> Dart")
      roundMarkSink?.success(true)
    }
  }

  // A DataItem payload-stringjét továbbítja Dart felé (a dekódolás ott történik).
  private fun emit(item: DataItem) {
    val json = DataMapItem.fromDataItem(item).dataMap.getString(PAYLOAD_KEY) ?: return
    Log.d(TAG, "emit -> Dart (${json.length} char)")
    eventSink?.success(json)
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    eventChannel.setStreamHandler(null)
    roundMarkEventChannel.setStreamHandler(null)
  }
}
