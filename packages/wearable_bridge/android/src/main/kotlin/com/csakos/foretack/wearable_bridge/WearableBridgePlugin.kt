package com.csakos.foretack.wearable_bridge

import android.content.Context
import com.google.android.gms.wearable.PutDataMapRequest
import com.google.android.gms.wearable.Wearable
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class WearableBridgePlugin : FlutterPlugin, MethodCallHandler {
  private lateinit var channel: MethodChannel
  private lateinit var appContext: Context

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    appContext = binding.applicationContext
    channel = MethodChannel(binding.binaryMessenger, "com.csakos.foretack/wearable")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "putRaceState" -> {
        val json = call.arguments as? String
          ?: return result.error("BAD_ARGS", "putRaceState requires a JSON String", null)
        // Latched DataItem: az utolsó állapot perzisztál, az alvó óra ébredéskor a legfrissebbet olvassa.
        val request = PutDataMapRequest.create("/race-state").apply {
          dataMap.putString("payload", json)
        }.asPutDataRequest().setUrgent()
        Wearable.getDataClient(appContext).putDataItem(request)
          .addOnSuccessListener { result.success(null) }
          .addOnFailureListener { e -> result.error("WEARABLE_FAILED", e.message, null) }
      }
      else -> result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}
