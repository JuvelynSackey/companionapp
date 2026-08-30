package com.example.ui.screens

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Assignment
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.data.local.entity.ExamScheduleEntity
import com.example.data.repository.ExamCountdownInfo
import com.example.data.repository.ExamCountdownUtils
import com.example.ui.MainViewModel
import com.example.ui.NavigationTab
import com.example.ui.UserRole
import com.example.ui.components.ScheduleExportModal
import com.example.ui.theme.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ExamsScreen(
    viewModel: MainViewModel,
    modifier: Modifier = Modifier
) {
    val exams by viewModel.allExams.collectAsState()
    val schedules by viewModel.allSchedules.collectAsState()
    val locations by viewModel.allLocations.collectAsState()
    val currentRole by viewModel.currentRole.collectAsState()
    val nextExamInfo by viewModel.nextExamCountdown.collectAsState()

    var showAddDialog by remember { mutableStateOf(false) }
    var showExportModal by remember { mutableStateOf(false) }
    var selectedExamRules by remember { mutableStateOf<ExamScheduleEntity?>(null) }
    var examToDelete by remember { mutableStateOf<ExamScheduleEntity?>(null) }
    var searchQuery by remember { mutableStateOf("") }

    // Sorted chronologically by exam date and start time
    val sortedExams = remember(exams) {
        exams.sortedWith(compareBy({ it.examDate }, { it.startTime }))
    }

    val filteredExams = remember(sortedExams, searchQuery) {
        if (searchQuery.isBlank()) {
            sortedExams
        } else {
            val q = searchQuery.trim().lowercase()
            sortedExams.filter {
                it.courseCode.lowercase().contains(q) ||
                it.courseTitle.lowercase().contains(q) ||
                it.venue.lowercase().contains(q)
            }
        }
    }

    Scaffold(
        modifier = modifier.fillMaxSize(),
        floatingActionButton = {
            FloatingActionButton(
                onClick = { showAddDialog = true },
                containerColor = AcademicBlue,
                contentColor = Color.White,
                modifier = Modifier.testTag("add_exam_fab")
            ) {
                Icon(Icons.Filled.Add, contentDescription = "Add Exam Paper")
            }
        }
    ) { padding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(horizontal = 16.dp)
                .testTag("exams_scrollable_list"),
            contentPadding = PaddingValues(top = 8.dp, bottom = 96.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Header Card with Dynamic Countdown to next scheduled exam
            item {
                Card(
                    modifier = Modifier
                        .fillMaxWidth()
                        .testTag("exams_countdown_header_card"),
                    shape = RoundedCornerShape(20.dp),
                    colors = CardDefaults.cardColors(containerColor = Navy900)
                ) {
                    Column(modifier = Modifier.padding(20.dp)) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                text = "EXAMINATION TIMETABLE",
                                style = MaterialTheme.typography.labelMedium,
                                color = AcademicGoldLight,
                                fontWeight = FontWeight.Bold,
                                letterSpacing = 1.sp
                            )
                            Surface(
                                shape = RoundedCornerShape(8.dp),
                                color = CampusRed
                            ) {
                                Text(
                                    text = "OFFICIAL",
                                    modifier = Modifier.padding(horizontal = 8.dp, vertical = 2.dp),
                                    style = MaterialTheme.typography.labelSmall,
                                    color = Color.White,
                                    fontWeight = FontWeight.Bold
                                )
                            }
                        }

                        Spacer(modifier = Modifier.height(12.dp))

                        Text(
                            text = if (nextExamInfo != null) "Next: ${nextExamInfo!!.exam.courseCode} Final" else "Semester Finals Countdown",
                            style = MaterialTheme.typography.headlineSmall,
                            fontWeight = FontWeight.Bold,
                            color = Color.White
                        )
                        Text(
                            text = if (nextExamInfo != null) "${nextExamInfo!!.exam.courseTitle} • ${nextExamInfo!!.exam.venue}" else "Scheduled across university exam centers",
                            style = MaterialTheme.typography.bodySmall,
                            color = Slate200
                        )

                        Spacer(modifier = Modifier.height(16.dp))

                        // Dynamic Countdown boxes
                        val daysStr = if (nextExamInfo != null) {
                            val days = nextExamInfo!!.daysRemaining
                            if (days >= 0) String.format("%02d", days) else "00"
                        } else "00"

                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            CountdownUnitCard(number = daysStr, label = "DAYS", modifier = Modifier.weight(1f))
                            CountdownUnitCard(number = "14", label = "HOURS", modifier = Modifier.weight(1f))
                            CountdownUnitCard(number = "00", label = "MINS", modifier = Modifier.weight(1f))
                            CountdownUnitCard(number = "${exams.size}", label = "PAPERS", modifier = Modifier.weight(1f))
                        }

                        Spacer(modifier = Modifier.height(14.dp))

                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            FilledTonalButton(
                                onClick = { showExportModal = true },
                                modifier = Modifier
                                    .weight(1f)
                                    .testTag("export_exams_calendar_button"),
                                shape = RoundedCornerShape(12.dp),
                                colors = ButtonDefaults.filledTonalButtonColors(
                                    containerColor = Color.White.copy(alpha = 0.15f),
                                    contentColor = Color.White
                                )
                            ) {
                                Icon(Icons.Filled.CalendarMonth, contentDescription = null, modifier = Modifier.size(18.dp))
                                Spacer(modifier = Modifier.width(6.dp))
                                Text(
                                    text = "Export (.ics)",
                                    fontWeight = FontWeight.Bold,
                                    style = MaterialTheme.typography.labelMedium
                                )
                            }

                            Button(
                                onClick = { showAddDialog = true },
                                modifier = Modifier
                                    .weight(1f)
                                    .testTag("add_exam_entry_button"),
                                shape = RoundedCornerShape(12.dp),
                                colors = ButtonDefaults.buttonColors(
                                    containerColor = AcademicGold,
                                    contentColor = Slate900
                                )
                            ) {
                                Icon(Icons.Filled.Add, contentDescription = null, modifier = Modifier.size(18.dp))
                                Spacer(modifier = Modifier.width(6.dp))
                                Text(
                                    text = "Add Paper",
                                    fontWeight = FontWeight.Bold,
                                    style = MaterialTheme.typography.labelMedium
                                )
                            }
                        }
                    }
                }
            }

            // Quick Exam Hall Checklist Banner
            item {
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(16.dp),
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.primaryContainer)
                ) {
                    Row(
                        modifier = Modifier.padding(14.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            imageVector = Icons.Filled.Checklist,
                            contentDescription = null,
                            tint = AcademicBlue,
                            modifier = Modifier.size(28.dp)
                        )
                        Spacer(modifier = Modifier.width(12.dp))
                        Column(modifier = Modifier.weight(1f)) {
                            Text(
                                text = "Exam Hall Verification Checklist",
                                style = MaterialTheme.typography.titleSmall,
                                fontWeight = FontWeight.Bold,
                                color = MaterialTheme.colorScheme.onPrimaryContainer
                            )
                            Text(
                                text = "Valid Student ID • Index Slip • Calculator • 30 min early arrival",
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha = 0.8f)
                            )
                        }
                    }
                }
            }

            // Search Bar & Header
            item {
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Column {
                            Text(
                                text = "Upcoming Exams Sorted by Date",
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.Bold
                            )
                            Text(
                                text = "${filteredExams.size} scheduled entries • Soonest first",
                                style = MaterialTheme.typography.bodySmall,
                                color = Slate600
                            )
                        }

                        Surface(
                            shape = RoundedCornerShape(8.dp),
                            color = AcademicBlue.copy(alpha = 0.1f)
                        ) {
                            Row(
                                modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Icon(Icons.Filled.Sort, contentDescription = null, tint = AcademicBlue, modifier = Modifier.size(14.dp))
                                Spacer(modifier = Modifier.width(4.dp))
                                Text(
                                    text = "Date Order",
                                    style = MaterialTheme.typography.labelSmall,
                                    fontWeight = FontWeight.Bold,
                                    color = AcademicBlue
                                )
                            }
                        }
                    }

                    // Swipe Hint Chip
                    Surface(
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(10.dp),
                        color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.6f)
                    ) {
                        Row(
                            modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(
                                imageVector = Icons.Filled.Swipe,
                                contentDescription = null,
                                tint = AcademicBlue,
                                modifier = Modifier.size(16.dp)
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(
                                text = "Tip: Swipe any exam card left or right to delete",
                                style = MaterialTheme.typography.labelSmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }

                    OutlinedTextField(
                        value = searchQuery,
                        onValueChange = { searchQuery = it },
                        modifier = Modifier
                            .fillMaxWidth()
                            .testTag("search_exams_field"),
                        placeholder = { Text("Search by code, title, or hall...") },
                        leadingIcon = {
                            Icon(Icons.Filled.Search, contentDescription = "Search", tint = Slate500)
                        },
                        trailingIcon = {
                            if (searchQuery.isNotBlank()) {
                                IconButton(onClick = { searchQuery = "" }) {
                                    Icon(Icons.Filled.Clear, contentDescription = "Clear search")
                                }
                            }
                        },
                        shape = RoundedCornerShape(14.dp),
                        singleLine = true,
                        colors = OutlinedTextFieldDefaults.colors(
                            unfocusedContainerColor = MaterialTheme.colorScheme.surface,
                            focusedContainerColor = MaterialTheme.colorScheme.surface
                        )
                    )
                }
            }

            // Scrollable List of Exam Cards Sorted by Date with Swipe-to-Delete
            if (filteredExams.isEmpty()) {
                item {
                    Card(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 24.dp)
                            .testTag("empty_exams_state"),
                        shape = RoundedCornerShape(16.dp),
                        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f))
                    ) {
                        Column(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(24.dp),
                            horizontalAlignment = Alignment.CenterHorizontally
                        ) {
                            Icon(
                                imageVector = Icons.Outlined.EventBusy,
                                contentDescription = null,
                                modifier = Modifier.size(48.dp),
                                tint = Slate500
                            )
                            Spacer(modifier = Modifier.height(12.dp))
                            Text(
                                text = if (searchQuery.isNotBlank()) "No exams match '$searchQuery'" else "No exams in timetable",
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.Bold
                            )
                            Spacer(modifier = Modifier.height(4.dp))
                            Text(
                                text = if (searchQuery.isNotBlank()) "Try changing your search terms." else "Tap below to add your first upcoming exam schedule.",
                                style = MaterialTheme.typography.bodySmall,
                                color = Slate600
                            )
                            Spacer(modifier = Modifier.height(16.dp))
                            Button(
                                onClick = { showAddDialog = true },
                                shape = RoundedCornerShape(10.dp)
                            ) {
                                Icon(Icons.Filled.Add, contentDescription = null, modifier = Modifier.size(16.dp))
                                Spacer(modifier = Modifier.width(6.dp))
                                Text("Add Exam Paper")
                            }
                        }
                    }
                }
            } else {
                items(filteredExams, key = { it.id }) { exam ->
                    val countdownInfo = ExamCountdownUtils.getCountdownInfo(exam)
                    SwipeableExamItem(
                        exam = exam,
                        countdownInfo = countdownInfo,
                        onAlarmToggle = { viewModel.toggleExamAlarm(exam) },
                        onNavigate = {
                            val dest = locations.find { loc -> exam.venue.contains(loc.shortCode, ignoreCase = true) }
                            if (dest != null) viewModel.planRouteTo(dest)
                            else viewModel.setSelectedTab(NavigationTab.MAP_NAV)
                        },
                        onViewRules = { selectedExamRules = exam },
                        onTriggerTestAlarm = {
                            viewModel.triggerSimulatedAlarm(
                                title = "${exam.courseCode} Examination",
                                venue = exam.venue,
                                leaveTime = exam.suggestedLeaveTime
                            )
                        },
                        onDeleteRequest = {
                            examToDelete = exam
                        }
                    )
                }
            }
        }
    }

    // Delete Confirmation Dialog
    examToDelete?.let { exam ->
        AlertDialog(
            onDismissRequest = { examToDelete = null },
            icon = {
                Icon(
                    imageVector = Icons.Filled.Delete,
                    contentDescription = null,
                    tint = CampusRed,
                    modifier = Modifier.size(28.dp)
                )
            },
            title = {
                Text(
                    text = "Delete Exam Entry",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )
            },
            text = {
                Text(
                    text = "Are you sure you want to remove '${exam.courseCode} - ${exam.courseTitle}' from your upcoming examination timetable?",
                    style = MaterialTheme.typography.bodyMedium
                )
            },
            confirmButton = {
                Button(
                    onClick = {
                        viewModel.deleteExam(exam)
                        examToDelete = null
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = CampusRed),
                    modifier = Modifier.testTag("confirm_delete_exam_button")
                ) {
                    Text("Delete", fontWeight = FontWeight.Bold)
                }
            },
            dismissButton = {
                TextButton(
                    onClick = { examToDelete = null }
                ) {
                    Text("Cancel")
                }
            }
        )
    }

    // Exam Rules Bottom Sheet / Dialog
    selectedExamRules?.let { exam ->
        AlertDialog(
            onDismissRequest = { selectedExamRules = null },
            title = {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Filled.Gavel, contentDescription = null, tint = AcademicBlue)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("${exam.courseCode} Hall Instructions")
                }
            },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    Text(
                        text = "Paper: ${exam.courseTitle}",
                        style = MaterialTheme.typography.titleSmall,
                        fontWeight = FontWeight.Bold
                    )
                    Text(
                        text = "• Venue: ${exam.venue}\n" +
                                "• Seating Range: ${exam.seatRange}\n" +
                                "• Chief Invigilator: ${exam.invigilator}\n\n" +
                                "⚠️ Regulations:\n${exam.rules}",
                        style = MaterialTheme.typography.bodyMedium
                    )
                }
            },
            confirmButton = {
                Button(onClick = { selectedExamRules = null }) {
                    Text("Understood")
                }
            }
        )
    }

    // Add Exam Dialog
    if (showAddDialog) {
        var code by remember { mutableStateOf("") }
        var title by remember { mutableStateOf("") }
        var date by remember { mutableStateOf("2026-09-08") }
        var start by remember { mutableStateOf("09:00") }
        var end by remember { mutableStateOf("12:00") }
        var venue by remember { mutableStateOf("KAB 1") }
        var seatRange by remember { mutableStateOf("Index 10920001 - 10920200") }
        var walkingMins by remember { mutableStateOf("15") }
        var rules by remember { mutableStateOf("Standard university exam regulations apply.") }

        AlertDialog(
            onDismissRequest = { showAddDialog = false },
            title = { Text("Add Examination Paper") },
            text = {
                Column(
                    modifier = Modifier.fillMaxWidth(),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    OutlinedTextField(
                        value = code,
                        onValueChange = { code = it },
                        label = { Text("Course Code (e.g. CSCD 302)") },
                        modifier = Modifier.fillMaxWidth()
                    )
                    OutlinedTextField(
                        value = title,
                        onValueChange = { title = it },
                        label = { Text("Course Title") },
                        modifier = Modifier.fillMaxWidth()
                    )
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        OutlinedTextField(
                            value = date,
                            onValueChange = { date = it },
                            label = { Text("Date (YYYY-MM-DD)") },
                            modifier = Modifier.weight(1f)
                        )
                        OutlinedTextField(
                            value = start,
                            onValueChange = { start = it },
                            label = { Text("Start Time") },
                            modifier = Modifier.weight(1f)
                        )
                    }
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        OutlinedTextField(
                            value = venue,
                            onValueChange = { venue = it },
                            label = { Text("Venue") },
                            modifier = Modifier.weight(1.5f)
                        )
                        OutlinedTextField(
                            value = walkingMins,
                            onValueChange = { walkingMins = it },
                            label = { Text("Walk (min)") },
                            modifier = Modifier.weight(1f)
                        )
                    }
                    OutlinedTextField(
                        value = seatRange,
                        onValueChange = { seatRange = it },
                        label = { Text("Seating Index Range") },
                        modifier = Modifier.fillMaxWidth()
                    )
                }
            },
            confirmButton = {
                Button(
                    onClick = {
                        if (code.isNotBlank() && title.isNotBlank()) {
                            viewModel.addExamSchedule(
                                code = code,
                                title = title,
                                date = date,
                                start = start,
                                end = end,
                                venue = venue,
                                seatRange = seatRange,
                                walkingMinutes = walkingMins.toIntOrNull() ?: 15,
                                rules = rules
                            )
                            showAddDialog = false
                        }
                    }
                ) {
                    Text("Save Exam")
                }
            },
            dismissButton = {
                TextButton(onClick = { showAddDialog = false }) {
                    Text("Cancel")
                }
            }
        )
    }

    if (showExportModal) {
        ScheduleExportModal(
            schedules = schedules,
            exams = exams,
            selectedDay = 1,
            onDismiss = { showExportModal = false }
        )
    }
}

