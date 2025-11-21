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
        val intent = packageManager.getLaunchIntentForPackage(packageName)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    
        val statusEmoji = when (status.lowercase()) {
            "walking" -> "🚶"
            "stopped", "stationary" -> "🧘"
            else -> "📊"
        }
        
        val statusText = when (status.lowercase()) {
            "walking" -> "Walking"
            "stopped", "stationary" -> "Stationary"
            else -> "Tracking"
        }

        // Use InboxStyle for always-expanded, multi-line display
        val inboxStyle = NotificationCompat.InboxStyle()
            .setBigContentTitle("$statusEmoji Step Tracking - $statusText")
            .addLine("")
            .addLine("📊 Today: $today steps")
            .addLine("🔓 Since Open: $open steps")
            .addLine("⚡ Since Boot: $boot steps")
            .addLine("")
            .setSummaryText("Live Updates")

        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Step Tracking")
            .setContentText("$today steps today")
            .setSmallIcon(android.R.drawable.ic_menu_compass)
            .setOngoing(true)
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_HIGH)  // HIGH for always expanded
            .setCategory(NotificationCompat.CATEGORY_STATUS)
            .setShowWhen(false)
            .setColorized(false)
            .setSilent(true)
            .setOnlyAlertOnce(true)
            .setStyle(inboxStyle)
    
        return builder.build()
    }
    

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Step Live Updates",
                NotificationManager.IMPORTANCE_HIGH  // HIGH for always expanded Live Updates
            ).apply {
                description = "Real-time step tracking with Live Updates"
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                setShowBadge(false)
                // Explicitly disable sound and vibration for silent updates
                setSound(null, null)
                enableVibration(false)
                enableLights(false)
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
