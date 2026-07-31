package com.personal.personal_app

import android.os.Bundle
import android.provider.Settings
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.personal.personal_app/brightness"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getBrightness" -> {
                    val brightness = window.attributes.screenBrightness
                    if (brightness < 0) {
                        // System default, read from system settings
                        val sysBrightness = Settings.System.getInt(
                            contentResolver,
                            Settings.System.SCREEN_BRIGHTNESS,
                            128
                        ) / 255.0
                        result.success(sysBrightness)
                    } else {
                        result.success(brightness.toDouble())
                    }
                }
                "setBrightness" -> {
                    val brightness = call.argument<Double>("brightness") ?: 1.0
                    val layoutParams = window.attributes
                    layoutParams.screenBrightness = brightness.toFloat()
                    window.attributes = layoutParams
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}
