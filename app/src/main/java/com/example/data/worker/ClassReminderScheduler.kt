package com.example.data.worker

import android.content.Context
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.workDataOf
import com.example.data.local.entity.AcademicScheduleEventEntity
import com.example.data.local.entity.CourseScheduleEntity
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import java.util.concurrent.TimeUnit

/**
 * Manager and scheduler for registering, updating, and cancelling WorkManager tasks
 * that trigger local notifications exactly 15 minutes before classes and lectures start.
 */
object ClassReminderScheduler {

    const val TAG_CLASS_REMINDER = "class_reminder_tag"
    const val UNIQUE_WORK_PREFIX_ACADEMIC = "class_reminder_academic_"
    const val UNIQUE_WORK_PREFIX_COURSE = "class_reminder_course_"

    /**
     * Schedules a 15-minute advance reminder via WorkManager for an [AcademicScheduleEventEntity].
     */
    fun scheduleClassReminder(
        context: Context,
        event: AcademicScheduleEventEntity,
        minutesBefore: Int = event.reminderMinutesBefore.coerceAtLeast(1)
    ) {
        if (!event.isAlarmEnabled || event.isCompleted) {
            cancelClassReminder(context, event.id)
            return
        }

        val delayMillis = calculateInitialDelayMillis(
            dayOfWeek = event.dayOfWeek,
            eventDateIso = event.eventDate,
            startTime = event.startTime,
            minutesBefore = minutesBefore
        )

        if (delayMillis < 0) {
            // Expired date in past
            return
        }

        val workData = workDataOf(
            ClassReminderNotificationWorker.KEY_CLASS_ID to event.id,
            ClassReminderNotificationWorker.KEY_IS_ACADEMIC_EVENT to true,
            ClassReminderNotificationWorker.KEY_COURSE_CODE to event.courseCode,
            ClassReminderNotificationWorker.KEY_TITLE to event.title,
            ClassReminderNotificationWorker.KEY_START_TIME to event.startTime,
            ClassReminderNotificationWorker.KEY_END_TIME to event.endTime,
            ClassReminderNotificationWorker.KEY_VENUE to event.venue,
            ClassReminderNotificationWorker.KEY_LECTURER to event.instructorOrLead,
            ClassReminderNotificationWorker.KEY_MINUTES_BEFORE to minutesBefore,
            ClassReminderNotificationWorker.KEY_DAY_OF_WEEK to (event.dayOfWeek ?: -1),
            ClassReminderNotificationWorker.KEY_IS_RECURRING to event.isRecurring
        )

        val workRequest = OneTimeWorkRequestBuilder<ClassReminderNotificationWorker>()
            .setInitialDelay(delayMillis, TimeUnit.MILLISECONDS)
            .setInputData(workData)
            .addTag(TAG_CLASS_REMINDER)
            .addTag("event_${event.id}")
            .build()

        WorkManager.getInstance(context).enqueueUniqueWork(
            "$UNIQUE_WORK_PREFIX_ACADEMIC${event.id}",
            ExistingWorkPolicy.REPLACE,
            workRequest
        )
    }

