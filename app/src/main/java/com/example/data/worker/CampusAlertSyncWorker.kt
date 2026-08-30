package com.example.data.worker

import android.content.Context
import androidx.work.Constraints
import androidx.work.CoroutineWorker
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import androidx.work.workDataOf
import com.example.data.local.AppDatabase
import com.example.data.local.entity.CampusAlertEntity
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.util.concurrent.TimeUnit

class CampusAlertSyncWorker(
    private val appContext: Context,
    workerParams: WorkerParameters
) : CoroutineWorker(appContext, workerParams) {

    override suspend fun doWork(): Result = withContext(Dispatchers.IO) {
        try {
            val db = AppDatabase.getDatabase(appContext)

            // Read custom input payload if triggered specifically for broadcast
            val customTitle = inputData.getString(KEY_ALERT_TITLE)
            val customMessage = inputData.getString(KEY_ALERT_MESSAGE)
            val customCategory = inputData.getString(KEY_ALERT_CATEGORY) ?: "CAMPUS_NEWS"
            val customAuthor = inputData.getString(KEY_ALERT_AUTHOR) ?: "Academic Affairs Directorate"
            val customCourseCode = inputData.getString(KEY_COURSE_CODE)

            if (!customTitle.isNullOrBlank() && !customMessage.isNullOrBlank()) {
                val newAlert = CampusAlertEntity(
                    title = customTitle,
                    message = customMessage,
                    category = customCategory,
                    author = customAuthor,
                    timestamp = System.currentTimeMillis(),
                    isPinned = true,
                    courseCode = customCourseCode,
                    isRead = false
                )
                val newId = db.campusAlertDao().insertAlert(newAlert)
                CampusAlertNotificationHelper.showCampusAlertNotification(
                    context = appContext,
                    notificationId = newId.toInt().coerceAtLeast(1001),
                    title = customTitle,
                    message = customMessage,
                    category = customCategory,
                    author = customAuthor
                )
                return@withContext Result.success(
                    workDataOf("RESULT_STATUS" to "Custom announcement published and notified.")
                )
            }

            // Periodic sync routine: check for new campus updates and broadcast notice
            val backgroundUpdates = listOf(
                CampusAlertEntity(
                    title = "⚡ Urgent Venue Update: Science Lab 3 Maintenance",
                    message = "Science Complex Lab 3 network routers are undergoing scheduled optimization. CSCD 302 practical sessions continue on local workstations.",
                    category = "VENUE_CHANGE",
                    author = "Computing Directorate",
                    timestamp = System.currentTimeMillis(),
                    isPinned = true,
                    courseCode = "CSCD 302",
                    isRead = false
                ),
                CampusAlertEntity(
                    title = "📢 Central Examination Hall Entry Protocol",
                    message = "All students appearing for finals must present valid Biometric Student IDs at the Great Hall and KAB security gates 30 minutes prior to paper start.",
                    category = "EXAM_ALERT",
                    author = "Academic Affairs Directorate",
                    timestamp = System.currentTimeMillis(),
                    isPinned = true,
                    courseCode = null,
                    isRead = false
                ),
                CampusAlertEntity(
                    title = "🌧️ Weather Advisory & Shaded Walkway Guide",
                    message = "Intermittent rainfall anticipated this afternoon. Students are advised to utilize the covered Balme-KAB connecting corridors.",
                    category = "CAMPUS_NEWS",
                    author = "Campus Safety & Transport",
                    timestamp = System.currentTimeMillis(),
                    isPinned = false,
                    courseCode = null,
                    isRead = false
                )
            )

            // Insert random fresh item if not already existing
            val sample = backgroundUpdates.random()
            val insertedId = db.campusAlertDao().insertAlert(sample)

            CampusAlertNotificationHelper.showCampusAlertNotification(
                context = appContext,
                notificationId = insertedId.toInt().coerceAtLeast(2001),
                title = sample.title,
                message = sample.message,
                category = sample.category,
                author = sample.author
            )

            Result.success(workDataOf("RESULT_STATUS" to "Background alert sync completed successfully."))
        } catch (e: Exception) {
            Result.failure(workDataOf("ERROR_MSG" to (e.message ?: "Unknown error in sync worker.")))
        }
    }

    companion object {
        const val WORK_NAME_PERIODIC = "campus_alert_periodic_sync"
        const val WORK_NAME_ONE_TIME = "campus_alert_one_time_sync"

        const val KEY_ALERT_TITLE = "key_alert_title"
        const val KEY_ALERT_MESSAGE = "key_alert_message"
        const val KEY_ALERT_CATEGORY = "key_alert_category"
        const val KEY_ALERT_AUTHOR = "key_alert_author"
        const val KEY_COURSE_CODE = "key_course_code"

        fun schedulePeriodicSync(context: Context, repeatIntervalHours: Long = 4) {
            val constraints = Constraints.Builder()
                .build()

            val periodicRequest = PeriodicWorkRequestBuilder<CampusAlertSyncWorker>(
                repeatIntervalHours, TimeUnit.HOURS
            )
                .setConstraints(constraints)
                .build()

            WorkManager.getInstance(context).enqueueUniquePeriodicWork(
                WORK_NAME_PERIODIC,
                ExistingPeriodicWorkPolicy.KEEP,
                periodicRequest
            )
        }

        fun triggerImmediateAlertSync(
            context: Context,
            title: String? = null,
            message: String? = null,
            category: String? = null,
            author: String? = null,
            courseCode: String? = null
        ) {
            val dataBuilder = workDataOf(
                KEY_ALERT_TITLE to title,
                KEY_ALERT_MESSAGE to message,
                KEY_ALERT_CATEGORY to category,
                KEY_ALERT_AUTHOR to author,
                KEY_COURSE_CODE to courseCode
            )

            val oneTimeRequest = OneTimeWorkRequestBuilder<CampusAlertSyncWorker>()
                .setInputData(dataBuilder)
                .build()

            WorkManager.getInstance(context).enqueueUniqueWork(
                WORK_NAME_ONE_TIME + "_" + System.currentTimeMillis(),
                ExistingWorkPolicy.REPLACE,
                oneTimeRequest
            )
        }
    }
}
