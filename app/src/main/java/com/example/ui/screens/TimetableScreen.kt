package com.example.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.data.local.entity.CourseScheduleEntity
import com.example.ui.MainViewModel
import com.example.ui.NavigationTab
import com.example.ui.UserRole
import com.example.ui.components.ScheduleExportModal
import com.example.ui.components.SmartAlarmComponent
import com.example.ui.theme.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TimetableScreen(
    viewModel: MainViewModel,
    modifier: Modifier = Modifier
) {
    val schedules by viewModel.allSchedules.collectAsState()
    val exams by viewModel.allExams.collectAsState()
    val selectedDay by viewModel.selectedDay.collectAsState()
    val currentRole by viewModel.currentRole.collectAsState()
    val locations by viewModel.allLocations.collectAsState()

    var showAddDialog by remember { mutableStateOf(false) }
    var showExportModal by remember { mutableStateOf(false) }
    var editingScheduleForVenue by remember { mutableStateOf<CourseScheduleEntity?>(null) }

    val days = listOf(
        1 to "Mon",
        2 to "Tue",
        3 to "Wed",
        4 to "Thu",
        5 to "Fri"
    )

    val currentDaySchedules = schedules.filter { it.dayOfWeek == selectedDay }

    Scaffold(
        modifier = modifier.fillMaxSize(),
        floatingActionButton = {
            if (currentRole == UserRole.ADMINISTRATOR || currentRole == UserRole.CLASS_REPRESENTATIVE) {
                FloatingActionButton(
                    onClick = { showAddDialog = true },
                    containerColor = AcademicBlue,
                    contentColor = Color.White,
                    modifier = Modifier.testTag("add_schedule_fab")
                ) {
                    Icon(Icons.Filled.Add, contentDescription = "Add Class")
                }
            }
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(horizontal = 16.dp)
        ) {
            Spacer(modifier = Modifier.height(8.dp))

            // Screen Header
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = "Academic Timetable",
                        style = MaterialTheme.typography.headlineSmall,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                    Text(
                        text = "Semester II • 2025/2026 Academic Year",
                        style = MaterialTheme.typography.bodySmall,
                        color = Slate600
                    )
                }

                Row(verticalAlignment = Alignment.CenterVertically) {
                    FilledTonalButton(
                        onClick = { showExportModal = true },
                        shape = RoundedCornerShape(12.dp),
                        colors = ButtonDefaults.filledTonalButtonColors(
                            containerColor = AcademicBlue.copy(alpha = 0.12f),
                            contentColor = AcademicBlue
                        ),
                        contentPadding = PaddingValues(horizontal = 12.dp, vertical = 6.dp),
                        modifier = Modifier.testTag("export_schedule_button")
                    ) {
                        Icon(
                            imageVector = Icons.Filled.CalendarMonth,
                            contentDescription = null,
                            modifier = Modifier.size(16.dp)
                        )
                        Spacer(modifier = Modifier.width(6.dp))
                        Text("Export (.ics)", fontWeight = FontWeight.Bold, style = MaterialTheme.typography.labelMedium)
                    }

                    if (currentRole == UserRole.CLASS_REPRESENTATIVE) {
                        Spacer(modifier = Modifier.width(8.dp))
                        Surface(
                            shape = RoundedCornerShape(8.dp),
                            color = AcademicGold.copy(alpha = 0.15f)
                        ) {
                            Text(
                                text = "Rep Edit Mode",
                                modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                                style = MaterialTheme.typography.labelSmall,
                                color = AcademicGold,
                                fontWeight = FontWeight.Bold
                            )
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(14.dp))

            // Day Selector Tabs
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                days.forEach { (dayNum, dayName) ->
                    val isSelected = dayNum == selectedDay
                    val dayCount = schedules.count { it.dayOfWeek == dayNum }

                    Surface(
                        modifier = Modifier
                            .weight(1f)
                            .clickable { viewModel.setSelectedDay(dayNum) }
                            .testTag("day_tab_$dayName"),
                        shape = RoundedCornerShape(12.dp),
                        color = if (isSelected) AcademicBlue else MaterialTheme.colorScheme.surfaceVariant
                    ) {
                        Column(
                            modifier = Modifier.padding(vertical = 10.dp),
                            horizontalAlignment = Alignment.CenterHorizontally
                        ) {
                            Text(
                                text = dayName,
                                style = MaterialTheme.typography.labelLarge,
                                fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Medium,
                                color = if (isSelected) Color.White else Slate700
                            )
                            Text(
                                text = "$dayCount ${if (dayCount == 1) "class" else "classes"}",
                                style = MaterialTheme.typography.labelSmall.copy(fontSize = 10.sp),
                                color = if (isSelected) Color(0xFFBAE6FD) else Slate600
                            )
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Timetable List
            LazyColumn(
                verticalArrangement = Arrangement.spacedBy(12.dp),
                contentPadding = PaddingValues(bottom = 96.dp),
                modifier = Modifier.fillMaxSize()
            ) {
                // Smart Alarm Card for Selected Day
                item {
                    SmartAlarmComponent(
                        viewModel = viewModel
                    )
                }

                if (currentDaySchedules.isEmpty()) {
                    item {
                        Box(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(vertical = 36.dp),
                            contentAlignment = Alignment.Center
                        ) {
                            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                Icon(
                                    Icons.Filled.EventAvailable,
                                    contentDescription = null,
                                    modifier = Modifier.size(64.dp),
                                    tint = Slate600.copy(alpha = 0.5f)
                                )
                                Spacer(modifier = Modifier.height(12.dp))
                                Text(
                                    text = "No lectures scheduled for this day",
                                    style = MaterialTheme.typography.titleMedium,
                                    color = Slate600
                                )
                                Text(
                                    text = "Use this free window for private revision or group study!",
                                    style = MaterialTheme.typography.bodySmall,
                                    color = Slate600.copy(alpha = 0.8f)
                                )
                            }
                        }
                    }
                } else {
                    items(currentDaySchedules) { item ->
                        TimetableCard(
                            schedule = item,
                            currentRole = currentRole,
                            onAlarmToggle = { viewModel.toggleScheduleAlarm(item) },
                            onNavigate = {
                                val dest = locations.find { loc -> item.venue.contains(loc.shortCode, ignoreCase = true) }
                                if (dest != null) viewModel.planRouteTo(dest)
                                else viewModel.setSelectedTab(NavigationTab.MAP_NAV)
                            },
                            onRepShiftVenue = { editingScheduleForVenue = item },
                            onDelete = { viewModel.deleteSchedule(item) }
                        )
                    }
                }
            }
        }
    }

    // Class Rep Venue Relocation Dialog
    editingScheduleForVenue?.let { sched ->
        var newVenue by remember { mutableStateOf(sched.venue) }
        var reasonNote by remember { mutableStateOf("Moved by Class Rep for today's session.") }

        AlertDialog(
            onDismissRequest = { editingScheduleForVenue = null },
            title = { Text("Relocate Venue: ${sched.courseCode}") },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    Text(
                        text = "Broadcast an instant venue change alert to all registered classmates.",
                        style = MaterialTheme.typography.bodySmall,
                        color = Slate600
                    )
                    OutlinedTextField(
                        value = newVenue,
                        onValueChange = { newVenue = it },
                        label = { Text("New Venue (e.g. Science Lab 3, KAB 2)") },
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth()
                    )
                    OutlinedTextField(
                        value = reasonNote,
                        onValueChange = { reasonNote = it },
                        label = { Text("Relocation Notice / Instructions") },
                        maxLines = 3,
                        modifier = Modifier.fillMaxWidth()
                    )
                }
            },
            confirmButton = {
                Button(
                    onClick = {
                        viewModel.updateCourseVenue(sched.id, newVenue, reasonNote)
                        editingScheduleForVenue = null
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = CampusRed)
                ) {
                    Text("Broadcast Change")
                }
            },
            dismissButton = {
                TextButton(onClick = { editingScheduleForVenue = null }) {
                    Text("Cancel")
                }
            }
        )
    }

    // Add Schedule Dialog (Admin & Rep)
    if (showAddDialog) {
        var code by remember { mutableStateOf("") }
        var title by remember { mutableStateOf("") }
        var lecturer by remember { mutableStateOf("") }
        var start by remember { mutableStateOf("08:30") }
        var end by remember { mutableStateOf("10:30") }
        var venue by remember { mutableStateOf("KAB 1") }
        var credits by remember { mutableStateOf("3") }

        AlertDialog(
            onDismissRequest = { showAddDialog = false },
            title = { Text("Add Course Lecture Schedule") },
            text = {
                Column(
                    modifier = Modifier.fillMaxWidth(),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    OutlinedTextField(
                        value = code,
                        onValueChange = { code = it },
                        label = { Text("Course Code (e.g. CSCD 302)") },
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth()
                    )
                    OutlinedTextField(
                        value = title,
                        onValueChange = { title = it },
                        label = { Text("Course Title") },
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth()
                    )
                    OutlinedTextField(
                        value = lecturer,
                        onValueChange = { lecturer = it },
                        label = { Text("Lecturer Name") },
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth()
                    )
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        OutlinedTextField(
                            value = start,
                            onValueChange = { start = it },
                            label = { Text("Start (HH:mm)") },
                            modifier = Modifier.weight(1f)
                        )
                        OutlinedTextField(
                            value = end,
                            onValueChange = { end = it },
                            label = { Text("End (HH:mm)") },
                            modifier = Modifier.weight(1f)
                        )
                    }
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        OutlinedTextField(
                            value = venue,
                            onValueChange = { venue = it },
                            label = { Text("Venue") },
                            modifier = Modifier.weight(2f)
                        )
                        OutlinedTextField(
                            value = credits,
                            onValueChange = { credits = it },
                            label = { Text("Credits") },
                            modifier = Modifier.weight(1f)
                        )
                    }
                }
            },
            confirmButton = {
                Button(
                    onClick = {
                        if (code.isNotBlank() && title.isNotBlank()) {
                            viewModel.addCourseSchedule(
                                code = code,
                                title = title,
                                lecturer = lecturer,
                                day = selectedDay,
                                start = start,
                                end = end,
                                venue = venue,
                                credits = credits.toIntOrNull() ?: 3
                            )
                            showAddDialog = false
                        }
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = AcademicBlue)
                ) {
                    Text("Save Schedule")
                }
            },
            dismissButton = {
                TextButton(onClick = { showAddDialog = false }) {
                    Text("Cancel")
                }
            }
        )
    }

    // Export Schedule to .ics Modal
    if (showExportModal) {
        ScheduleExportModal(
            schedules = schedules,
            exams = exams,
            selectedDay = selectedDay,
            onDismiss = { showExportModal = false }
        )
    }
}

