package com.example.starter_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.provider.Settings

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "starter_app/device_identity"
        ).setMethodCallHandler { call, result ->
            if (call.method != "load") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val androidId = Settings.Secure.getString(
                contentResolver,
                Settings.Secure.ANDROID_ID
            )

            result.success(
                mapOf(
                    "identifier" to androidId,
                    "kind" to "android_id",
                    "platform" to "android"
                )
            )
        }
    }
}
