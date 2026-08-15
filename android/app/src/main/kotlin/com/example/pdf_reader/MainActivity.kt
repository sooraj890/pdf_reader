
package com.example.pdf_reader

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {

    private val CHANNEL = "pdf_reader/file"

    private var pendingUri: String? = null

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)

        // Get PDF when app is opened from WhatsApp
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)

        // Important when app is already running
        setIntent(intent)

        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {

        if (intent == null) {
            return
        }

        if (intent.action != Intent.ACTION_VIEW) {
            return
        }

        val uri: Uri? = intent.data

        if (uri == null) {
            return
        }

        pendingUri = uri.toString()

        // If Flutter is already connected, send immediately
        flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->

            MethodChannel(
                messenger,
                CHANNEL
            ).invokeMethod(
                "openExternalFile",
                pendingUri
            )
        }
    }

    override fun configureFlutterEngine(
        flutterEngine: FlutterEngine
    ) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->

            when (call.method) {

                // Flutter asks Android to copy content:// URI
                // to a normal local file.
                "copyUriToCache" -> {

                    val uriString =
                        call.argument<String>("uri")

                    if (uriString == null) {

                        result.error(
                            "INVALID_URI",
                            "URI is null",
                            null
                        )

                        return@setMethodCallHandler
                    }

                    try {

                        val uri = Uri.parse(uriString)

                        val fileName =
                            getFileName(uri)
                                ?: "received_${System.currentTimeMillis()}.pdf"

                        val safeFileName =
                            fileName.replace(
                                Regex("[^a-zA-Z0-9._-]"),
                                "_"
                            )

                        val outputFile =
                            File(cacheDir, safeFileName)

                        contentResolver
                            .openInputStream(uri)
                            .use { input ->

                                if (input == null) {

                                    result.error(
                                        "OPEN_FAILED",
                                        "Could not open document",
                                        null
                                    )

                                    return@setMethodCallHandler
                                }

                                outputFile.outputStream()
                                    .use { output ->

                                        input.copyTo(output)
                                    }
                            }

                        result.success(
                            outputFile.absolutePath
                        )

                    } catch (e: Exception) {

                        result.error(
                            "COPY_FAILED",
                            e.message,
                            null
                        )
                    }
                }

                else -> {
                    result.notImplemented()
                }
            }
        }

        // If app was launched with a PDF before
        // Flutter was ready, send it now.
        pendingUri?.let { uri ->

            MethodChannel(
                flutterEngine.dartExecutor.binaryMessenger,
                CHANNEL
            ).invokeMethod(
                "openExternalFile",
                uri
            )

            pendingUri = null
        }
    }

    private fun getFileName(uri: Uri): String? {

        var fileName: String? = null

        try {

            contentResolver.query(
                uri,
                null,
                null,
                null,
                null
            )?.use { cursor ->

                val nameIndex =
                    cursor.getColumnIndex(
                        android.provider.OpenableColumns.DISPLAY_NAME
                    )

                if (nameIndex >= 0 && cursor.moveToFirst()) {

                    fileName =
                        cursor.getString(nameIndex)
                }
            }

        } catch (e: Exception) {

            // Ignore and use fallback
        }

        return fileName
    }
}