    /**
     * Schedules a 15-minute advance reminder via WorkManager for a [CourseScheduleEntity].
     */
    fun scheduleCourseScheduleReminder(
        context: Context,
        schedule: CourseScheduleEntity,
        minutesBefore: Int = schedule.reminderMinutesBefore.coerceAtLeast(1)
    ) {
        if (!schedule.isAlarmEnabled || schedule.isCancelledOrMoved) {
            cancelCourseScheduleReminder(context, schedule.id)
            return
        }

        val delayMillis = calculateDelayForNextDayOccurrence(
            dayOfWeek = schedule.dayOfWeek,
            startTime = schedule.startTime,
            minutesBefore = minutesBefore
        )

        val workData = workDataOf(
            ClassReminderNotificationWorker.KEY_CLASS_ID to schedule.id,
            ClassReminderNotificationWorker.KEY_IS_ACADEMIC_EVENT to false,
            ClassReminderNotificationWorker.KEY_COURSE_CODE to schedule.courseCode,
            ClassReminderNotificationWorker.KEY_TITLE to schedule.courseTitle,
            ClassReminderNotificationWorker.KEY_START_TIME to schedule.startTime,
            ClassReminderNotificationWorker.KEY_END_TIME to schedule.endTime,
            ClassReminderNotificationWorker.KEY_VENUE to schedule.venue,
            ClassReminderNotificationWorker.KEY_LECTURER to schedule.lecturer,
            ClassReminderNotificationWorker.KEY_MINUTES_BEFORE to minutesBefore,
            ClassReminderNotificationWorker.KEY_DAY_OF_WEEK to schedule.dayOfWeek,
            ClassReminderNotificationWorker.KEY_IS_RECURRING to true
        )

        val workRequest = OneTimeWorkRequestBuilder<ClassReminderNotificationWorker>()
            .setInitialDelay(delayMillis, TimeUnit.MILLISECONDS)
            .setInputData(workData)
            .addTag(TAG_CLASS_REMINDER)
            .addTag("course_${schedule.id}")
            .build()

        WorkManager.getInstance(context).enqueueUniqueWork(
            "$UNIQUE_WORK_PREFIX_COURSE${schedule.id}",
            ExistingWorkPolicy.REPLACE,
            workRequest
        )
    }

    /**
     * Cancels the scheduled WorkManager reminder for an academic schedule event.
     */
    fun cancelClassReminder(context: Context, eventId: Long) {
        WorkManager.getInstance(context).cancelUniqueWork("$UNIQUE_WORK_PREFIX_ACADEMIC$eventId")
    }

    /**
     * Cancels the scheduled WorkManager reminder for a course schedule.
     */
    fun cancelCourseScheduleReminder(context: Context, scheduleId: Long) {
        WorkManager.getInstance(context).cancelUniqueWork("$UNIQUE_WORK_PREFIX_COURSE$scheduleId")
    }

    /**
     * Cancels all scheduled class reminders.
     */
    fun cancelAllClassReminders(context: Context) {
        WorkManager.getInstance(context).cancelAllWorkByTag(TAG_CLASS_REMINDER)
    }

    /**
     * Bulk-schedules advance reminders for a list of academic schedule events.
     */
    fun syncAcademicEvents(context: Context, events: List<AcademicScheduleEventEntity>) {
        events.forEach { event ->
            if (event.isAlarmEnabled && !event.isCompleted) {
                scheduleClassReminder(context, event)
            } else {
                cancelClassReminder(context, event.id)
            }
        }
    }

    /**
     * Bulk-schedules advance reminders for a list of course schedules.
     */
    fun syncCourseSchedules(context: Context, schedules: List<CourseScheduleEntity>) {
        schedules.forEach { schedule ->
            if (schedule.isAlarmEnabled && !schedule.isCancelledOrMoved) {
                scheduleCourseScheduleReminder(context, schedule)
            } else {
                cancelCourseScheduleReminder(context, schedule.id)
            }
        }
    }

    /**
     * Calculates the initial delay in milliseconds from now until [minutesBefore] minutes
     * prior to the event's start time.
     */
    fun calculateInitialDelayMillis(
        dayOfWeek: Int?,
        eventDateIso: String?,
        startTime: String,
        minutesBefore: Int = 15
    ): Long {
        if (!eventDateIso.isNullOrBlank()) {
            return calculateDelayForSpecificDate(eventDateIso, startTime, minutesBefore)
        }
        if (dayOfWeek != null && dayOfWeek in 1..7) {
            return calculateDelayForNextDayOccurrence(dayOfWeek, startTime, minutesBefore)
        }
        // Fallback default: calculate as next occurrence today
        val todayCal = Calendar.getInstance()
        val currentDay = when (todayCal.get(Calendar.DAY_OF_WEEK)) {
            Calendar.MONDAY -> 1
            Calendar.TUESDAY -> 2
            Calendar.WEDNESDAY -> 3
            Calendar.THURSDAY -> 4
            Calendar.FRIDAY -> 5
            Calendar.SATURDAY -> 6
            Calendar.SUNDAY -> 7
            else -> 1
        }
        return calculateDelayForNextDayOccurrence(currentDay, startTime, minutesBefore)
    }