@Composable
fun TimetableCard(
    schedule: CourseScheduleEntity,
    currentRole: UserRole,
    onAlarmToggle: () -> Unit,
    onNavigate: () -> Unit,
    onRepShiftVenue: () -> Unit,
    onDelete: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .testTag("timetable_card_${schedule.courseCode}"),
        shape = RoundedCornerShape(18.dp),
        colors = CardDefaults.cardColors(
            containerColor = if (schedule.isCancelledOrMoved) CampusRedContainer.copy(alpha = 0.45f) else MaterialTheme.colorScheme.surface
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            // Header Row
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Surface(
                        shape = RoundedCornerShape(8.dp),
                        color = Color(schedule.colorHex).copy(alpha = 0.15f)
                    ) {
                        Text(
                            text = schedule.courseCode,
                            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.ExtraBold,
                            color = Color(schedule.colorHex)
                        )
                    }
                    Spacer(modifier = Modifier.width(8.dp))
                    Surface(
                        shape = RoundedCornerShape(6.dp),
                        color = Slate200
                    ) {
                        Text(
                            text = "${schedule.creditHours} Credits",
                            modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp),
                            style = MaterialTheme.typography.labelSmall,
                            color = Slate700
                        )
                    }
                }

                Row {
                    IconButton(onClick = onAlarmToggle) {
                        Icon(
                            imageVector = if (schedule.isAlarmEnabled) Icons.Filled.NotificationsActive else Icons.Outlined.NotificationsOff,
                            contentDescription = "Alarm",
                            tint = if (schedule.isAlarmEnabled) AcademicGold else Slate600
                        )
                    }
                    if (currentRole == UserRole.ADMINISTRATOR) {
                        IconButton(onClick = onDelete) {
                            Icon(Icons.Filled.Delete, contentDescription = "Delete", tint = Slate600)
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(8.dp))

            Text(
                text = schedule.courseTitle,
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onSurface
            )

            Spacer(modifier = Modifier.height(6.dp))

            // Details
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(Icons.Filled.Schedule, contentDescription = null, tint = AcademicBlue, modifier = Modifier.size(16.dp))
                Spacer(modifier = Modifier.width(4.dp))
                Text(
                    text = "${schedule.startTime} - ${schedule.endTime} (2 hours)",
                    style = MaterialTheme.typography.bodySmall,
                    color = Slate700,
                    fontWeight = FontWeight.SemiBold
                )
                Spacer(modifier = Modifier.width(12.dp))
                Icon(Icons.Filled.Person, contentDescription = null, tint = Slate600, modifier = Modifier.size(16.dp))
                Spacer(modifier = Modifier.width(4.dp))
                Text(
                    text = schedule.lecturer,
                    style = MaterialTheme.typography.bodySmall,
                    color = Slate700
                )
            }

            Spacer(modifier = Modifier.height(4.dp))

            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(
                    imageVector = Icons.Filled.Place,
                    contentDescription = null,
                    tint = if (schedule.isCancelledOrMoved) CampusRed else CampusGreen,
                    modifier = Modifier.size(16.dp)
                )
                Spacer(modifier = Modifier.width(4.dp))
                Text(
                    text = schedule.venue,
                    style = MaterialTheme.typography.bodySmall,
                    fontWeight = FontWeight.Bold,
                    color = if (schedule.isCancelledOrMoved) CampusRed else MaterialTheme.colorScheme.onSurface
                )
            }

            if (schedule.isCancelledOrMoved && !schedule.changeNote.isNullOrBlank()) {
                Spacer(modifier = Modifier.height(8.dp))
                Surface(
                    shape = RoundedCornerShape(8.dp),
                    color = CampusRed.copy(alpha = 0.12f),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text(
                        text = "📢 Notice: ${schedule.changeNote}",
                        style = MaterialTheme.typography.bodySmall,
                        color = CampusRed,
                        modifier = Modifier.padding(8.dp),
                        fontWeight = FontWeight.Medium
                    )
                }
            }

            Spacer(modifier = Modifier.height(12.dp))

            // Action Buttons
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                OutlinedButton(
                    onClick = onNavigate,
                    modifier = Modifier.weight(1f),
                    shape = RoundedCornerShape(10.dp)
                ) {
                    Icon(Icons.Filled.Navigation, contentDescription = null, modifier = Modifier.size(16.dp))
                    Spacer(modifier = Modifier.width(6.dp))
                    Text("Navigate", style = MaterialTheme.typography.labelMedium)
                }

                if (currentRole == UserRole.CLASS_REPRESENTATIVE || currentRole == UserRole.ADMINISTRATOR) {
                    Button(
                        onClick = onRepShiftVenue,
                        modifier = Modifier.weight(1f),
                        colors = ButtonDefaults.buttonColors(containerColor = AcademicGold),
                        shape = RoundedCornerShape(10.dp)
                    ) {
                        Icon(Icons.Filled.EditLocationAlt, contentDescription = null, modifier = Modifier.size(16.dp))
                        Spacer(modifier = Modifier.width(6.dp))
                        Text("Shift Venue", style = MaterialTheme.typography.labelMedium)
                    }
                }
            }
        }
    }
}
