package com.example.pdf_reader

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.provider.MediaStore

class MainActivity : FlutterActivity() {

    private val CHANNEL = "app.channel.shared.data"

    private var sharedFilePath: String? = null

    // =========================
    // APP START
    // =========================
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    // =========================
    // APP RESUME / NEW INTENT
    // =========================
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    // =========================
    // INTENT HANDLER
    // =========================
    private fun handleIntent(intent: Intent?) {
        if (intent == null) return

        if (intent.action == Intent.ACTION_VIEW ||
            intent.action == Intent.ACTION_SEND
        ) {

            val uri: Uri? =
                intent.data ?: intent.clipData?.getItemAt(0)?.uri

            if (uri != null) {
                sharedFilePath = uri.toString() // 🔥 KEEP URI ONLY
            }
        }
    }
    // =========================
    // SAFE URI → PATH CONVERTER
    // =========================
    private fun resolveFilePath(uri: Uri): String? {
        return try {

            // Direct file path
            if (uri.scheme == "file") {
                return uri.path
            }

            // Content URI handling
            val projection = arrayOf(MediaStore.MediaColumns.DATA)

            val cursor = contentResolver.query(
                uri,
                projection,
                null,
                null,
                null
            )

            cursor?.use {
                val index =
                    it.getColumnIndexOrThrow(MediaStore.MediaColumns.DATA)

                if (it.moveToFirst()) {
                    return it.getString(index)
                }
            }

            // fallback
            uri.path

        } catch (e: Exception) {
            uri.path
        }
    }

    // =========================
    // FLUTTER COMMUNICATION
    // =========================
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->

            if (call.method == "getSharedFile") {
                result.success(sharedFilePath)
                sharedFilePath = null
            }
        }
    }
}