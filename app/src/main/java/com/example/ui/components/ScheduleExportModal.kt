package com.example.ui.components

import android.widget.Toast
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.data.export.IcsCalendarExporter
import com.example.data.export.ScheduleExportOptions
import com.example.data.local.entity.CourseScheduleEntity
import com.example.data.local.entity.ExamScheduleEntity
import com.example.ui.theme.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ScheduleExportModal(
    schedules: List<CourseScheduleEntity>,
    exams: List<ExamScheduleEntity>,
    selectedDay: Int,
    onDismiss: () -> Unit,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current

    var exportScope by remember { mutableStateOf("ALL") } // "ALL", "TODAY", "CLASSES_AND_EXAMS"
    var includeExams by remember { mutableStateOf(true) }
    var semesterWeeks by remember { mutableStateOf(16) }
    var alarmMinutes by remember { mutableStateOf(15) }
    var includeAlarms by remember { mutableStateOf(true) }

    val daysMap = mapOf(1 to "Monday", 2 to "Tuesday", 3 to "Wednesday", 4 to "Thursday", 5 to "Friday")
    val todayName = daysMap[selectedDay] ?: "Today"

    val filteredSchedules = when (exportScope) {
        "TODAY" -> schedules.filter { it.dayOfWeek == selectedDay }
        else -> schedules
    }

    val exportExams = if (exportScope == "CLASSES_AND_EXAMS" || (exportScope == "ALL" && includeExams)) {
        exams
    } else emptyList()

    val totalEventsCount = filteredSchedules.size + exportExams.size

    val exportOptions = ScheduleExportOptions(
        includeWeeklyClasses = true,
        includeExams = exportExams.isNotEmpty(),
        selectedDayFilter = if (exportScope == "TODAY") selectedDay else null,
        semesterWeeksCount = semesterWeeks,
        includeAlarms = includeAlarms,
        alarmMinutesBefore = alarmMinutes,
        calendarTitle = "Campus Academic Schedule (Semester II)"
    )

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        dragHandle = { BottomSheetDefaults.DragHandle() },
        containerColor = MaterialTheme.colorScheme.surface,
        shape = RoundedCornerShape(topStart = 28.dp, topEnd = 28.dp),
        modifier = modifier
    ) {
        LazyColumn(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 20.dp),
            contentPadding = PaddingValues(bottom = 36.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Header
            item {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column(modifier = Modifier.weight(1f)) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Surface(
                                shape = RoundedCornerShape(10.dp),
                                color = AcademicBlue.copy(alpha = 0.12f),
                                modifier = Modifier.size(38.dp)
                            ) {
                                Box(contentAlignment = Alignment.Center) {
                                    Icon(
                                        imageVector = Icons.Filled.CalendarMonth,
                                        contentDescription = null,
                                        tint = AcademicBlue,
                                        modifier = Modifier.size(22.dp)
                                    )
                                }
                            }
                            Spacer(modifier = Modifier.width(10.dp))
                            Text(
                                text = "Export Schedule (.ics)",
                                style = MaterialTheme.typography.titleLarge,
                                fontWeight = FontWeight.Bold,
                                color = MaterialTheme.colorScheme.onSurface
                            )
                        }
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(
                            text = "Sync timetable directly with Google Calendar, Apple Calendar, Outlook, or Samsung Calendar",
                            style = MaterialTheme.typography.bodySmall,
                            color = Slate600
                        )
                    }
                }
            }

            // Sync Status & Event Counter Card
            item {
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(18.dp),
                    colors = CardDefaults.cardColors(containerColor = Navy900)
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(16.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Column {
                            Text(
                                text = "CALENDAR SYNC SUMMARY",
                                style = MaterialTheme.typography.labelSmall,
                                color = AcademicGoldLight,
                                fontWeight = FontWeight.Bold,
                                letterSpacing = 0.8.sp
                            )
                            Spacer(modifier = Modifier.height(4.dp))
                            Text(
                                text = "$totalEventsCount Calendar Items Prepared",
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.Bold,
                                color = Color.White
                            )
                            Text(
                                text = "${filteredSchedules.size} Weekly Classes • ${exportExams.size} Final Exams",
                                style = MaterialTheme.typography.bodySmall,
                                color = Slate200
                            )
                        }

                        Surface(
                            shape = RoundedCornerShape(12.dp),
                            color = Color.White.copy(alpha = 0.15f)
                        ) {
                            Text(
                                text = "RFC 5545",
                                modifier = Modifier.padding(horizontal = 10.dp, vertical = 6.dp),
                                style = MaterialTheme.typography.labelSmall,
                                fontWeight = FontWeight.Bold,
                                color = Color.White
                            )
                        }
                    }
                }
            }

            // Scope Selector
            item {
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text(
                        text = "EXPORT SCOPE",
                        style = MaterialTheme.typography.labelSmall,
                        fontWeight = FontWeight.Bold,
                        color = Slate600,
                        letterSpacing = 0.8.sp
                    )

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        FilterChip(
                            selected = exportScope == "ALL",
                            onClick = {
                                exportScope = "ALL"
                                includeExams = true
                            },
                            label = { Text("Full Week (${schedules.size})") },
                            modifier = Modifier.weight(1f),
                            shape = RoundedCornerShape(10.dp),
                            colors = FilterChipDefaults.filterChipColors(
                                selectedContainerColor = AcademicBlue,
                                selectedLabelColor = Color.White
                            )
                        )
                        FilterChip(
                            selected = exportScope == "TODAY",
                            onClick = {
                                exportScope = "TODAY"
                                includeExams = false
                            },
                            label = { Text("$todayName Only") },
                            modifier = Modifier.weight(1f),
                            shape = RoundedCornerShape(10.dp),
                            colors = FilterChipDefaults.filterChipColors(
                                selectedContainerColor = AcademicBlue,
                                selectedLabelColor = Color.White
                            )
                        )
                        FilterChip(
                            selected = exportScope == "CLASSES_AND_EXAMS",
                            onClick = {
                                exportScope = "CLASSES_AND_EXAMS"
                                includeExams = true
                            },
                            label = { Text("+ Exams (${exams.size})") },
                            modifier = Modifier.weight(1f),
                            shape = RoundedCornerShape(10.dp),
                            colors = FilterChipDefaults.filterChipColors(
                                selectedContainerColor = AcademicBlue,
                                selectedLabelColor = Color.White
                            )
                        )
                    }
                }
            }

            // Export Preferences: Alarms & Semester Duration
            item {
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(16.dp),
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.4f))
                ) {
                    Column(
                        modifier = Modifier.padding(16.dp),
                        verticalArrangement = Arrangement.spacedBy(14.dp)
                    ) {
                        // Include Notification Alarm Switch
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Column(modifier = Modifier.weight(1f)) {
                                Text(
                                    text = "Class Departure Alarms (VALARM)",
                                    style = MaterialTheme.typography.titleSmall,
                                    fontWeight = FontWeight.Bold
                                )
                                Text(
                                    text = "Pre-configure ${alarmMinutes}m reminder in external calendar",
                                    style = MaterialTheme.typography.bodySmall,
                                    color = Slate600
                                )
                            }
                            Switch(
                                checked = includeAlarms,
                                onCheckedChange = { includeAlarms = it },
                                colors = SwitchDefaults.colors(checkedThumbColor = AcademicBlue)
                            )
                        }

                        if (includeAlarms) {
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.spacedBy(8.dp)
                            ) {
                                listOf(10, 15, 30).forEach { mins ->
                                    FilterChip(
                                        selected = alarmMinutes == mins,
                                        onClick = { alarmMinutes = mins },
                                        label = { Text("${mins} min early") },
                                        shape = RoundedCornerShape(8.dp)
                                    )
                                }
                            }
                        }

                        Divider(color = Slate200)

                        // Semester Weeks Duration
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Column {
                                Text(
                                    text = "Semester Duration",
                                    style = MaterialTheme.typography.titleSmall,
                                    fontWeight = FontWeight.Bold
                                )
                                Text(
                                    text = "Weekly recurring rule span",
                                    style = MaterialTheme.typography.bodySmall,
                                    color = Slate600
                                )
                            }

                            Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                                listOf(12, 16).forEach { weeks ->
                                    FilterChip(
                                        selected = semesterWeeks == weeks,
                                        onClick = { semesterWeeks = weeks },
                                        label = { Text("$weeks Wks") },
                                        shape = RoundedCornerShape(8.dp)
                                    )
                                }
                            }
                        }
                    }
                }
            }

            // Export Action Buttons
            item {
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    // Primary Action: Open / Import into Calendar App
                    Button(
                        onClick = {
                            val icsContent = IcsCalendarExporter.generateIcsContent(
                                schedules = filteredSchedules,
                                exams = exportExams,
                                options = exportOptions
                            )
                            val file = IcsCalendarExporter.writeIcsToFile(context, icsContent)
                            IcsCalendarExporter.openWithCalendarApp(context, file)
                            onDismiss()
                        },
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(52.dp)
                            .testTag("sync_calendar_app_button"),
                        shape = RoundedCornerShape(14.dp),
                        colors = ButtonDefaults.buttonColors(containerColor = AcademicBlue)
                    ) {
                        Icon(Icons.Filled.Sync, contentDescription = null)
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = "Open & Sync with Calendar App",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold
                        )
                    }

                    // Secondary Action: Share .ICS File via Share Sheet
                    FilledTonalButton(
                        onClick = {
                            val icsContent = IcsCalendarExporter.generateIcsContent(
                                schedules = filteredSchedules,
                                exams = exportExams,
                                options = exportOptions
                            )
                            val file = IcsCalendarExporter.writeIcsToFile(context, icsContent)
                            IcsCalendarExporter.shareIcsFile(context, file)
                            onDismiss()
                        },
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(48.dp)
                            .testTag("share_ics_file_button"),
                        shape = RoundedCornerShape(14.dp),
                        colors = ButtonDefaults.filledTonalButtonColors(
                            containerColor = AcademicBlue.copy(alpha = 0.12f),
                            contentColor = AcademicBlue
                        )
                    ) {
                        Icon(Icons.Filled.Share, contentDescription = null, modifier = Modifier.size(18.dp))
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = "Share .ICS File (Email, WhatsApp, Drive)",
                            fontWeight = FontWeight.Bold
                        )
                    }

                    // Tertiary Action: Copy iCalendar text to Clipboard
                    OutlinedButton(
                        onClick = {
                            val icsContent = IcsCalendarExporter.generateIcsContent(
                                schedules = filteredSchedules,
                                exams = exportExams,
                                options = exportOptions
                            )
                            IcsCalendarExporter.copyIcsToClipboard(context, icsContent)
                            onDismiss()
                        },
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(46.dp)
                            .testTag("copy_ics_clipboard_button"),
                        shape = RoundedCornerShape(14.dp)
                    ) {
                        Icon(Icons.Filled.ContentCopy, contentDescription = null, modifier = Modifier.size(18.dp))
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("Copy iCalendar Raw Text")
                    }
                }
            }
        }
    }
}
