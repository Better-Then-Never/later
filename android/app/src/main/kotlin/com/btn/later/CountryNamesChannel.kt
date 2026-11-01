package com.btn.later

import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * Country names in any language from the platform ("later.app/locale",
 * lib/data/services/country_names.dart): the app's engine and the place
 * alerts' background engine (PlacesWorker) both answer it.
 */
object CountryNamesChannel {
    fun attach(messenger: BinaryMessenger) {
        MethodChannel(messenger, "later.app/locale").setMethodCallHandler { call, result ->
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
    }
}
