package com.example.data.export

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.Toast
import androidx.core.content.FileProvider
import com.example.data.local.entity.CourseScheduleEntity
import com.example.data.local.entity.ExamScheduleEntity
import java.io.File
import java.io.FileWriter
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import java.util.TimeZone

data class ScheduleExportOptions(
    val includeWeeklyClasses: Boolean = true,
    val includeExams: Boolean = true,
    val selectedDayFilter: Int? = null, // null for all weekdays 1-5, or specific day 1..5
    val semesterWeeksCount: Int = 16,
    val includeAlarms: Boolean = true,
    val alarmMinutesBefore: Int = 15,
    val calendarTitle: String = "Campus Academic Schedule"
)

object IcsCalendarExporter {

    private val icsDateFormat = SimpleDateFormat("yyyyMMdd'T'HHmmss'Z'", Locale.US).apply {
        timeZone = TimeZone.getTimeZone("UTC")
    }

    private val localIcsFormat = SimpleDateFormat("yyyyMMdd'T'HHmmss", Locale.US)

    /**
     * Generates a standard RFC 5545 compliant iCalendar string (.ics).
     */
    fun generateIcsContent(
        schedules: List<CourseScheduleEntity>,
        exams: List<ExamScheduleEntity> = emptyList(),
        options: ScheduleExportOptions = ScheduleExportOptions()
    ): String {
        val sb = StringBuilder()
        val nowFormatted = icsDateFormat.format(Date())

        sb.appendLine("BEGIN:VCALENDAR")
        sb.appendLine("VERSION:2.0")
        sb.appendLine("PRODID:-//Campus Companion//Academic Schedule Exporter//EN")
        sb.appendLine("CALSCALE:GREGORIAN")
        sb.appendLine("METHOD:PUBLISH")
        sb.appendLine("X-WR-CALNAME:${escapeIcsText(options.calendarTitle)}")
        sb.appendLine("X-WR-TIMEZONE:UTC")

        // 1. Export Weekly Class Timetable
        if (options.includeWeeklyClasses) {
            val filteredSchedules = if (options.selectedDayFilter != null) {
                schedules.filter { it.dayOfWeek == options.selectedDayFilter }
            } else {
                schedules
            }

            // Reference base semester start date: Current semester base (Monday of active semester)
            val semesterStartCal = Calendar.getInstance().apply {
                firstDayOfWeek = Calendar.MONDAY
                // If past mid-year, start from Aug/Sept or Feb
                set(Calendar.DAY_OF_WEEK, Calendar.MONDAY)
                set(Calendar.HOUR_OF_DAY, 0)
                set(Calendar.MINUTE, 0)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }

            val untilCal = (semesterStartCal.clone() as Calendar).apply {
                add(Calendar.WEEK_OF_YEAR, options.semesterWeeksCount)
            }
            val untilFormatted = icsDateFormat.format(untilCal.time)

            filteredSchedules.forEach { schedule ->
                appendScheduleEvent(
                    sb = sb,
                    schedule = schedule,
                    semesterStartCal = semesterStartCal,
                    untilFormatted = untilFormatted,
                    nowFormatted = nowFormatted,
                    options = options
                )
            }
        }

        // 2. Export Exam Schedules
        if (options.includeExams && exams.isNotEmpty()) {
            exams.forEach { exam ->
                appendExamEvent(
                    sb = sb,
                    exam = exam,
                    nowFormatted = nowFormatted,
                    options = options
                )
            }
        }

        sb.appendLine("END:VCALENDAR")
        return sb.toString()
    }

