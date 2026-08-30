package com.example.data.worker

import android.content.Context
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import androidx.work.workDataOf
import com.example.data.local.AppDatabase
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/**
 * WorkManager worker executed 15 minutes before a class start time to fire
 * a high-priority local notification and automatically schedule subsequent weekly occurrences.
 */
class ClassReminderNotificationWorker(
    private val appContext: Context,
    workerParams: WorkerParameters
) : CoroutineWorker(appContext, workerParams) {

    companion object {
        const val KEY_CLASS_ID = "KEY_CLASS_ID"
        const val KEY_IS_ACADEMIC_EVENT = "KEY_IS_ACADEMIC_EVENT"
        const val KEY_COURSE_CODE = "KEY_COURSE_CODE"
        const val KEY_TITLE = "KEY_TITLE"
        const val KEY_START_TIME = "KEY_START_TIME"
        const val KEY_END_TIME = "KEY_END_TIME"
        const val KEY_VENUE = "KEY_VENUE"
        const val KEY_LECTURER = "KEY_LECTURER"
        const val KEY_MINUTES_BEFORE = "KEY_MINUTES_BEFORE"
        const val KEY_DAY_OF_WEEK = "KEY_DAY_OF_WEEK"
        const val KEY_IS_RECURRING = "KEY_IS_RECURRING"
    }

    override suspend fun doWork(): Result = withContext(Dispatchers.IO) {
        try {
            val classId = inputData.getLong(KEY_CLASS_ID, -1L)
            val isAcademicEvent = inputData.getBoolean(KEY_IS_ACADEMIC_EVENT, true)
            val courseCode = inputData.getString(KEY_COURSE_CODE) ?: "CLASS"
            val title = inputData.getString(KEY_TITLE) ?: "Upcoming Lecture"
            val startTime = inputData.getString(KEY_START_TIME) ?: "08:30"
            val endTime = inputData.getString(KEY_END_TIME) ?: ""
            val venue = inputData.getString(KEY_VENUE) ?: "Main Campus Venue"
            val lecturer = inputData.getString(KEY_LECTURER) ?: ""
            val minutesBefore = inputData.getInt(KEY_MINUTES_BEFORE, 15)
            val dayOfWeek = inputData.getInt(KEY_DAY_OF_WEEK, -1)
            val isRecurring = inputData.getBoolean(KEY_IS_RECURRING, false)

            val db = AppDatabase.getDatabase(appContext)

            // Validate against current database state before firing alert
            var shouldTriggerNotification = true

            if (isAcademicEvent && classId != -1L) {
                val dbEvent = db.academicScheduleEventDao().getEventByIdSnapshot(classId)
                if (dbEvent != null) {
                    if (!dbEvent.isAlarmEnabled || dbEvent.isCompleted) {
                        shouldTriggerNotification = false
                    }
                }
            } else if (!isAcademicEvent && classId != -1L) {
                val dbCourse = db.courseScheduleDao().getScheduleById(classId)
                if (dbCourse != null) {
                    if (!dbCourse.isAlarmEnabled || dbCourse.isCancelledOrMoved) {
                        shouldTriggerNotification = false
                    }
                }
            }

            if (shouldTriggerNotification) {
                val notificationId = if (classId > 0) (classId % 100000).toInt() + 10000 else 10001

                ClassReminderNotificationHelper.showClassReminderNotification(
                    context = appContext,
                    notificationId = notificationId,
                    courseCode = courseCode,
                    title = title,
                    startTime = startTime,
                    endTime = endTime,
                    venue = venue,
                    lecturer = lecturer,
                    minutesBefore = minutesBefore
                )
            }

            // If this is a weekly recurring event, reschedule for next week's occurrence
            if (isRecurring && dayOfWeek in 1..7 && classId != -1L) {
                if (isAcademicEvent) {
                    val dbEvent = db.academicScheduleEventDao().getEventByIdSnapshot(classId)
                    if (dbEvent != null && dbEvent.isAlarmEnabled && !dbEvent.isCompleted) {
                        ClassReminderScheduler.scheduleClassReminder(appContext, dbEvent, minutesBefore)
                    }
                } else {
                    val dbCourse = db.courseScheduleDao().getScheduleById(classId)
                    if (dbCourse != null && dbCourse.isAlarmEnabled && !dbCourse.isCancelledOrMoved) {
                        ClassReminderScheduler.scheduleCourseScheduleReminder(appContext, dbCourse, minutesBefore)
                    }
                }
            }

            Result.success(
                workDataOf(
                    "STATUS" to "Notification processed",
                    "NOTIFIED" to shouldTriggerNotification,
                    "COURSE" to courseCode
                )
            )
        } catch (e: Exception) {
            Result.failure(
                workDataOf("ERROR" to (e.localizedMessage ?: "Unknown error"))
            )
        }
    }
}
