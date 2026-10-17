package com.btn.later

import android.content.Context
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.MediaRecorder
import android.os.Build
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Voice messages without a plugin: records the microphone to an AAC file
 * (.m4a) and plays one file at a time. Dart side: VoiceService
 * (lib/data/services/voice_service.dart), channel "later.app/voice".
 */
class VoiceChannel(private val context: Context, messenger: BinaryMessenger) :
    MethodChannel.MethodCallHandler {
    private val channel = MethodChannel(messenger, "later.app/voice")
    private var recorder: MediaRecorder? = null
    private var recordingPath: String? = null
    private var recordingStartedAt = 0L
    private var player: MediaPlayer? = null

    init {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "start" -> {
                    start(call.argument<String>("path")!!)
                    result.success(null)
                }
                "stop" -> result.success(stop())
                "cancel" -> {
                    cancel()
                    result.success(null)
                }
                // 0..32767 since the last call (the live waveform).
                "amplitude" -> result.success(recorder?.maxAmplitude ?: 0)
                "play" -> play(call.argument<String>("path")!!, result)
                "pause" -> {
                    player?.pause()
                    result.success(null)
                }
                "resume" -> {
                    player?.start()
                    result.success(null)
                }
                "seek" -> {
                    player?.seekTo(call.argument<Int>("ms") ?: 0)
                    result.success(null)
                }
                "position" -> result.success(player?.currentPosition ?: 0)
                "stopPlayback" -> {
                    releasePlayer()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            result.error("voice", e.message, null)
        }
    }

    private fun start(path: String) {
        cancel()
        releasePlayer()
        val r = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            MediaRecorder(context)
        } else {
            @Suppress("DEPRECATION")
            MediaRecorder()
        }
        r.setAudioSource(MediaRecorder.AudioSource.MIC)
        r.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
        r.setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
        r.setAudioChannels(1)
        r.setAudioSamplingRate(44100)
        r.setAudioEncodingBitRate(64000)
        r.setOutputFile(path)
        r.prepare()
        r.start()
        recorder = r
        recordingPath = path
        recordingStartedAt = System.currentTimeMillis()
    }

    /** Stops and keeps the file; its length in milliseconds, or null. */
    private fun stop(): Int? {
        val r = recorder ?: return null
        val length = (System.currentTimeMillis() - recordingStartedAt).toInt()
        recorder = null
        return try {
            r.stop()
            length
        } catch (e: RuntimeException) {
            // Stopped right after starting: no audio was written.
            recordingPath?.let { File(it).delete() }
            null
        } finally {
            r.release()
            recordingPath = null
        }
    }

    private fun cancel() {
        val r = recorder ?: return
        recorder = null
        try {
            r.stop()
        } catch (_: RuntimeException) {
        }
        r.release()
        recordingPath?.let { File(it).delete() }
        recordingPath = null
    }

    private fun play(path: String, result: MethodChannel.Result) {
        releasePlayer()
        val p = MediaPlayer()
        p.setAudioAttributes(
            AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_MEDIA)
                .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                .build(),
        )
        p.setDataSource(path)
        p.setOnCompletionListener {
            releasePlayer()
            channel.invokeMethod("completed", null)
        }
        // One answer per call: an error after playing started ends it instead.
        var answered = false
        p.setOnPreparedListener {
            it.start()
            answered = true
            result.success(it.duration)
        }
        p.setOnErrorListener { _, what, extra ->
            releasePlayer()
            if (answered) {
                channel.invokeMethod("completed", null)
            } else {
                answered = true
                result.error("voice", "playback failed ($what, $extra)", null)
            }
            true
        }
        player = p
        p.prepareAsync()
    }

    private fun releasePlayer() {
        player?.release()
        player = null
    }

    fun dispose() {
        cancel()
        releasePlayer()
        channel.setMethodCallHandler(null)
    }
}