@Composable
fun CountdownUnitCard(
    number: String,
    label: String,
    modifier: Modifier = Modifier
) {
    Surface(
        modifier = modifier,
        shape = RoundedCornerShape(12.dp),
        color = Color.White.copy(alpha = 0.12f)
    ) {
        Column(
            modifier = Modifier.padding(vertical = 8.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = number,
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Black,
                color = Color.White
            )
            Text(
                text = label,
                style = MaterialTheme.typography.labelSmall.copy(fontSize = 9.sp),
                color = AcademicGoldLight,
                fontWeight = FontWeight.Bold
            )
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SwipeableExamItem(
    exam: ExamScheduleEntity,
    countdownInfo: ExamCountdownInfo,
    onAlarmToggle: () -> Unit,
    onNavigate: () -> Unit,
    onViewRules: () -> Unit,
    onTriggerTestAlarm: () -> Unit,
    onDeleteRequest: () -> Unit
) {
    val dismissState = rememberSwipeToDismissBoxState(
        confirmValueChange = { dismissValue ->
            if (dismissValue == SwipeToDismissBoxValue.EndToStart || dismissValue == SwipeToDismissBoxValue.StartToEnd) {
                onDeleteRequest()
                false // Keep card in view until confirmed via state removal
            } else {
                false
            }
        }
    )

    SwipeToDismissBox(
        state = dismissState,
        enableDismissFromStartToEnd = true,
        enableDismissFromEndToStart = true,
        modifier = Modifier
            .fillMaxWidth()
            .testTag("swipeable_exam_${exam.courseCode}"),
        backgroundContent = {
            val direction = dismissState.dismissDirection
            val alignment = if (direction == SwipeToDismissBoxValue.StartToEnd) Alignment.CenterStart else Alignment.CenterEnd
            val scale by animateFloatAsState(
                if (dismissState.targetValue == SwipeToDismissBoxValue.Settled) 0.85f else 1.15f,
                label = "swipe_icon_scale"
            )

            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .clip(RoundedCornerShape(18.dp))
                    .background(CampusRed)
                    .padding(horizontal = 24.dp),
                contentAlignment = alignment
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    modifier = Modifier.scale(scale)
                ) {
                    if (direction == SwipeToDismissBoxValue.StartToEnd) {
                        Icon(
                            imageVector = Icons.Filled.Delete,
                            contentDescription = "Swipe to Delete",
                            tint = Color.White,
                            modifier = Modifier.size(26.dp)
                        )
                        Text(
                            text = "Delete ${exam.courseCode}",
                            color = Color.White,
                            fontWeight = FontWeight.Bold,
                            style = MaterialTheme.typography.titleSmall
                        )
                    } else {
                        Text(
                            text = "Delete ${exam.courseCode}",
                            color = Color.White,
                            fontWeight = FontWeight.Bold,
                            style = MaterialTheme.typography.titleSmall
                        )
                        Icon(
                            imageVector = Icons.Filled.Delete,
                            contentDescription = "Swipe to Delete",
                            tint = Color.White,
                            modifier = Modifier.size(26.dp)
                        )
                    }
                }
            }
        },
        content = {
            ExamPaperCard(
                exam = exam,
                countdownInfo = countdownInfo,
                onAlarmToggle = onAlarmToggle,
                onNavigate = onNavigate,
                onViewRules = onViewRules,
                onTriggerTestAlarm = onTriggerTestAlarm,
                onDelete = onDeleteRequest
            )
        }
    )
}

@Composable
fun ExamPaperCard(
    exam: ExamScheduleEntity,
    countdownInfo: ExamCountdownInfo,
    onAlarmToggle: () -> Unit,
    onNavigate: () -> Unit,
    onViewRules: () -> Unit,
    onTriggerTestAlarm: () -> Unit,
    onDelete: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .testTag("exam_card_${exam.courseCode}"),
        shape = RoundedCornerShape(18.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            // Top Row: Course Code, Countdown badge, Date and Delete icon button
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Surface(
                        shape = RoundedCornerShape(8.dp),
                        color = CampusRed.copy(alpha = 0.12f)
                    ) {
                        Text(
                            text = exam.courseCode,
                            modifier = Modifier.padding(horizontal = 10.dp, vertical = 4.dp),
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold,
                            color = CampusRed
                        )
                    }

                    // Days remaining pill badge
                    val badgeColor = when {
                        countdownInfo.isToday -> CampusRed
                        countdownInfo.isTomorrow -> Color(0xFFF97316)
                        countdownInfo.daysRemaining in 2..5 -> Color(0xFFF59E0B)
                        else -> AcademicBlue
                    }

                    Surface(
                        shape = RoundedCornerShape(6.dp),
                        color = badgeColor.copy(alpha = 0.12f)
                    ) {
                        Text(
                            text = countdownInfo.formattedDaysRemaining,
                            modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp),
                            style = MaterialTheme.typography.labelSmall.copy(fontSize = 11.sp),
                            fontWeight = FontWeight.Bold,
                            color = badgeColor
                        )
                    }
                }

                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    Surface(
                        shape = RoundedCornerShape(8.dp),
                        color = Slate200
                    ) {
                        Row(
                            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(Icons.Filled.CalendarToday, contentDescription = null, modifier = Modifier.size(13.dp), tint = Slate700)
                            Spacer(modifier = Modifier.width(4.dp))
                            Text(
                                text = exam.examDate,
                                style = MaterialTheme.typography.labelSmall,
                                fontWeight = FontWeight.Bold,
                                color = Slate700
                            )
                        }
                    }

                    // Delete Icon Button for individual exam entry
                    IconButton(
                        onClick = onDelete,
                        modifier = Modifier
                            .size(36.dp)
                            .testTag("delete_exam_button_${exam.courseCode}")
                    ) {
                        Icon(
                            imageVector = Icons.Outlined.Delete,
                            contentDescription = "Delete ${exam.courseCode} exam entry",
                            tint = CampusRed,
                            modifier = Modifier.size(20.dp)
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(10.dp))

            Text(
                text = exam.courseTitle,
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onSurface
            )

            Spacer(modifier = Modifier.height(8.dp))

            // Details
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(Icons.Filled.AccessTime, contentDescription = null, tint = AcademicBlue, modifier = Modifier.size(16.dp))
                Spacer(modifier = Modifier.width(4.dp))
                Text(
                    text = "${exam.startTime} - ${exam.endTime} (3.0 hrs)",
                    style = MaterialTheme.typography.bodySmall,
                    fontWeight = FontWeight.SemiBold
                )
                Spacer(modifier = Modifier.width(12.dp))
                Icon(Icons.Filled.Place, contentDescription = null, tint = CampusGreen, modifier = Modifier.size(16.dp))
                Spacer(modifier = Modifier.width(4.dp))
                Text(
                    text = exam.venue,
                    style = MaterialTheme.typography.bodySmall,
                    fontWeight = FontWeight.Bold
                )
            }

            Spacer(modifier = Modifier.height(4.dp))

            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(Icons.Filled.Badge, contentDescription = null, tint = Slate600, modifier = Modifier.size(16.dp))
                Spacer(modifier = Modifier.width(4.dp))
                Text(
                    text = exam.seatRange,
                    style = MaterialTheme.typography.bodySmall,
                    color = Slate600
                )
            }

            Spacer(modifier = Modifier.height(12.dp))

            // Departure Highlight Banner
            Surface(
                shape = RoundedCornerShape(12.dp),
                color = AcademicGold.copy(alpha = 0.12f),
                modifier = Modifier.fillMaxWidth()
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(10.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column {
                        Text(
                            text = "SMART DEPARTURE TIME",
                            style = MaterialTheme.typography.labelSmall.copy(fontSize = 10.sp),
                            color = AcademicGold,
                            fontWeight = FontWeight.ExtraBold
                        )
                        Text(
                            text = "Leave by ${exam.suggestedLeaveTime} (~${exam.walkingTimeMinutes} min walk)",
                            style = MaterialTheme.typography.bodyMedium,
                            fontWeight = FontWeight.Bold,
                            color = Slate900
                        )
                    }

                    Switch(
                        checked = exam.isAlarmSet,
                        onCheckedChange = { onAlarmToggle() },
                        colors = SwitchDefaults.colors(checkedThumbColor = AcademicGold, checkedTrackColor = AcademicGold.copy(alpha = 0.5f))
                    )
                }
            }

            Spacer(modifier = Modifier.height(12.dp))

            // Action Row
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                OutlinedButton(
                    onClick = onViewRules,
                    modifier = Modifier.weight(1f),
                    shape = RoundedCornerShape(10.dp)
                ) {
                    Icon(Icons.Filled.Info, contentDescription = null, modifier = Modifier.size(16.dp))
                    Spacer(modifier = Modifier.width(4.dp))
                    Text("Hall Rules", style = MaterialTheme.typography.labelMedium)
                }

                Button(
                    onClick = onNavigate,
                    modifier = Modifier.weight(1f),
                    shape = RoundedCornerShape(10.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = AcademicBlue)
                ) {
                    Icon(Icons.Filled.Navigation, contentDescription = null, modifier = Modifier.size(16.dp))
                    Spacer(modifier = Modifier.width(4.dp))
                    Text("Find Hall", style = MaterialTheme.typography.labelMedium)
                }
            }
        }
    }
}


