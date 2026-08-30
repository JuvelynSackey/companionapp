package com.example.data.repository

import com.example.data.local.entity.ExamScheduleEntity
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale

data class ExamCountdownInfo(
    val exam: ExamScheduleEntity,
    val daysRemaining: Long,
    val isToday: Boolean,
    val isTomorrow: Boolean,
    val isPast: Boolean,
    val formattedDaysRemaining: String,
    val formattedExamDate: String
)

object ExamCountdownUtils {

    private val isoDateFormat = SimpleDateFormat("yyyy-MM-dd", Locale.US).apply {
        isLenient = false
    }

    private val displayDateFormat = SimpleDateFormat("EEE, MMM d, yyyy", Locale.US)

    /**
     * Calculates the number of days remaining until an exam date (ISO 8601 YYYY-MM-DD).
     * Compares midnight of current date to midnight of the exam date.
     * Returns 0 for today, 1 for tomorrow, positive integer for future, negative for past.
     */
    fun calculateDaysRemaining(examDateIso: String, nowCalendar: Calendar = Calendar.getInstance()): Long {
        return try {
            val examDate = isoDateFormat.parse(examDateIso.trim()) ?: return 0L
            val todayCal = (nowCalendar.clone() as Calendar).apply {
                set(Calendar.HOUR_OF_DAY, 0)
                set(Calendar.MINUTE, 0)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }
            val examCal = Calendar.getInstance().apply {
                time = examDate
                set(Calendar.HOUR_OF_DAY, 0)
                set(Calendar.MINUTE, 0)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }
            val diffMillis = examCal.timeInMillis - todayCal.timeInMillis
            diffMillis / (1000 * 60 * 60 * 24)
        } catch (e: Exception) {
            0L
        }
    }

    fun formatExamDateDisplay(examDateIso: String): String {
        return try {
            val date = isoDateFormat.parse(examDateIso.trim()) ?: return examDateIso
            displayDateFormat.format(date)
        } catch (e: Exception) {
            examDateIso
        }
    }

    fun getCountdownInfo(exam: ExamScheduleEntity, nowCalendar: Calendar = Calendar.getInstance()): ExamCountdownInfo {
        val days = calculateDaysRemaining(exam.examDate, nowCalendar)
        val isToday = days == 0L
        val isTomorrow = days == 1L
        val isPast = days < 0L

        val formattedDaysRemaining = when {
            isToday -> "Today!"
            isTomorrow -> "Tomorrow (1 day)"
            isPast -> "${-days}d ago"
            else -> "$days days remaining"
        }

        val formattedDate = formatExamDateDisplay(exam.examDate)

        return ExamCountdownInfo(
            exam = exam,
            daysRemaining = days,
            isToday = isToday,
            isTomorrow = isTomorrow,
            isPast = isPast,
            formattedDaysRemaining = formattedDaysRemaining,
            formattedExamDate = formattedDate
        )
    }

    /**
     * Finds the next upcoming scheduled exam from a list of exams in the database.
     * Orders all exams by date ascending, selects the next upcoming exam.
     */
    fun findNextUpcomingExam(exams: List<ExamScheduleEntity>, nowCalendar: Calendar = Calendar.getInstance()): ExamCountdownInfo? {
        if (exams.isEmpty()) return null

        val sorted = exams.sortedWith(compareBy({ it.examDate }, { it.startTime }))
        val upcomingExams = sorted.map { getCountdownInfo(it, nowCalendar) }

        // Prefer upcoming (today or future), otherwise return the closest one
        return upcomingExams.firstOrNull { !it.isPast } ?: upcomingExams.firstOrNull()
    }

    /**
     * Returns all exams sorted chronologically by date and start time with countdown details.
     */
    fun getSortedUpcomingExams(exams: List<ExamScheduleEntity>, nowCalendar: Calendar = Calendar.getInstance()): List<ExamCountdownInfo> {
        return exams
            .sortedWith(compareBy({ it.examDate }, { it.startTime }))
            .map { getCountdownInfo(it, nowCalendar) }
    }
}
