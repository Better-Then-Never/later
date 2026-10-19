package com.btn.later

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "later.app/deeplink"
    private var initialLink: String? = null
    private var voice: VoiceChannel? = null
    private var gallery: GalleryChannel? = null
    private var contacts: ContactsChannel? = null

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

    // FlutterActivity reports "fully drawn" at Flutter's first frame; Later
    // reports it when the map shows its capsules (StartupReport), the time
    // to full display Android vitals should count (docs/map/COLD_START.md).
    override fun onFlutterUiDisplayed() {}

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
        // Voice messages: record and play (VoiceChannel.kt).
        voice = VoiceChannel(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
        // Capsule photos into the gallery (GalleryChannel.kt).
        gallery = GalleryChannel(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
        // Friend suggestions: hashes of the contacts' emails (ContactsChannel.kt).
        contacts = ContactsChannel(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
        // Waiting capsules uploaded while the app is closed (UploadWorker.kt).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "later.app/uploads")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "schedule" -> {
                        UploadWorker.schedule(
                            applicationContext,
                            wifiOnly = call.argument<Boolean>("wifiOnly") ?: false,
                        )
                        result.success(null)
                    }
                    "cancel" -> {
                        UploadWorker.cancel(applicationContext)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        // Whether the network costs money (uploads on Wi-Fi only).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "later.app/network")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isMetered" -> {
                        val cm = getSystemService(android.content.Context.CONNECTIVITY_SERVICE)
                            as android.net.ConnectivityManager
                        result.success(cm.isActiveNetworkMetered)
                    }
                    else -> result.notImplemented()
                }
            }
        // Country names in the app's language (the world view, B7): the
        // platform knows them for every language, no table in the app.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "later.app/locale")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "countryNames" -> {
                        val codes = call.argument<List<String>>("codes") ?: emptyList()
                        val language = java.util.Locale.forLanguageTag(
                            call.argument<String>("language") ?: "en",
                        )
                        result.success(
                            codes.associateWith { code ->
                                java.util.Locale("", code).getDisplayCountry(language)
                            },
                        )
                    }
                    else -> result.notImplemented()
                }
            }
        // The map drew its capsules (StartupReport).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "later.app/startup")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "fullyDrawn" -> {
                        reportFullyDrawn()
                        result.success(null)
                    }
                    // The app's light or dark for the launch screen of the next
                    // starts (AppearanceController): Android 12+ keeps it.
                    "nightMode" -> {
                        if (android.os.Build.VERSION.SDK_INT >= 31) {
                            val modes = getSystemService(android.app.UiModeManager::class.java)
                            modes?.setApplicationNightMode(
                                when (call.arguments as? String) {
                                    "dark" -> android.app.UiModeManager.MODE_NIGHT_YES
                                    "light" -> android.app.UiModeManager.MODE_NIGHT_NO
                                    else -> android.app.UiModeManager.MODE_NIGHT_AUTO
                                },
                            )
                        }
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        voice?.dispose()
        voice = null
        gallery?.dispose()
        gallery = null
        contacts?.dispose()
        contacts = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
