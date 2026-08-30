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

/**
 * Helper responsible for creating the Class Reminders notification channel
 * and displaying rich 15-minute advance lecture / class notifications.
 */
object ClassReminderNotificationHelper {

    const val CHANNEL_ID = "class_reminders_channel"
    const val CHANNEL_NAME = "Class & Lecture Reminders"
    const val CHANNEL_DESCRIPTION = "15-minute advance notifications for upcoming academic lectures, labs, and study sessions"

    /**
     * Initializes the notification channel on Android 8.0 (API 26) and above.
     */
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

    /**
     * Posts a local notification to alert the student 15 minutes before their class starts.
     */
    fun showClassReminderNotification(
        context: Context,
        notificationId: Int,
        courseCode: String,
        title: String,
        startTime: String,
        endTime: String = "",
        venue: String,
        lecturer: String = "",
        minutesBefore: Int = 15
    ) {
        createNotificationChannel(context)

        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            putExtra("NOTIFICATION_SOURCE", "CLASS_REMINDER")
            putExtra("COURSE_CODE", courseCode)
            putExtra("VENUE", venue)
        }

        val pendingIntent = PendingIntent.getActivity(
            context,
            notificationId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val defaultSoundUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)

        val displayCourse = if (courseCode.isNotBlank()) "[$courseCode] " else ""
        val notificationTitle = "⏰ Class in $minutesBefore mins: $displayCourse$title"
        val timeDisplay = if (endTime.isNotBlank()) "$startTime – $endTime" else startTime
        val shortContent = "$title starts at $startTime in $venue"

        val expandedDetails = buildString {
            append("$title\n")
            append("🕒 Time: $timeDisplay\n")
            append("📍 Venue: $venue\n")
            if (lecturer.isNotBlank()) {
                append("👨‍🏫 Instructor: $lecturer\n")
            }
            append("\nYour class starts in $minutesBefore minutes. Get your materials ready and proceed to the lecture venue.")
        }

        val builder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle(notificationTitle)
            .setContentText(shortContent)
            .setStyle(NotificationCompat.BigTextStyle().bigText(expandedDetails))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_EVENT)
            .setSound(defaultSoundUri)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)

        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(notificationId, builder.build())
    }
}
