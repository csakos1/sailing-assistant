package com.csakos.foretack.wearable_bridge

import android.content.Context
import android.net.Uri
import android.util.Log
import com.google.android.gms.wearable.DataClient
import com.google.android.gms.wearable.DataEvent
import com.google.android.gms.wearable.DataEventBuffer
import com.google.android.gms.wearable.DataItem
import com.google.android.gms.wearable.DataMapItem
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
private const val RACE_STATE_PATH = "/race-state"
private const val PAYLOAD_KEY = "payload"
private const val TAG = "WearableBridge"

// Kétirányú Wearable Data Layer híd (ADR 0018 + A1):
//  - push (telefon): putRaceState -> latched DataItem a /race-state path-ra;
//  - vétel (óra): DataClient listener + kezdeti latched olvasás -> EventChannel.
// A Wearable Tasks/listener-callbackek alapból a fő szálon érkeznek, ezért az
// EventSink hívása a platform-szálon történik (Flutter-konform).
class WearableBridgePlugin :
  FlutterPlugin,
  MethodCallHandler,
  EventChannel.StreamHandler,
  DataClient.OnDataChangedListener {

  private lateinit var channel: MethodChannel
  private lateinit var eventChannel: EventChannel
  private lateinit var appContext: Context
  private var eventSink: EventChannel.EventSink? = null

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    appContext = binding.applicationContext
    channel = MethodChannel(binding.binaryMessenger, WEARABLE_CHANNEL)
    channel.setMethodCallHandler(this)
    eventChannel = EventChannel(binding.binaryMessenger, WEARABLE_EVENT_CHANNEL)
    eventChannel.setStreamHandler(this)
  }

  // --- Push (telefon -> óra) ---

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
      else -> result.notImplemented()
    }
  }

  // --- Vétel (óra) ---

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

  // A DataItem payload-stringjét továbbítja Dart felé (a dekódolás ott történik).
  private fun emit(item: DataItem) {
    val json = DataMapItem.fromDataItem(item).dataMap.getString(PAYLOAD_KEY) ?: return
    Log.d(TAG, "emit -> Dart (${json.length} char)")
    eventSink?.success(json)
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    eventChannel.setStreamHandler(null)
  }
}