    /**
     * Calculates delay in milliseconds until the next occurrence of a weekly recurring day.
     */
    fun calculateDelayForNextDayOccurrence(
        dayOfWeek: Int, // 1 = Monday .. 7 = Sunday
        startTime: String,
        minutesBefore: Int = 15
    ): Long {
        val now = System.currentTimeMillis()
        val targetCal = Calendar.getInstance()
        val (startHour, startMinute) = parseTime(startTime)

        var totalMinutes = (startHour * 60 + startMinute) - minutesBefore
        var dayAdjustment = 0
        if (totalMinutes < 0) {
            totalMinutes += 24 * 60
            dayAdjustment = -1
        }

        val targetHour = totalMinutes / 60
        val targetMin = totalMinutes % 60

        val calendarDayOfWeek = when (dayOfWeek) {
            1 -> Calendar.MONDAY
            2 -> Calendar.TUESDAY
            3 -> Calendar.WEDNESDAY
            4 -> Calendar.THURSDAY
            5 -> Calendar.FRIDAY
            6 -> Calendar.SATURDAY
            7 -> Calendar.SUNDAY
            else -> Calendar.MONDAY
        }

        targetCal.set(Calendar.HOUR_OF_DAY, targetHour)
        targetCal.set(Calendar.MINUTE, targetMin)
        targetCal.set(Calendar.SECOND, 0)
        targetCal.set(Calendar.MILLISECOND, 0)

        // Set to target day of week
        var currentDay = targetCal.get(Calendar.DAY_OF_WEEK)
        var daysDiff = calendarDayOfWeek - currentDay + dayAdjustment
        if (daysDiff < 0) {
            daysDiff += 7
        }
        targetCal.add(Calendar.DAY_OF_YEAR, daysDiff)

        // If calculated target is already in the past (within a 10s buffer), push to next week
        if (targetCal.timeInMillis <= now + 10_000L) {
            targetCal.add(Calendar.DAY_OF_YEAR, 7)
        }

        return (targetCal.timeInMillis - now).coerceAtLeast(0L)
    }

    /**
     * Calculates delay in milliseconds for a specific single-date event (YYYY-MM-DD).
     */
    fun calculateDelayForSpecificDate(
        dateIso: String,
        startTime: String,
        minutesBefore: Int = 15
    ): Long {
        val now = System.currentTimeMillis()
        val sdf = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())
        val parsedDate: Date = try {
            sdf.parse(dateIso.trim()) ?: return -1L
        } catch (_: Exception) {
            return -1L
        }

        val targetCal = Calendar.getInstance().apply {
            time = parsedDate
        }

        val (startHour, startMinute) = parseTime(startTime)
        var totalMinutes = (startHour * 60 + startMinute) - minutesBefore
        if (totalMinutes < 0) {
            totalMinutes += 24 * 60
            targetCal.add(Calendar.DAY_OF_YEAR, -1)
        }

        targetCal.set(Calendar.HOUR_OF_DAY, totalMinutes / 60)
        targetCal.set(Calendar.MINUTE, totalMinutes % 60)
        targetCal.set(Calendar.SECOND, 0)
        targetCal.set(Calendar.MILLISECOND, 0)

        val delay = targetCal.timeInMillis - now
        return if (delay < 0) -1L else delay
    }

    private fun parseTime(timeStr: String): Pair<Int, Int> {
        return try {
            val parts = timeStr.trim().split(":")
            val h = parts[0].toInt()
            val m = if (parts.size > 1) parts[1].toInt() else 0
            Pair(h, m)
        } catch (_: Exception) {
            Pair(8, 30) // Default 08:30
        }
    }
}
