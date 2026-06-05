package dev.csakos.sailingassistant.watch

import android.view.InputDevice
import android.view.MotionEvent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

/**
 * Az óra-app fő activityje. A forgatható perem (Galaxy Watch4 Classic)
 * `AXIS_SCROLL` rotary-eseményeit egy EventChannelen továbbítja a Dart-oldalra,
 * ahol a lap-snap A↔B navigáció történik (ADR 0015 Addendum). A küszöbölést a
 * Dart `RotaryPageStepper` végzi; itt csak a nyers, előjeles deltát adjuk át.
 * A Data Layer transportot a `wearable_bridge` plugin kezeli, nem ez.
 */
class MainActivity : FlutterActivity() {
    private var rotarySink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // A perem-csatorna a watch engine-jén; a plugin csatornái mellett él meg.
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, ROTARY_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    rotarySink = events
                }

                override fun onCancel(arguments: Any?) {
                    rotarySink = null
                }
            })
    }

    /**
     * A perem `SOURCE_ROTARY_ENCODER` forrásból érkező `AXIS_SCROLL`-deltáját
     * előjelesen továbbítja (a sink a fő szálon hívható — `onGenericMotionEvent`
     * a UI-szálon fut). A többi generic motion eventet a szülőre hagyja.
     */
    override fun onGenericMotionEvent(event: MotionEvent): Boolean {
        if (event.action == MotionEvent.ACTION_SCROLL &&
            event.isFromSource(InputDevice.SOURCE_ROTARY_ENCODER)
        ) {
            val delta = event.getAxisValue(MotionEvent.AXIS_SCROLL)
            rotarySink?.success(delta.toDouble())
            return true
        }
        return super.onGenericMotionEvent(event)
    }

    private companion object {
        // Egyeznie kell a Dart `rotaryScrollChannelName`-mel.
        const val ROTARY_CHANNEL = "com.csakos.foretack/rotary"
    }
}
