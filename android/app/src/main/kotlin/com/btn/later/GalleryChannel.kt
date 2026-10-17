package com.btn.later

import android.content.ContentValues
import android.content.Context
import android.os.Build
import android.provider.MediaStore
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Saves a capsule photo to the phone's gallery (Pictures/Later) without a
 * plugin. Android 10 and later only: there the app may add its own pictures
 * to MediaStore without any permission; older phones answer false. Dart
 * side: GalleryService (lib/data/services/gallery_service.dart).
 */
class GalleryChannel(private val context: Context, messenger: BinaryMessenger) :
    MethodChannel.MethodCallHandler {
    private val channel = MethodChannel(messenger, "later.app/gallery")

    init {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "saveImage" -> {
                val path = call.argument<String>("path")
                val name = call.argument<String>("name") ?: "Later"
                if (path == null) {
                    result.error("bad_args", "path is missing", null)
                    return
                }
                try {
                    result.success(save(File(path), name))
                } catch (e: Exception) {
                    result.error("save_failed", e.message, null)
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun save(file: File, name: String): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q || !file.exists()) return false
        val resolver = context.contentResolver
        val values = ContentValues().apply {
            put(MediaStore.Images.Media.DISPLAY_NAME, "$name.jpg")
            put(MediaStore.Images.Media.MIME_TYPE, "image/jpeg")
            put(MediaStore.Images.Media.RELATIVE_PATH, "Pictures/Later")
            put(MediaStore.Images.Media.IS_PENDING, 1)
        }
        val uri = resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
            ?: return false
        try {
            resolver.openOutputStream(uri)?.use { out ->
                file.inputStream().use { it.copyTo(out) }
            } ?: throw IllegalStateException("no output stream")
            values.clear()
            values.put(MediaStore.Images.Media.IS_PENDING, 0)
            resolver.update(uri, values, null, null)
            return true
        } catch (e: Exception) {
            resolver.delete(uri, null, null)
            throw e
        }
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
    }
}
