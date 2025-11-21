package com.example.steppify

import android.app.*
import android.content.Context
import android.content.Intent
import android.os.Build
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

class NotificationHelper(private val context: Context) {

    companion object {
        const val CHANNEL_ID = "step_tracker_channel"
        const val NOTIFICATION_ID = 1001
        const val DAILY_GOAL = 10000 // Default daily step goal
    }

    init {
        createNotificationChannel()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "Step Tracker"
            val descriptionText = "Live step tracking updates"
            val importance = NotificationManager.IMPORTANCE_LOW
            val channel = NotificationChannel(CHANNEL_ID, name, importance).apply {
                description = descriptionText
                setShowBadge(false)
            }

            val notificationManager: NotificationManager =
                context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    fun showNotification(todaySteps: Int, sinceOpenSteps: Int, status: String) {
        val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        val pendingIntent: PendingIntent = PendingIntent.getActivity(
            context,
            0,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        // Calculate progress
        val progress = ((todaySteps.toFloat() / DAILY_GOAL) * 100).toInt().coerceIn(0, 100)
        val remaining = (DAILY_GOAL - todaySteps).coerceAtLeast(0)
        
        val statusText = when (status) {
            "walking" -> "Walking now"
            "stationary" -> "Stationary"
            "active" -> "Tracking active"
            else -> "Tracking"
        }

        // Create custom layout
        val notificationLayout = RemoteViews(context.packageName, android.R.layout.simple_list_item_1).apply {
            // We'll use the default layout but customize the text
        }

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_menu_compass)
            .setContentTitle("👟 Steppify • $statusText")
            .setContentText("$todaySteps steps today • $remaining to goal")
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .setContentIntent(pendingIntent)
            .setProgress(100, progress, false)
            .setStyle(
                NotificationCompat.BigTextStyle()
                    .setBigContentTitle("👟 Steppify • $statusText")
                    .bigText(
                        "Today: $todaySteps steps\n" +
                        "Since Open: $sinceOpenSteps steps\n" +
                        "Goal: $DAILY_GOAL steps ($progress% complete)"
                    )
            )
            .build()

        NotificationManagerCompat.from(context).notify(NOTIFICATION_ID, notification)
    }

    fun cancelNotification() {
        NotificationManagerCompat.from(context).cancel(NOTIFICATION_ID)
    }
}
