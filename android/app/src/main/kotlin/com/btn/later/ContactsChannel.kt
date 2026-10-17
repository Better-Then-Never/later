package com.btn.later

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.provider.ContactsContract
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.security.MessageDigest

/**
 * Friend suggestions from the phone's contacts (opt-in, behind a flag): reads
 * the contacts' email addresses and answers only their hashes, so no address
 * book entry ever leaves this file. Same hash as the functions use for the
 * index (functions/lib/contacts.js): SHA-256 of SALT + the lower-case email.
 * Dart side: ContactsService (lib/data/services/contacts_service.dart).
 */
class ContactsChannel(private val context: Context, messenger: BinaryMessenger) :
    MethodChannel.MethodCallHandler {
    private val channel = MethodChannel(messenger, "later.app/contacts")

    init {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "emailHashes" -> {
                val limit = call.argument<Int>("limit") ?: MAX
                try {
                    result.success(emailHashes(limit))
                } catch (e: Exception) {
                    result.error("read_failed", e.message, null)
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun emailHashes(limit: Int): List<String> {
        val granted = context.checkSelfPermission(Manifest.permission.READ_CONTACTS) ==
            PackageManager.PERMISSION_GRANTED
        if (!granted) return emptyList()
        val hashes = LinkedHashSet<String>()
        val digest = MessageDigest.getInstance("SHA-256")
        context.contentResolver.query(
            ContactsContract.CommonDataKinds.Email.CONTENT_URI,
            arrayOf(ContactsContract.CommonDataKinds.Email.ADDRESS),
            null,
            null,
            null,
        )?.use { cursor ->
            while (cursor.moveToNext() && hashes.size < limit) {
                val email = cursor.getString(0)?.trim()?.lowercase() ?: continue
                if (!email.contains('@')) continue
                val bytes = digest.digest((SALT + email).toByteArray(Charsets.UTF_8))
                hashes.add(bytes.joinToString("") { "%02x".format(it) })
            }
        }
        return hashes.toList()
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
    }

    companion object {
        const val SALT = "later-contacts-v1:"
        const val MAX = 1000
    }
}
