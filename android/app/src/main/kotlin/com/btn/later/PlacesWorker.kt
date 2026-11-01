package com.btn.later

import android.content.Context
import androidx.work.Constraints
import androidx.work.CoroutineWorker
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.NetworkType
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeoutOrNull
import java.util.concurrent.TimeUnit

/**
 * The place alerts (capsule v3 phase 4: "You're near …", "Welcome to …"):
 * about every half hour while they are on, runs one check in a Flutter
 * engine of its own (backgroundPlacesMain in
 * lib/app/background_places_main.dart). Needs location "all the time".
 */
class PlacesWorker(context: Context, params: WorkerParameters) :
    CoroutineWorker(context, params) {

    override suspend fun doWork(): Result = withContext(Dispatchers.Main) {
        val loader = FlutterInjector.instance().flutterLoader()
        if (!loader.initialized()) loader.startInitialization(applicationContext)
        loader.ensureInitializationComplete(applicationContext, null)
        val engine = FlutterEngine(applicationContext)
        val outcome = CompletableDeferred<Unit>()
        MethodChannel(engine.dartExecutor.binaryMessenger, "later.app/places_worker")
            .setMethodCallHandler { call, result ->
                if (call.method == "done") {
                    outcome.complete(Unit)
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
        CountryNamesChannel.attach(engine.dartExecutor.binaryMessenger)
        engine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint(
                loader.findAppBundlePath(),
                "package:later/app/background_places_main.dart",
                "backgroundPlacesMain",
            ),
        )
        // A location fix and a few reads: well within WorkManager's ten minutes.
        withTimeoutOrNull(TimeUnit.MINUTES.toMillis(3)) { outcome.await() }
        engine.destroy()
        // A missed check is simply the next one: never retried.
        Result.success()
    }

    companion object {
        private const val NAME = "place-alerts"

        fun schedule(context: Context) {
            val request = PeriodicWorkRequestBuilder<PlacesWorker>(30, TimeUnit.MINUTES)
                .setConstraints(
                    Constraints.Builder()
                        .setRequiredNetworkType(NetworkType.CONNECTED)
                        .build(),
                )
                .build()
            WorkManager.getInstance(context)
                .enqueueUniquePeriodicWork(NAME, ExistingPeriodicWorkPolicy.KEEP, request)
        }

        fun cancel(context: Context) {
            WorkManager.getInstance(context).cancelUniqueWork(NAME)
        }
    }
}
