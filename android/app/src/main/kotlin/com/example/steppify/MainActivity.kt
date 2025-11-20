package com.example.steppify

import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "step_activity_channel"
    private var serviceActive = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startActivity" -> {
                    try {
                        val args = call.arguments as? Map<String, Any>
                        val todaySteps = args?.get("today") as? Int ?: 0
                        val sinceOpenSteps = args?.get("open") as? Int ?: 0
                        val sinceBootSteps = args?.get("boot") as? Int ?: 0
                        val status = args?.get("status") as? String ?: "unknown"

                        val intent = Intent(this, StepService::class.java).apply {
                            putExtra("today", todaySteps)
                            putExtra("open", sinceOpenSteps)
                            putExtra("boot", sinceBootSteps)
                            putExtra("status", status)
                        }

                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }

                        serviceActive = true
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("SERVICE_ERROR", "Failed to start service: ${e.message}", null)
                    }
                }

                "updateActivity" -> {
                    try {
                        val args = call.arguments as? Map<String, Any>
                        val todaySteps = args?.get("today") as? Int ?: 0
                        val sinceOpenSteps = args?.get("open") as? Int ?: 0
                        val sinceBootSteps = args?.get("boot") as? Int ?: 0
                        val status = args?.get("status") as? String ?: "unknown"

                        if (serviceActive) {
                            val data = StepNotificationData(
                                today = todaySteps,
                                open = sinceOpenSteps,
                                boot = sinceBootSteps,
                                status = status
                            )
                            StepService.updateNotification(data)
                        }

                        result.success(null)
                    } catch (e: Exception) {
                        result.error("SERVICE_ERROR", "Failed to update service: ${e.message}", null)
                    }
                }

                "endActivity" -> {
                    try {
                        stopService(Intent(this, StepService::class.java))
                        serviceActive = false
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("SERVICE_ERROR", "Failed to stop service: ${e.message}", null)
                    }
                }

                "registerDevice" -> {
                    // For API testing - just acknowledge
                    result.success(null)
                }

                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