    private fun appendScheduleEvent(
        sb: StringBuilder,
        schedule: CourseScheduleEntity,
        semesterStartCal: Calendar,
        untilFormatted: String,
        nowFormatted: String,
        options: ScheduleExportOptions
    ) {
        // Map dayOfWeek (1=Mon, 2=Tue, 3=Wed, 4=Thu, 5=Fri)
        val dayOffset = (schedule.dayOfWeek - 1).coerceIn(0, 6)
        val eventDayCal = (semesterStartCal.clone() as Calendar).apply {
            add(Calendar.DAY_OF_YEAR, dayOffset)
        }

        val (startHour, startMin) = parseTime(schedule.startTime)
        val (endHour, endMin) = parseTime(schedule.endTime)

        val eventStart = (eventDayCal.clone() as Calendar).apply {
            set(Calendar.HOUR_OF_DAY, startHour)
            set(Calendar.MINUTE, startMin)
            set(Calendar.SECOND, 0)
        }

        val eventEnd = (eventDayCal.clone() as Calendar).apply {
            set(Calendar.HOUR_OF_DAY, endHour)
            set(Calendar.MINUTE, endMin)
            set(Calendar.SECOND, 0)
        }

        val dayCode = when (schedule.dayOfWeek) {
            1 -> "MO"
            2 -> "TU"
            3 -> "WE"
            4 -> "TH"
            5 -> "FR"
            6 -> "SA"
            else -> "SU"
        }

        val dtStart = localIcsFormat.format(eventStart.time)
        val dtEnd = localIcsFormat.format(eventEnd.time)

        sb.appendLine("BEGIN:VEVENT")
        sb.appendLine("UID:class-${schedule.id}-${schedule.courseCode}@campuscompanion.app")
        sb.appendLine("DTSTAMP:$nowFormatted")
        sb.appendLine("DTSTART:$dtStart")
        sb.appendLine("DTEND:$dtEnd")
        sb.appendLine("RRULE:FREQ=WEEKLY;UNTIL=$untilFormatted;BYDAY=$dayCode")
        sb.appendLine("SUMMARY:${escapeIcsText("${schedule.courseCode}: ${schedule.courseTitle}")}")
        sb.appendLine("LOCATION:${escapeIcsText(schedule.venue)}")

        val desc = buildString {
            append("Lecturer: ${schedule.lecturer}\\n")
            append("Credit Hours: ${schedule.creditHours} Units\\n")
            if (!schedule.changeNote.isNullOrBlank()) {
                append("Notice: ${schedule.changeNote}\\n")
            }
            append("Exported from Campus Companion Academic App")
        }
        sb.appendLine("DESCRIPTION:${escapeIcsText(desc)}")
        sb.appendLine("STATUS:CONFIRMED")

        if (options.includeAlarms) {
            sb.appendLine("BEGIN:VALARM")
            sb.appendLine("ACTION:DISPLAY")
            sb.appendLine("DESCRIPTION:${escapeIcsText("Class starting soon: ${schedule.courseCode} at ${schedule.venue}")}")
            sb.appendLine("TRIGGER:-PT${options.alarmMinutesBefore}M")
            sb.appendLine("END:VALARM")
        }

        sb.appendLine("END:VEVENT")
    }

    private fun appendExamEvent(
        sb: StringBuilder,
        exam: ExamScheduleEntity,
        nowFormatted: String,
        options: ScheduleExportOptions
    ) {
        val (startHour, startMin) = parseTime(exam.startTime)
        val (endHour, endMin) = parseTime(exam.endTime)

        // Parse Exam Date (e.g. "2026-08-25")
        val examDateCal = Calendar.getInstance()
        try {
            val df = SimpleDateFormat("yyyy-MM-dd", Locale.US)
            val parsed = df.parse(exam.examDate)
            if (parsed != null) {
                examDateCal.time = parsed
            }
        } catch (e: Exception) {
            // fallback
        }

        val eventStart = (examDateCal.clone() as Calendar).apply {
            set(Calendar.HOUR_OF_DAY, startHour)
            set(Calendar.MINUTE, startMin)
            set(Calendar.SECOND, 0)
        }

        val eventEnd = (examDateCal.clone() as Calendar).apply {
            set(Calendar.HOUR_OF_DAY, endHour)
            set(Calendar.MINUTE, endMin)
            set(Calendar.SECOND, 0)
        }

        val dtStart = localIcsFormat.format(eventStart.time)
        val dtEnd = localIcsFormat.format(eventEnd.time)

        sb.appendLine("BEGIN:VEVENT")
        sb.appendLine("UID:exam-${exam.id}-${exam.courseCode}@campuscompanion.app")
        sb.appendLine("DTSTAMP:$nowFormatted")
        sb.appendLine("DTSTART:$dtStart")
        sb.appendLine("DTEND:$dtEnd")
        sb.appendLine("SUMMARY:${escapeIcsText("EXAM: ${exam.courseCode} - ${exam.courseTitle}")}")
        sb.appendLine("LOCATION:${escapeIcsText("${exam.venue} (${exam.seatRange})")}")

        val desc = buildString {
            append("FINAL EXAMINATION\\n")
            append("Course: ${exam.courseCode} (${exam.courseTitle})\\n")
            append("Venue: ${exam.venue}\\n")
            append("Assigned Seating: ${exam.seatRange}\\n")
            append("Invigilator: ${exam.invigilator}\\n")
            append("Walking Time: ${exam.walkingTimeMinutes} Mins\\n")
            if (exam.rules.isNotBlank()) {
                append("Exam Rules: ${exam.rules}\\n")
            }
            append("Note: Bring Student ID & required examination stationery.")
        }
        sb.appendLine("DESCRIPTION:${escapeIcsText(desc)}")
        sb.appendLine("STATUS:CONFIRMED")
        sb.appendLine("PRIORITY:1")

        if (options.includeAlarms) {
            sb.appendLine("BEGIN:VALARM")
            sb.appendLine("ACTION:DISPLAY")
            sb.appendLine("DESCRIPTION:${escapeIcsText("Upcoming Final Exam: ${exam.courseCode} at ${exam.venue}")}")
            sb.appendLine("TRIGGER:-PT60M")
            sb.appendLine("END:VALARM")
        }

        sb.appendLine("END:VEVENT")
    }

