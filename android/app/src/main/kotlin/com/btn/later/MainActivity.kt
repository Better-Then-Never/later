package com.btn.later

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "later.app/deeplink"
    private var initialLink: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Cold start: the Dart side is not listening yet, so keep the link
        // until it asks for it with getInitialLink.
        initialLink = intent?.data?.toString()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        // Warm start: the Dart side is running and listening.
        intent.data?.toString()?.let { link ->
            flutterEngine?.let { engine ->
                MethodChannel(engine.dartExecutor.binaryMessenger, channelName)
                    .invokeMethod("handleDeepLink", link)
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInitialLink" -> {
                        result.success(initialLink)
                        initialLink = null
                    }
                    else -> result.notImplemented()
                }
            }
        // The signed-in home screen drew its first frame (StartupReport).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "later.app/startup")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "fullyDrawn" -> {
                        reportFullyDrawn()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
