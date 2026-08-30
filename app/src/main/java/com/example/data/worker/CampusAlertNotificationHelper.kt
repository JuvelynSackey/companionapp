package com.example.data.worker

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.RingtoneManager
import android.os.Build
import androidx.core.app.NotificationCompat
import com.example.MainActivity

object CampusAlertNotificationHelper {

    const val CHANNEL_ID = "campus_alerts_channel"
    const val CHANNEL_NAME = "Campus Announcements & Alerts"
    const val CHANNEL_DESCRIPTION = "High-priority notifications for lecture hall changes, exam schedules, and university announcements"

    fun createNotificationChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val importance = NotificationManager.IMPORTANCE_HIGH
            val channel = NotificationChannel(CHANNEL_ID, CHANNEL_NAME, importance).apply {
                description = CHANNEL_DESCRIPTION
                enableLights(true)
                enableVibration(true)
                setShowBadge(true)
            }
            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    fun showCampusAlertNotification(
        context: Context,
        notificationId: Int,
        title: String,
        message: String,
        category: String = "CAMPUS_NEWS",
        author: String = "Campus Companion"
    ) {
        createNotificationChannel(context)

        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            putExtra("NOTIFICATION_ALERT_ID", notificationId)
            putExtra("NOTIFICATION_CATEGORY", category)
        }

        val pendingIntent = PendingIntent.getActivity(
            context,
            notificationId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val defaultSoundUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)

        val categoryIcon = when (category) {
            "VENUE_CHANGE" -> "⚡ [VENUE UPDATE]"
            "EXAM_ALERT" -> "📅 [EXAM ALERT]"
            "EMERGENCY" -> "🚨 [EMERGENCY]"
            "ACADEMIC" -> "📚 [ACADEMIC]"
            else -> "📢 [ANNOUNCEMENT]"
        }

        val builder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle("$categoryIcon $title")
            .setContentText(message)
            .setStyle(NotificationCompat.BigTextStyle().bigText("$message\n\n— Issued by: $author"))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_MESSAGE)
            .setSound(defaultSoundUri)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)

        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(notificationId, builder.build())
    }
}
