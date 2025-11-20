package com.example.steppify

import android.app.*
import android.content.Intent
import android.os.IBinder
import android.os.Build
import androidx.core.app.NotificationCompat

class StepService : Service() {

    companion object {
        const val CHANNEL_ID = "step_live_channel"
        const val NOTIFICATION_ID = 101
        
        // Static reference to update from MainActivity
        private var instance: StepService? = null
        
        fun updateNotification(data: StepNotificationData) {
            instance?.updateNotificationInternal(data)
        }
    }

    private var today = 0
    private var open = 0
    private var boot = 0
    private var status = "unknown"

    override fun onCreate() {
        super.onCreate()
        instance = this
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        today = intent?.getIntExtra("today", 0) ?: 0
        open = intent?.getIntExtra("open", 0) ?: 0
        boot = intent?.getIntExtra("boot", 0) ?: 0
        status = intent?.getStringExtra("status") ?: "unknown"

        val notification = buildNotification()
        startForeground(NOTIFICATION_ID, notification)

        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        super.onDestroy()
        instance = null
    }

    private fun updateNotificationInternal(data: StepNotificationData) {
        today = data.today
        open = data.open
        boot = data.boot
        status = data.status

        val notification = buildNotification()
        val manager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(NOTIFICATION_ID, notification)
    }

    private fun buildNotification(): Notification {
        // Create intent to open app when notification is tapped
        val intent = packageManager.getLaunchIntentForPackage(packageName)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Format status for display
        val statusText = when (status.lowercase()) {
            "walking" -> "🚶 Walking"
            "stopped", "stationary" -> "🧘 Stationary"
            "manual" -> "🔄 Updated"
            "start" -> "▶️ Active"
            else -> "📊 Tracking"
        }

        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            // REQUIRED: Content title (no emojis for better compatibility)
            .setContentTitle("Steppify - Step Tracking")
            
            // REQUIRED: Content text showing current steps
            .setContentText("$today steps today • $statusText")
            
            // REQUIRED: Small icon
            .setSmallIcon(android.R.drawable.ic_menu_compass)
            
            // REQUIRED: Ongoing flag for Live Updates
            .setOngoing(true)
            
            // REQUIRED: Visibility public for lock screen
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            
            // Content intent
            .setContentIntent(pendingIntent)
            
            // REQUIRED: Use BigTextStyle (one of the allowed styles)
            .setStyle(
                NotificationCompat.BigTextStyle()
                    .setBigContentTitle("Step Tracking Active")
                    .bigText(
                        "📊 Today: $today steps\n" +
                        "🔓 Since Open: $open steps\n" +
                        "⚡ Since Boot: $boot steps\n" +
                        "$statusText"
                    )
            )
            
            // REQUIRED: Priority HIGH for Live Updates
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            
            // Category for better system handling
            .setCategory(NotificationCompat.CATEGORY_STATUS)
            
            // Don't show timestamp
            .setShowWhen(false)
            
            // NOT colorized (requirement for Live Updates)
            .setColorized(false)

        return builder.build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Step Live Activity",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Live step tracking notification"
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                setShowBadge(false)
            }

            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }
}

data class StepNotificationData(
    val today: Int,
    val open: Int,
    val boot: Int,
    val status: String
)
