package com.btn.later

import android.content.Context
import androidx.work.BackoffPolicy
import androidx.work.Constraints
import androidx.work.CoroutineWorker
import androidx.work.ExistingWorkPolicy
import androidx.work.NetworkType
import androidx.work.OneTimeWorkRequestBuilder
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
 * Uploads capsules that wait on the phone while the app is closed: runs the
 * app's outbox once in a Flutter engine of its own
 * (backgroundUploadsMain in lib/app/background_uploads_main.dart)
 * and asks WorkManager to try again later, with growing waits, while
 * something still waits.
 */
class UploadWorker(context: Context, params: WorkerParameters) :
    CoroutineWorker(context, params) {

    override suspend fun doWork(): Result = withContext(Dispatchers.Main) {
        val loader = FlutterInjector.instance().flutterLoader()
        if (!loader.initialized()) loader.startInitialization(applicationContext)
        loader.ensureInitializationComplete(applicationContext, null)
        val engine = FlutterEngine(applicationContext)
        val outcome = CompletableDeferred<Int>()
        MethodChannel(engine.dartExecutor.binaryMessenger, "later.app/uploads_worker")
            .setMethodCallHandler { call, result ->
                if (call.method == "done") {
                    outcome.complete((call.arguments as? Number)?.toInt() ?: -1)
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
        engine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint(
                loader.findAppBundlePath(),
                "package:later/app/background_uploads_main.dart",
                "backgroundUploadsMain",
            ),
        )
        // WorkManager stops a job after ten minutes; leave room to clean up.
        val remaining = withTimeoutOrNull(TimeUnit.MINUTES.toMillis(8)) { outcome.await() } ?: -1
        engine.destroy()
        if (remaining == 0) Result.success() else Result.retry()
    }

    companion object {
        private const val NAME = "capsule-outbox"

        fun schedule(context: Context, wifiOnly: Boolean) {
            val constraints = Constraints.Builder()
                .setRequiredNetworkType(if (wifiOnly) NetworkType.UNMETERED else NetworkType.CONNECTED)
                .build()
            val request = OneTimeWorkRequestBuilder<UploadWorker>()
                .setConstraints(constraints)
                .setBackoffCriteria(BackoffPolicy.EXPONENTIAL, 30, TimeUnit.SECONDS)
                .build()
            WorkManager.getInstance(context)
                .enqueueUniqueWork(NAME, ExistingWorkPolicy.REPLACE, request)
        }

        fun cancel(context: Context) {
            WorkManager.getInstance(context).cancelUniqueWork(NAME)
        }
    }
}