    private fun parseTime(timeStr: String): Pair<Int, Int> {
        val parts = timeStr.trim().split(":")
        val h = parts.getOrNull(0)?.toIntOrNull() ?: 8
        val m = parts.getOrNull(1)?.toIntOrNull() ?: 0
        return Pair(h, m)
    }

    private fun escapeIcsText(text: String): String {
        return text
            .replace("\\", "\\\\")
            .replace(";", "\\;")
            .replace(",", "\\,")
            .replace("\n", "\\n")
    }

    /**
     * Saves the .ics content to the app's cache directory and returns the File.
     */
    fun writeIcsToFile(
        context: Context,
        icsContent: String,
        fileName: String = "campus_academic_schedule.ics"
    ): File {
        val exportDir = File(context.cacheDir, "exports").apply { mkdirs() }
        val file = File(exportDir, fileName)
        FileWriter(file).use { writer ->
            writer.write(icsContent)
        }
        return file
    }

    /**
     * Gets a shareable content URI for the file using FileProvider.
     */
    fun getShareableUri(context: Context, file: File): Uri {
        val authority = "${context.packageName}.fileprovider"
        return FileProvider.getUriForFile(context, authority, file)
    }

    /**
     * Triggers the Android system share sheet with the .ics calendar attachment.
     */
    fun shareIcsFile(context: Context, file: File, title: String = "Share Academic Schedule (.ics)") {
        try {
            val uri = getShareableUri(context, file)
            val shareIntent = Intent(Intent.ACTION_SEND).apply {
                type = "text/calendar"
                putExtra(Intent.EXTRA_STREAM, uri)
                putExtra(Intent.EXTRA_SUBJECT, "Academic Class Schedule (iCalendar)")
                putExtra(Intent.EXTRA_TEXT, "Here is my semester academic timetable exported from Campus Companion. Tap to import into Google Calendar, Outlook, or Apple Calendar.")
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            val chooser = Intent.createChooser(shareIntent, title).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(chooser)
        } catch (e: Exception) {
            Toast.makeText(context, "Could not open share sheet: ${e.localizedMessage}", Toast.LENGTH_LONG).show()
        }
    }

    /**
     * Attempts to open the .ics file directly in an installed Calendar or Calendar Import app.
     */
    fun openWithCalendarApp(context: Context, file: File) {
        try {
            val uri = getShareableUri(context, file)
            val openIntent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, "text/calendar")
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(openIntent)
        } catch (e: Exception) {
            // If no direct handler found, fallback to share sheet
            shareIcsFile(context, file, "Open with Calendar App")
        }
    }

    /**
     * Copies the raw .ics RFC-5545 text to the system clipboard.
     */
    fun copyIcsToClipboard(context: Context, icsContent: String) {
        val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        val clip = ClipData.newPlainText("Campus Academic Schedule (iCal)", icsContent)
        clipboard.setPrimaryClip(clip)
        Toast.makeText(context, "iCalendar (.ics) data copied to clipboard!", Toast.LENGTH_SHORT).show()
    }
}
