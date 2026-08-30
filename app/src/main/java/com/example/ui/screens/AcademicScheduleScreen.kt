package com.example.ui.screens

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.automirrored.filled.List
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Alarm
import androidx.compose.material.icons.filled.AlarmOff
import androidx.compose.material.icons.filled.Book
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.CalendarToday
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Clear
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.DateRange
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Event
import androidx.compose.material.icons.filled.FilterList
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.RadioButtonUnchecked
import androidx.compose.material.icons.filled.Schedule
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.School
import androidx.compose.material.icons.filled.Science
import androidx.compose.material.icons.filled.Today
import androidx.compose.material.icons.filled.ViewAgenda
import androidx.compose.material.icons.filled.ViewList
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExtendedFloatingActionButton
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarDuration
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Surface
import androidx.compose.material3.SwipeToDismissBox
import androidx.compose.material3.SwipeToDismissBoxValue
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Tab
import androidx.compose.material3.TabRow
import androidx.compose.material3.TabRowDefaults
import androidx.compose.material3.TabRowDefaults.tabIndicatorOffset
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.rememberSwipeToDismissBoxState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.data.local.entity.AcademicEventType
import com.example.data.local.entity.AcademicScheduleEventEntity
import com.example.ui.AcademicScheduleUiState
import com.example.ui.AcademicScheduleViewModel
import com.example.ui.ScheduleViewMode

/**
 * Modern Jetpack Compose screen that displays the student's academic class schedule
 * with day filtering, search, class management, reminder toggles, and a Floating Action Button
 * to add new schedule entries.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AcademicScheduleScreen(
    modifier: Modifier = Modifier,
    viewModel: AcademicScheduleViewModel = viewModel(),
    onNavigateToVenueMap: ((venueName: String, locationCode: String?) -> Unit)? = null
) {
    val uiState by viewModel.uiState.collectAsState()
    val snackbarHostState = remember { SnackbarHostState() }
    var showAddEventDialog by remember { mutableStateOf(false) }
    var eventToEdit by remember { mutableStateOf<AcademicScheduleEventEntity?>(null) }
    var eventToDelete by remember { mutableStateOf<AcademicScheduleEventEntity?>(null) }

    LaunchedEffect(uiState.userMessage) {
        uiState.userMessage?.let { message ->
            snackbarHostState.showSnackbar(
                message = message,
                duration = SnackbarDuration.Short
            )
            viewModel.clearUserMessage()
        }
    }

    Scaffold(
        modifier = modifier
            .fillMaxSize()
            .testTag("academic_schedule_screen"),
        snackbarHost = { SnackbarHost(hostState = snackbarHostState) },
        topBar = {
            AcademicScheduleTopBar(
                searchQuery = uiState.searchQuery,
                onSearchQueryChanged = { viewModel.setSearchQuery(it) },
                onClearSearch = { viewModel.setSearchQuery("") },
                viewMode = uiState.viewMode,
                onToggleViewMode = { viewModel.toggleViewMode() }
            )
        },
        floatingActionButton = {
            ExtendedFloatingActionButton(
                onClick = { showAddEventDialog = true },
                modifier = Modifier.testTag("add_schedule_event_fab"),
                containerColor = MaterialTheme.colorScheme.primary,
                contentColor = MaterialTheme.colorScheme.onPrimary,
                icon = {
                    Icon(
                        imageVector = Icons.Default.Add,
                        contentDescription = "Add New Schedule Entry"
                    )
                },
                text = {
                    Text(
                        text = "Add Class",
                        fontWeight = FontWeight.SemiBold
                    )
                }
            )
        }
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
        ) {
            // View Mode Selector Segmented Tabs (List vs Day Calendar)
            ScheduleViewModeSelector(
                currentMode = uiState.viewMode,
                onSelectMode = { viewModel.setViewMode(it) }
            )

            if (uiState.isLoading) {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator()
                }
            } else if (uiState.viewMode == ScheduleViewMode.DAY_CALENDAR) {
                // Day-by-Day Calendar Timetable View
                AcademicScheduleDayCalendarView(
                    events = uiState.allEvents,
                    selectedDay = uiState.selectedDayOfWeek ?: java.time.LocalDate.now().dayOfWeek.value,
                    onSelectDay = { viewModel.setDayOfWeekFilter(it) },
                    onToggleCompletion = { eventId, isCompleted ->
                        viewModel.toggleEventCompletion(eventId, isCompleted)
                    },
                    onToggleAlarm = { eventId, isEnabled ->
                        viewModel.toggleAlarm(eventId, isEnabled)
                    },
                    onEditEvent = { eventToEdit = it },
                    onDeleteEvent = { eventToDelete = it },
                    onDirectDelete = { viewModel.deleteEvent(it) },
                    onNavigateToVenue = onNavigateToVenueMap,
                    onAddEventForDay = { dayInt ->
                        showAddEventDialog = true
                    }
                )
            } else {
                // Standard List View with Filter Strip and Metrics
                ScheduleFilterBar(
                    selectedDay = uiState.selectedDayOfWeek,
                    selectedType = uiState.selectedFilterType,
                    onSelectDay = { day -> viewModel.setDayOfWeekFilter(day) },
                    onSelectType = { type -> viewModel.setFilterType(type) },
                    onClearFilters = { viewModel.clearFilters() }
                )

                // Schedule Overview Metrics Banner
                ScheduleMetricsSummaryCard(
                    totalCount = uiState.totalEventCount,
                    completedCount = uiState.completedEventCount,
                    pendingCount = uiState.pendingEventCount,
                    todayCount = uiState.todayEvents.size
                )

                if (uiState.filteredEvents.isEmpty()) {
                    EmptyScheduleState(
                        hasFilter = uiState.selectedDayOfWeek != null || uiState.selectedFilterType != null || uiState.searchQuery.isNotBlank(),
                        onAddClick = { showAddEventDialog = true },
                        onResetFilters = { viewModel.clearFilters() }
                    )
                } else {
                    LazyColumn(
                        modifier = Modifier
                            .fillMaxSize()
                            .testTag("class_list"),
                        contentPadding = PaddingValues(horizontal = 16.dp, vertical = 12.dp),
                        verticalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        items(
                            items = uiState.filteredEvents,
                            key = { it.id }
                        ) { event ->
                            val dismissState = rememberSwipeToDismissBoxState(
                                confirmValueChange = { dismissValue ->
                                    if (dismissValue == SwipeToDismissBoxValue.EndToStart || dismissValue == SwipeToDismissBoxValue.StartToEnd) {
                                        viewModel.deleteEvent(event)
                                        true
                                    } else {
                                        false
                                    }
                                }
                            )

                            SwipeToDismissBox(
                                state = dismissState,
                                enableDismissFromStartToEnd = true,
                                enableDismissFromEndToStart = true,
                                backgroundContent = {
                                    val direction = dismissState.dismissDirection
                                    val isStartToEnd = direction == SwipeToDismissBoxValue.StartToEnd
                                    val alignment = if (isStartToEnd) Alignment.CenterStart else Alignment.CenterEnd

                                    Box(
                                        modifier = Modifier
                                            .fillMaxSize()
                                            .clip(RoundedCornerShape(16.dp))
                                            .background(MaterialTheme.colorScheme.errorContainer)
                                            .padding(horizontal = 20.dp),
                                        contentAlignment = alignment
                                    ) {
                                        Row(
                                            verticalAlignment = Alignment.CenterVertically,
                                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                                        ) {
                                            Icon(
                                                imageVector = Icons.Default.Delete,
                                                contentDescription = "Swipe to Delete",
                                                tint = MaterialTheme.colorScheme.onErrorContainer
                                            )
                                            Text(
                                                text = "Delete Class",
                                                style = MaterialTheme.typography.labelLarge.copy(
                                                    fontWeight = FontWeight.Bold
                                                ),
                                                color = MaterialTheme.colorScheme.onErrorContainer
                                            )
                                        }
                                    }
                                },
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .testTag("swipe_to_delete_box_${event.id}")
                            ) {
                                AcademicClassCard(
                                    event = event,
                                    onToggleCompletion = { isCompleted ->
                                        viewModel.toggleEventCompletion(event.id, isCompleted)
                                    },
                                    onToggleAlarm = { isEnabled ->
                                        viewModel.toggleAlarm(event.id, isEnabled)
                                    },
                                    onEditClick = { eventToEdit = event },
                                    onDeleteClick = { eventToDelete = event },
                                    onNavigateToVenue = onNavigateToVenueMap
                                )
                            }
                        }

                        item {
                            Spacer(modifier = Modifier.height(80.dp)) // Extra space for FAB clearance
                        }
                    }
                }
            }
        }
    }

    // Dialog: Add New Schedule Entry
    if (showAddEventDialog) {
        AddOrEditScheduleDialog(
            initialEvent = null,
            onDismiss = { showAddEventDialog = false },
            onSave = { newEvent ->
                viewModel.addEvent(newEvent)
                showAddEventDialog = false
            }
        )
    }

    // Dialog: Edit Existing Schedule Entry
    eventToEdit?.let { event ->
        AddOrEditScheduleDialog(
            initialEvent = event,
            onDismiss = { eventToEdit = null },
            onSave = { updatedEvent ->
                viewModel.updateEvent(updatedEvent)
                eventToEdit = null
            }
        )
    }

    // Dialog: Delete Confirmation
    eventToDelete?.let { event ->
        AlertDialog(
            onDismissRequest = { eventToDelete = null },
            title = { Text("Delete Schedule Entry") },
            text = {
                Text("Are you sure you want to delete '${event.title}' (${event.courseCode}) from your academic schedule?")
            },
            confirmButton = {
                Button(
                    onClick = {
                        viewModel.deleteEvent(event)
                        eventToDelete = null
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.error)
                ) {
                    Text("Delete")
                }
            },
            dismissButton = {
                TextButton(onClick = { eventToDelete = null }) {
                    Text("Cancel")
                }
            }
        )
    }
}

/**
 * Top App Bar with embedded search field and academic identity branding.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun AcademicScheduleTopBar(
    searchQuery: String,
    onSearchQueryChanged: (String) -> Unit,
    onClearSearch: () -> Unit,
    viewMode: ScheduleViewMode = ScheduleViewMode.LIST,
    onToggleViewMode: () -> Unit = {}
) {
    val focusManager = LocalFocusManager.current
    var isSearchExpanded by remember { mutableStateOf(false) }

    Surface(
        color = MaterialTheme.colorScheme.surface,
        tonalElevation = 2.dp
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 8.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier.weight(1f)
                ) {
                    Box(
                        modifier = Modifier
                            .size(40.dp)
                            .clip(RoundedCornerShape(12.dp))
                            .background(MaterialTheme.colorScheme.primaryContainer),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            imageVector = Icons.Default.School,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.onPrimaryContainer,
                            modifier = Modifier.size(24.dp)
                        )
                    }
                    Spacer(modifier = Modifier.width(12.dp))
                    Column {
                        Text(
                            text = "Academic Schedule",
                            style = MaterialTheme.typography.titleLarge.copy(
                                fontWeight = FontWeight.Bold,
                                letterSpacing = (-0.5).sp
                            )
                        )
                        Text(
                            text = if (viewMode == ScheduleViewMode.DAY_CALENDAR) "Day-by-Day Timetable" else "Lectures, Labs & Exams",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }

                Row(verticalAlignment = Alignment.CenterVertically) {
                    IconButton(
                        onClick = onToggleViewMode,
                        modifier = Modifier.testTag("top_bar_view_mode_toggle_btn")
                    ) {
                        Icon(
                            imageVector = if (viewMode == ScheduleViewMode.DAY_CALENDAR) Icons.Default.ViewList else Icons.Default.CalendarMonth,
                            contentDescription = if (viewMode == ScheduleViewMode.DAY_CALENDAR) "Switch to List View" else "Switch to Day Calendar View",
                            tint = MaterialTheme.colorScheme.primary
                        )
                    }

                    IconButton(
                        onClick = {
                            isSearchExpanded = !isSearchExpanded
                            if (!isSearchExpanded) {
                                onClearSearch()
                            }
                        }
                    ) {
                        Icon(
                            imageVector = if (isSearchExpanded) Icons.Default.Close else Icons.Default.Search,
                            contentDescription = "Toggle Search",
                            tint = MaterialTheme.colorScheme.primary
                        )
                    }
                }
            }

            AnimatedVisibility(
                visible = isSearchExpanded || searchQuery.isNotBlank(),
                enter = fadeIn() + slideInVertically(),
                exit = fadeOut()
            ) {
                OutlinedTextField(
                    value = searchQuery,
                    onValueChange = onSearchQueryChanged,
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(top = 8.dp)
                        .testTag("course_search_bar"),
                    placeholder = { Text("Search course, venue, lecturer, or notes...") },
                    leadingIcon = {
                        Icon(
                            imageVector = Icons.Default.Search,
                            contentDescription = "Search"
                        )
                    },
                    trailingIcon = {
                        if (searchQuery.isNotEmpty()) {
                            IconButton(onClick = onClearSearch) {
                                Icon(
                                    imageVector = Icons.Default.Clear,
                                    contentDescription = "Clear Search"
                                )
                            }
                        }
                    },
                    singleLine = true,
                    shape = RoundedCornerShape(12.dp),
                    keyboardOptions = KeyboardOptions(imeAction = ImeAction.Search),
                    keyboardActions = KeyboardActions(onSearch = { focusManager.clearFocus() }),
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = MaterialTheme.colorScheme.primary,
                        unfocusedBorderColor = MaterialTheme.colorScheme.outlineVariant
                    )
                )
            }
        }
    }
}

/**
 * Filter bar supporting days of week (Mon-Sat) and Event Types (Class, Lab, Exam, etc.).
 */
@Composable
private fun ScheduleFilterBar(
    selectedDay: Int?,
    selectedType: AcademicEventType?,
    onSelectDay: (Int?) -> Unit,
    onSelectType: (AcademicEventType?) -> Unit,
    onClearFilters: () -> Unit
) {
    val dayLabels = listOf(
        1 to "Mon",
        2 to "Tue",
        3 to "Wed",
        4 to "Thu",
        5 to "Fri",
        6 to "Sat"
    )

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .background(MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.3f))
            .padding(vertical = 8.dp)
    ) {
        // Day selector chips
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .horizontalScroll(rememberScrollState())
                .padding(horizontal = 16.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            FilterChip(
                selected = selectedDay == null,
                onClick = { onSelectDay(null) },
                label = { Text("All Days") },
                colors = FilterChipDefaults.filterChipColors(
                    selectedContainerColor = MaterialTheme.colorScheme.primary,
                    selectedLabelColor = MaterialTheme.colorScheme.onPrimary
                )
            )

            dayLabels.forEach { (dayInt, label) ->
                FilterChip(
                    selected = selectedDay == dayInt,
                    onClick = { onSelectDay(if (selectedDay == dayInt) null else dayInt) },
                    label = { Text(label) },
                    colors = FilterChipDefaults.filterChipColors(
                        selectedContainerColor = MaterialTheme.colorScheme.primary,
                        selectedLabelColor = MaterialTheme.colorScheme.onPrimary
                    )
                )
            }
        }

        Spacer(modifier = Modifier.height(4.dp))

        // Event Type filter chips
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .horizontalScroll(rememberScrollState())
                .padding(horizontal = 16.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            FilterChip(
                selected = selectedType == null,
                onClick = { onSelectType(null) },
                label = { Text("All Types") },
                leadingIcon = {
                    Icon(
                        imageVector = Icons.Default.FilterList,
                        contentDescription = null,
                        modifier = Modifier.size(16.dp)
                    )
                }
            )

            AcademicEventType.values().forEach { type ->
                val typeLabel = when (type) {
                    AcademicEventType.CLASS -> "Lectures"
                    AcademicEventType.LAB -> "Labs"
                    AcademicEventType.EXAM -> "Exams"
                    AcademicEventType.STUDY_SESSION -> "Study Pods"
                    AcademicEventType.TUTORIAL -> "Tutorials"
                    AcademicEventType.ASSIGNMENT_DEADLINE -> "Deadlines"
                }

                FilterChip(
                    selected = selectedType == type,
                    onClick = { onSelectType(if (selectedType == type) null else type) },
                    label = { Text(typeLabel) }
                )
            }
        }
    }
}

/**
 * Metric summary card displaying counts for today's commitments, total enrolled classes, and completion status.
 */
@Composable
private fun ScheduleMetricsSummaryCard(
    totalCount: Int,
    completedCount: Int,
    pendingCount: Int,
    todayCount: Int
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.secondaryContainer.copy(alpha = 0.4f)
        )
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(14.dp),
            horizontalArrangement = Arrangement.SpaceAround,
            verticalAlignment = Alignment.CenterVertically
        ) {
            MetricItem(
                count = todayCount.toString(),
                label = "Today's",
                badgeColor = MaterialTheme.colorScheme.primary
            )
            Box(
                modifier = Modifier
                    .width(1.dp)
                    .height(28.dp)
                    .background(MaterialTheme.colorScheme.outlineVariant)
            )
            MetricItem(
                count = totalCount.toString(),
                label = "Total Entries",
                badgeColor = MaterialTheme.colorScheme.secondary
            )
            Box(
                modifier = Modifier
                    .width(1.dp)
                    .height(28.dp)
                    .background(MaterialTheme.colorScheme.outlineVariant)
            )
            MetricItem(
                count = completedCount.toString(),
                label = "Completed",
                badgeColor = Color(0xFF10B981)
            )
        }
    }
}

@Composable
private fun MetricItem(
    count: String,
    label: String,
    badgeColor: Color
) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(
            text = count,
            style = MaterialTheme.typography.titleLarge.copy(
                fontWeight = FontWeight.Bold,
                color = badgeColor
            )
        )
        Text(
            text = label,
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

/**
 * Visual card item representing a single academic class / schedule event.
 */
@Composable
private fun AcademicClassCard(
    event: AcademicScheduleEventEntity,
    onToggleCompletion: (Boolean) -> Unit,
    onToggleAlarm: (Boolean) -> Unit,
    onEditClick: () -> Unit,
    onDeleteClick: () -> Unit,
    onNavigateToVenue: ((venueName: String, locationCode: String?) -> Unit)?
) {
    var menuExpanded by remember { mutableStateOf(false) }
    val cardBorderColor by animateColorAsState(
        targetValue = if (event.isCompleted) Color(0xFF10B981).copy(alpha = 0.5f) else Color.Transparent,
        label = "borderColor"
    )

    Card(
        modifier = Modifier
            .fillMaxWidth()
            .testTag("class_item_card_${event.id}"),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(
            containerColor = if (event.isCompleted)
                MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.4f)
            else
                MaterialTheme.colorScheme.surface
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = if (event.isCompleted) 0.dp else 2.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
        ) {
            // Header Row: Course Code badge, Type Chip, and Overflow Menu
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    // Course Code Chip
                    Surface(
                        shape = RoundedCornerShape(8.dp),
                        color = Color(event.colorHex).copy(alpha = 0.15f)
                    ) {
                        Text(
                            text = if (event.courseCode.isNotBlank()) event.courseCode else "ACADEMIC",
                            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                            style = MaterialTheme.typography.labelMedium.copy(
                                fontWeight = FontWeight.Bold,
                                color = Color(event.colorHex)
                            )
                        )
                    }

                    // Event Type Chip
                    val typeDisplay = when (event.eventType) {
                        "CLASS" -> "Lecture"
                        "LAB" -> "Lab"
                        "EXAM" -> "Exam"
                        "STUDY_SESSION" -> "Study Pod"
                        "TUTORIAL" -> "Tutorial"
                        else -> event.eventType
                    }
                    Surface(
                        shape = RoundedCornerShape(8.dp),
                        color = MaterialTheme.colorScheme.secondaryContainer.copy(alpha = 0.6f)
                    ) {
                        Text(
                            text = typeDisplay,
                            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.onSecondaryContainer
                        )
                    }

                    if (event.isRecurring && event.dayOfWeek != null) {
                        val dayName = getDayName(event.dayOfWeek)
                        Text(
                            text = "Every $dayName",
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.primary,
                            fontWeight = FontWeight.Medium
                        )
                    } else if (event.eventDate != null) {
                        Text(
                            text = event.eventDate,
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.primary,
                            fontWeight = FontWeight.Medium
                        )
                    }
                }

                Box {
                    IconButton(
                        onClick = { menuExpanded = true },
                        modifier = Modifier.size(28.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Default.MoreVert,
                            contentDescription = "Options",
                            tint = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                    DropdownMenu(
                        expanded = menuExpanded,
                        onDismissRequest = { menuExpanded = false }
                    ) {
                        DropdownMenuItem(
                            text = { Text("Edit Entry") },
                            leadingIcon = { Icon(Icons.Default.Edit, contentDescription = null) },
                            onClick = {
                                menuExpanded = false
                                onEditClick()
                            }
                        )
                        if (onNavigateToVenue != null && event.venue.isNotBlank()) {
                            DropdownMenuItem(
                                text = { Text("Show Venue on Map") },
                                leadingIcon = { Icon(Icons.Default.LocationOn, contentDescription = null) },
                                onClick = {
                                    menuExpanded = false
                                    onNavigateToVenue(event.venue, event.campusLocationCode)
                                }
                            )
                        }
                        DropdownMenuItem(
                            text = { Text("Delete Entry", color = MaterialTheme.colorScheme.error) },
                            leadingIcon = { Icon(Icons.Default.Delete, contentDescription = null, tint = MaterialTheme.colorScheme.error) },
                            onClick = {
                                menuExpanded = false
                                onDeleteClick()
                            }
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(10.dp))

            // Title & Completed Toggle
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                IconButton(
                    onClick = { onToggleCompletion(!event.isCompleted) },
                    modifier = Modifier.size(32.dp)
                ) {
                    Icon(
                        imageVector = if (event.isCompleted) Icons.Default.CheckCircle else Icons.Default.RadioButtonUnchecked,
                        contentDescription = if (event.isCompleted) "Mark as pending" else "Mark as completed",
                        tint = if (event.isCompleted) Color(0xFF10B981) else MaterialTheme.colorScheme.outline
                    )
                }
                Spacer(modifier = Modifier.width(8.dp))
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = event.title,
                        style = MaterialTheme.typography.titleMedium.copy(
                            fontWeight = FontWeight.Bold,
                            textDecoration = if (event.isCompleted) TextDecoration.LineThrough else TextDecoration.None
                        ),
                        color = if (event.isCompleted) MaterialTheme.colorScheme.onSurfaceVariant else MaterialTheme.colorScheme.onSurface
                    )
                    if (event.instructorOrLead.isNotBlank()) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            modifier = Modifier.padding(top = 2.dp)
                        ) {
                            Icon(
                                imageVector = Icons.Default.Person,
                                contentDescription = null,
                                modifier = Modifier.size(14.dp),
                                tint = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                            Spacer(modifier = Modifier.width(4.dp))
                            Text(
                                text = event.instructorOrLead,
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(12.dp))

            // Time & Venue Row
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                // Time window
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        imageVector = Icons.Default.Schedule,
                        contentDescription = null,
                        modifier = Modifier.size(16.dp),
                        tint = MaterialTheme.colorScheme.primary
                    )
                    Spacer(modifier = Modifier.width(6.dp))
                    Text(
                        text = "${event.startTime} - ${event.endTime}",
                        style = MaterialTheme.typography.bodyMedium.copy(
                            fontWeight = FontWeight.SemiBold
                        )
                    )
                }

                // Venue badge / clickable navigator
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier
                        .clip(RoundedCornerShape(8.dp))
                        .clickable(enabled = onNavigateToVenue != null) {
                            onNavigateToVenue?.invoke(event.venue, event.campusLocationCode)
                        }
                        .padding(horizontal = 6.dp, vertical = 2.dp)
                ) {
                    Icon(
                        imageVector = Icons.Default.LocationOn,
                        contentDescription = null,
                        modifier = Modifier.size(16.dp),
                        tint = Color(0xFFD97706)
                    )
                    Spacer(modifier = Modifier.width(4.dp))
                    Text(
                        text = event.venue,
                        style = MaterialTheme.typography.bodySmall.copy(fontWeight = FontWeight.Medium),
                        color = MaterialTheme.colorScheme.onSurface,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                }
            }

            // Optional Notes
            if (event.notes.isNotBlank()) {
                Spacer(modifier = Modifier.height(8.dp))
                HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f))
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = event.notes,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis
                )
            }

            // Bottom action row: Reminder alarm toggle
            Spacer(modifier = Modifier.height(8.dp))
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.End
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier
                        .clip(RoundedCornerShape(8.dp))
                        .clickable { onToggleAlarm(!event.isAlarmEnabled) }
                        .padding(horizontal = 8.dp, vertical = 4.dp)
                ) {
                    Icon(
                        imageVector = if (event.isAlarmEnabled) Icons.Default.Alarm else Icons.Default.AlarmOff,
                        contentDescription = "Toggle Alarm",
                        modifier = Modifier.size(16.dp),
                        tint = if (event.isAlarmEnabled) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.outline
                    )
                    Spacer(modifier = Modifier.width(4.dp))
                    Text(
                        text = if (event.isAlarmEnabled) "${event.reminderMinutesBefore}m reminder" else "Reminder off",
                        style = MaterialTheme.typography.labelSmall,
                        color = if (event.isAlarmEnabled) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.outline
                    )
                }
            }
        }
    }
}

/**
 * Modal dialog for creating or editing an academic schedule event.
 */
@Composable
private fun AddOrEditScheduleDialog(
    initialEvent: AcademicScheduleEventEntity?,
    onDismiss: () -> Unit,
    onSave: (AcademicScheduleEventEntity) -> Unit
) {
    var title by remember { mutableStateOf(initialEvent?.title ?: "") }
    var courseCode by remember { mutableStateOf(initialEvent?.courseCode ?: "") }
    var eventType by remember {
        mutableStateOf(
            initialEvent?.eventType?.let {
                try { AcademicEventType.valueOf(it) } catch (e: Exception) { AcademicEventType.CLASS }
            } ?: AcademicEventType.CLASS
        )
    }
    var dayOfWeek by remember { mutableIntStateOf(initialEvent?.dayOfWeek ?: 1) }
    var isRecurring by remember { mutableStateOf(initialEvent?.isRecurring ?: true) }
    var eventDate by remember { mutableStateOf(initialEvent?.eventDate ?: "") }
    var startTime by remember { mutableStateOf(initialEvent?.startTime ?: "08:30") }
    var endTime by remember { mutableStateOf(initialEvent?.endTime ?: "10:30") }
    var venue by remember { mutableStateOf(initialEvent?.venue ?: "") }
    var instructor by remember { mutableStateOf(initialEvent?.instructorOrLead ?: "") }
    var notes by remember { mutableStateOf(initialEvent?.notes ?: "") }
    var reminderMinutes by remember { mutableIntStateOf(initialEvent?.reminderMinutesBefore ?: 15) }
    var isAlarmEnabled by remember { mutableStateOf(initialEvent?.isAlarmEnabled ?: true) }

    var hasError by remember { mutableStateOf(false) }

    val daysOfWeekOptions = listOf(
        1 to "Monday",
        2 to "Tuesday",
        3 to "Wednesday",
        4 to "Thursday",
        5 to "Friday",
        6 to "Saturday"
    )

    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Text(
                text = if (initialEvent == null) "Add Academic Schedule Entry" else "Edit Schedule Entry",
                style = MaterialTheme.typography.titleLarge.copy(fontWeight = FontWeight.Bold)
            )
        },
        text = {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .verticalScroll(rememberScrollState()),
                verticalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                // Event Type Selector Chips
                Text("Event Type", style = MaterialTheme.typography.labelMedium)
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .horizontalScroll(rememberScrollState()),
                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    AcademicEventType.values().forEach { type ->
                        val label = when (type) {
                            AcademicEventType.CLASS -> "Lecture"
                            AcademicEventType.LAB -> "Lab"
                            AcademicEventType.EXAM -> "Exam"
                            AcademicEventType.STUDY_SESSION -> "Study Pod"
                            AcademicEventType.TUTORIAL -> "Tutorial"
                            AcademicEventType.ASSIGNMENT_DEADLINE -> "Deadline"
                        }
                        FilterChip(
                            selected = eventType == type,
                            onClick = { eventType = type },
                            label = { Text(label) }
                        )
                    }
                }

                // Course Code and Title
                OutlinedTextField(
                    value = courseCode,
                    onValueChange = { courseCode = it },
                    label = { Text("Course Code (e.g. CSCD 302)") },
                    singleLine = true,
                    modifier = Modifier
                        .fillMaxWidth()
                        .testTag("event_course_code_input")
                )

                OutlinedTextField(
                    value = title,
                    onValueChange = {
                        title = it
                        if (it.isNotBlank()) hasError = false
                    },
                    label = { Text("Title / Topic *") },
                    isError = hasError,
                    singleLine = true,
                    modifier = Modifier
                        .fillMaxWidth()
                        .testTag("event_title_input")
                )

                // Recurring Day of Week vs Specific Date
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text("Weekly Recurring Class", style = MaterialTheme.typography.bodyMedium)
                    Switch(
                        checked = isRecurring,
                        onCheckedChange = { isRecurring = it }
                    )
                }

                if (isRecurring) {
                    Text("Day of Week", style = MaterialTheme.typography.labelMedium)
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .horizontalScroll(rememberScrollState()),
                        horizontalArrangement = Arrangement.spacedBy(6.dp)
                    ) {
                        daysOfWeekOptions.forEach { (dayVal, name) ->
                            FilterChip(
                                selected = dayOfWeek == dayVal,
                                onClick = { dayOfWeek = dayVal },
                                label = { Text(name) }
                            )
                        }
                    }
                } else {
                    OutlinedTextField(
                        value = eventDate,
                        onValueChange = { eventDate = it },
                        label = { Text("Event Date (YYYY-MM-DD)") },
                        placeholder = { Text("2026-08-25") },
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth()
                    )
                }

                // Start & End Time
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    OutlinedTextField(
                        value = startTime,
                        onValueChange = { startTime = it },
                        label = { Text("Start Time") },
                        placeholder = { Text("08:30") },
                        singleLine = true,
                        modifier = Modifier.weight(1f)
                    )
                    OutlinedTextField(
                        value = endTime,
                        onValueChange = { endTime = it },
                        label = { Text("End Time") },
                        placeholder = { Text("10:30") },
                        singleLine = true,
                        modifier = Modifier.weight(1f)
                    )
                }

                // Venue & Lecturer
                OutlinedTextField(
                    value = venue,
                    onValueChange = { venue = it },
                    label = { Text("Venue / Lecture Hall") },
                    placeholder = { Text("e.g. KAB 1, JQB Room 22, Great Hall") },
                    singleLine = true,
                    modifier = Modifier
                        .fillMaxWidth()
                        .testTag("event_venue_input")
                )

                OutlinedTextField(
                    value = instructor,
                    onValueChange = { instructor = it },
                    label = { Text("Lecturer / Lead") },
                    placeholder = { Text("e.g. Dr. K. Mensah") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )

                // Notes / Syllabus Info
                OutlinedTextField(
                    value = notes,
                    onValueChange = { notes = it },
                    label = { Text("Notes / Syllabus Details") },
                    maxLines = 3,
                    modifier = Modifier.fillMaxWidth()
                )

                // Smart Reminder Toggle
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text("Enable Smart Reminder", style = MaterialTheme.typography.bodyMedium)
                    Switch(
                        checked = isAlarmEnabled,
                        onCheckedChange = { isAlarmEnabled = it }
                    )
                }
            }
        },
        confirmButton = {
            Button(
                onClick = {
                    if (title.isBlank()) {
                        hasError = true
                        return@Button
                    }
                    val colorHex = when (eventType) {
                        AcademicEventType.CLASS -> 0xFF0284C7
                        AcademicEventType.EXAM -> 0xFFDC2626
                        AcademicEventType.STUDY_SESSION -> 0xFF059669
                        AcademicEventType.LAB -> 0xFFD97706
                        AcademicEventType.TUTORIAL -> 0xFF7C3AED
                        AcademicEventType.ASSIGNMENT_DEADLINE -> 0xFFE11D48
                    }
                    val event = initialEvent?.copy(
                        title = title.trim(),
                        courseCode = courseCode.trim().uppercase(),
                        eventType = eventType.name,
                        dayOfWeek = if (isRecurring) dayOfWeek else null,
                        eventDate = if (!isRecurring && eventDate.isNotBlank()) eventDate.trim() else null,
                        startTime = startTime.trim(),
                        endTime = endTime.trim(),
                        venue = venue.trim(),
                        instructorOrLead = instructor.trim(),
                        notes = notes.trim(),
                        isRecurring = isRecurring,
                        isAlarmEnabled = isAlarmEnabled,
                        reminderMinutesBefore = reminderMinutes,
                        colorHex = colorHex
                    ) ?: AcademicScheduleEventEntity(
                        title = title.trim(),
                        courseCode = courseCode.trim().uppercase(),
                        eventType = eventType.name,
                        dayOfWeek = if (isRecurring) dayOfWeek else null,
                        eventDate = if (!isRecurring && eventDate.isNotBlank()) eventDate.trim() else null,
                        startTime = startTime.trim(),
                        endTime = endTime.trim(),
                        venue = venue.trim(),
                        instructorOrLead = instructor.trim(),
                        notes = notes.trim(),
                        isRecurring = isRecurring,
                        isAlarmEnabled = isAlarmEnabled,
                        reminderMinutesBefore = reminderMinutes,
                        colorHex = colorHex
                    )
                    onSave(event)
                },
                modifier = Modifier.testTag("save_schedule_event_btn")
            ) {
                Text("Save")
            }
        },
        dismissButton = {
            TextButton(
                onClick = onDismiss,
                modifier = Modifier.testTag("cancel_schedule_event_btn")
            ) {
                Text("Cancel")
            }
        }
    )
}

/**
 * Clean empty state presentation when no classes match the search or filter query.
 */
@Composable
private fun EmptyScheduleState(
    hasFilter: Boolean,
    onAddClick: () -> Unit,
    onResetFilters: () -> Unit
) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .padding(32.dp),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Box(
                modifier = Modifier
                    .size(80.dp)
                    .clip(CircleShape)
                    .background(MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.5f)),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = Icons.Default.Book,
                    contentDescription = null,
                    modifier = Modifier.size(40.dp),
                    tint = MaterialTheme.colorScheme.primary
                )
            }
            Spacer(modifier = Modifier.height(16.dp))
            Text(
                text = if (hasFilter) "No matching schedule events" else "No classes scheduled yet",
                style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold)
            )
            Spacer(modifier = Modifier.height(6.dp))
            Text(
                text = if (hasFilter)
                    "Try resetting your day, type, or search filters to see all events."
                else
                    "Tap below to add your first lecture, lab, or study session.",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.padding(horizontal = 16.dp),
                textAlign = androidx.compose.ui.text.style.TextAlign.Center
            )
            Spacer(modifier = Modifier.height(20.dp))
            if (hasFilter) {
                OutlinedButton(onClick = onResetFilters) {
                    Text("Reset Filters")
                }
            } else {
                Button(onClick = onAddClick) {
                    Icon(imageVector = Icons.Default.Add, contentDescription = null)
                    Spacer(modifier = Modifier.width(6.dp))
                    Text("Add First Class")
                }
            }
        }
    }
}

private fun getDayName(dayInt: Int): String {
    return when (dayInt) {
        1 -> "Monday"
        2 -> "Tuesday"
        3 -> "Wednesday"
        4 -> "Thursday"
        5 -> "Friday"
        6 -> "Saturday"
        7 -> "Sunday"
        else -> "Monday"
    }
}

/**
 * Segmented toggle control allowing users to switch between the List View and the Day Calendar View.
 */
@Composable
private fun ScheduleViewModeSelector(
    currentMode: ScheduleViewMode,
    onSelectMode: (ScheduleViewMode) -> Unit
) {
    Surface(
        color = MaterialTheme.colorScheme.surface,
        modifier = Modifier.fillMaxWidth()
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 6.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Segment 1: List View
            Surface(
                onClick = { onSelectMode(ScheduleViewMode.LIST) },
                modifier = Modifier
                    .weight(1f)
                    .testTag("view_mode_toggle_list"),
                shape = RoundedCornerShape(12.dp),
                color = if (currentMode == ScheduleViewMode.LIST) {
                    MaterialTheme.colorScheme.primaryContainer
                } else {
                    MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.45f)
                },
                border = if (currentMode == ScheduleViewMode.LIST) {
                    androidx.compose.foundation.BorderStroke(1.5.dp, MaterialTheme.colorScheme.primary)
                } else null
            ) {
                Row(
                    modifier = Modifier
                        .padding(vertical = 10.dp, horizontal = 12.dp),
                    horizontalArrangement = Arrangement.Center,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = Icons.Default.ViewList,
                        contentDescription = "List View",
                        tint = if (currentMode == ScheduleViewMode.LIST) {
                            MaterialTheme.colorScheme.onPrimaryContainer
                        } else {
                            MaterialTheme.colorScheme.onSurfaceVariant
                        },
                        modifier = Modifier.size(18.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = "List View",
                        style = MaterialTheme.typography.labelLarge.copy(
                            fontWeight = if (currentMode == ScheduleViewMode.LIST) FontWeight.Bold else FontWeight.Medium
                        ),
                        color = if (currentMode == ScheduleViewMode.LIST) {
                            MaterialTheme.colorScheme.onPrimaryContainer
                        } else {
                            MaterialTheme.colorScheme.onSurfaceVariant
                        }
                    )
                }
            }

            // Segment 2: Day Calendar View
            Surface(
                onClick = { onSelectMode(ScheduleViewMode.DAY_CALENDAR) },
                modifier = Modifier
                    .weight(1f)
                    .testTag("view_mode_toggle_calendar"),
                shape = RoundedCornerShape(12.dp),
                color = if (currentMode == ScheduleViewMode.DAY_CALENDAR) {
                    MaterialTheme.colorScheme.primaryContainer
                } else {
                    MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.45f)
                },
                border = if (currentMode == ScheduleViewMode.DAY_CALENDAR) {
                    androidx.compose.foundation.BorderStroke(1.5.dp, MaterialTheme.colorScheme.primary)
                } else null
            ) {
                Row(
                    modifier = Modifier
                        .padding(vertical = 10.dp, horizontal = 12.dp),
                    horizontalArrangement = Arrangement.Center,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = Icons.Default.CalendarToday,
                        contentDescription = "Day Calendar",
                        tint = if (currentMode == ScheduleViewMode.DAY_CALENDAR) {
                            MaterialTheme.colorScheme.onPrimaryContainer
                        } else {
                            MaterialTheme.colorScheme.onSurfaceVariant
                        },
                        modifier = Modifier.size(18.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = "Day Calendar",
                        style = MaterialTheme.typography.labelLarge.copy(
                            fontWeight = if (currentMode == ScheduleViewMode.DAY_CALENDAR) FontWeight.Bold else FontWeight.Medium
                        ),
                        color = if (currentMode == ScheduleViewMode.DAY_CALENDAR) {
                            MaterialTheme.colorScheme.onPrimaryContainer
                        } else {
                            MaterialTheme.colorScheme.onSurfaceVariant
                        }
                    )
                }
            }
        }
    }
}

/**
 * Day-by-Day Calendar Timetable view with an interactive weekly day ribbon,
 * day metrics header, and chronological class timetable blocks with swipe-to-delete.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun AcademicScheduleDayCalendarView(
    events: List<AcademicScheduleEventEntity>,
    selectedDay: Int,
    onSelectDay: (Int) -> Unit,
    onToggleCompletion: (Long, Boolean) -> Unit,
    onToggleAlarm: (Long, Boolean) -> Unit,
    onEditEvent: (AcademicScheduleEventEntity) -> Unit,
    onDeleteEvent: (AcademicScheduleEventEntity) -> Unit,
    onDirectDelete: (AcademicScheduleEventEntity) -> Unit,
    onNavigateToVenue: ((venueName: String, locationCode: String?) -> Unit)?,
    onAddEventForDay: (Int) -> Unit
) {
    val dayTabs = listOf(
        1 to "Mon",
        2 to "Tue",
        3 to "Wed",
        4 to "Thu",
        5 to "Fri",
        6 to "Sat",
        7 to "Sun"
    )

    // Filter events for the selected day and sort chronologically by startTime
    val dayEvents = remember(events, selectedDay) {
        events.filter { it.dayOfWeek == selectedDay }
            .sortedBy { it.startTime }
    }

    val completedCount = dayEvents.count { it.isCompleted }
    val totalDayCount = dayEvents.size
    val completionProgress = if (totalDayCount > 0) completedCount.toFloat() / totalDayCount else 0f

    Column(
        modifier = Modifier
            .fillMaxSize()
            .testTag("day_calendar_view")
    ) {
        // Horizontal Day Selector Ribbon
        Surface(
            color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.35f),
            modifier = Modifier.fillMaxWidth()
        ) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .horizontalScroll(rememberScrollState())
                    .padding(horizontal = 12.dp, vertical = 10.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                dayTabs.forEach { (dayInt, label) ->
                    val isSelected = selectedDay == dayInt
                    val countForDay = events.count { it.dayOfWeek == dayInt }

                    Surface(
                        onClick = { onSelectDay(dayInt) },
                        modifier = Modifier
                            .width(64.dp)
                            .testTag("day_tab_$dayInt"),
                        shape = RoundedCornerShape(14.dp),
                        color = if (isSelected) {
                            MaterialTheme.colorScheme.primary
                        } else {
                            MaterialTheme.colorScheme.surface
                        },
                        shadowElevation = if (isSelected) 3.dp else 1.dp
                    ) {
                        Column(
                            modifier = Modifier.padding(vertical = 8.dp, horizontal = 4.dp),
                            horizontalAlignment = Alignment.CenterHorizontally,
                            verticalArrangement = Arrangement.Center
                        ) {
                            Text(
                                text = label,
                                style = MaterialTheme.typography.labelSmall.copy(
                                    fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Medium
                                ),
                                color = if (isSelected) {
                                    MaterialTheme.colorScheme.onPrimary
                                } else {
                                    MaterialTheme.colorScheme.onSurfaceVariant
                                }
                            )
                            Spacer(modifier = Modifier.height(4.dp))
                            Box(
                                modifier = Modifier
                                    .size(22.dp)
                                    .clip(CircleShape)
                                    .background(
                                        if (isSelected) {
                                            MaterialTheme.colorScheme.primaryContainer
                                        } else {
                                            MaterialTheme.colorScheme.surfaceVariant
                                        }
                                    ),
                                contentAlignment = Alignment.Center
                            ) {
                                Text(
                                    text = "$countForDay",
                                    style = MaterialTheme.typography.labelSmall.copy(
                                        fontWeight = FontWeight.Bold,
                                        fontSize = 11.sp
                                    ),
                                    color = if (isSelected) {
                                        MaterialTheme.colorScheme.onPrimaryContainer
                                    } else {
                                        MaterialTheme.colorScheme.onSurfaceVariant
                                    }
                                )
                            }
                        }
                    }
                }
            }
        }

        // Day Summary Banner
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 8.dp),
            shape = RoundedCornerShape(16.dp),
            colors = CardDefaults.cardColors(
                containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
            )
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(14.dp)
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column {
                        Text(
                            text = "${getDayName(selectedDay)}'s Timetable",
                            style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold)
                        )
                        Text(
                            text = if (totalDayCount == 0) "No classes scheduled" else "$totalDayCount classes scheduled • $completedCount completed",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }

                    if (totalDayCount > 0) {
                        Surface(
                            shape = RoundedCornerShape(8.dp),
                            color = if (completedCount == totalDayCount) {
                                MaterialTheme.colorScheme.primaryContainer
                            } else {
                                MaterialTheme.colorScheme.secondaryContainer
                            }
                        ) {
                            Text(
                                text = "${(completionProgress * 100).toInt()}% Done",
                                style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Bold),
                                modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                                color = if (completedCount == totalDayCount) {
                                    MaterialTheme.colorScheme.onPrimaryContainer
                                } else {
                                    MaterialTheme.colorScheme.onSecondaryContainer
                                }
                            )
                        }
                    }
                }

                if (totalDayCount > 0) {
                    Spacer(modifier = Modifier.height(10.dp))
                    LinearProgressIndicator(
                        progress = { completionProgress },
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(6.dp)
                            .clip(RoundedCornerShape(3.dp)),
                        color = MaterialTheme.colorScheme.primary,
                        trackColor = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.4f)
                    )
                }
            }
        }

        // Timeline Class Items or Empty Day State
        if (dayEvents.isEmpty()) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(32.dp),
                contentAlignment = Alignment.Center
            ) {
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.Center
                ) {
                    Box(
                        modifier = Modifier
                            .size(72.dp)
                            .clip(CircleShape)
                            .background(MaterialTheme.colorScheme.secondaryContainer.copy(alpha = 0.6f)),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            imageVector = Icons.Default.Today,
                            contentDescription = null,
                            modifier = Modifier.size(36.dp),
                            tint = MaterialTheme.colorScheme.secondary
                        )
                    }
                    Spacer(modifier = Modifier.height(16.dp))
                    Text(
                        text = "No classes on ${getDayName(selectedDay)}",
                        style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold)
                    )
                    Spacer(modifier = Modifier.height(6.dp))
                    Text(
                        text = "You have no scheduled lectures, labs, or exams on this day.",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        textAlign = androidx.compose.ui.text.style.TextAlign.Center
                    )
                    Spacer(modifier = Modifier.height(16.dp))
                    Button(
                        onClick = { onAddEventForDay(selectedDay) },
                        shape = RoundedCornerShape(12.dp)
                    ) {
                        Icon(imageVector = Icons.Default.Add, contentDescription = null)
                        Spacer(modifier = Modifier.width(6.dp))
                        Text("Add Class for ${getDayName(selectedDay)}")
                    }
                }
            }
        } else {
            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .testTag("day_calendar_list"),
                contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                items(
                    items = dayEvents,
                    key = { it.id }
                ) { event ->
                    val dismissState = rememberSwipeToDismissBoxState(
                        confirmValueChange = { dismissValue ->
                            if (dismissValue == SwipeToDismissBoxValue.EndToStart || dismissValue == SwipeToDismissBoxValue.StartToEnd) {
                                onDirectDelete(event)
                                true
                            } else {
                                false
                            }
                        }
                    )

                    SwipeToDismissBox(
                        state = dismissState,
                        enableDismissFromStartToEnd = true,
                        enableDismissFromEndToStart = true,
                        backgroundContent = {
                            val direction = dismissState.dismissDirection
                            val isStartToEnd = direction == SwipeToDismissBoxValue.StartToEnd
                            val alignment = if (isStartToEnd) Alignment.CenterStart else Alignment.CenterEnd

                            Box(
                                modifier = Modifier
                                    .fillMaxSize()
                                    .clip(RoundedCornerShape(16.dp))
                                    .background(MaterialTheme.colorScheme.errorContainer)
                                    .padding(horizontal = 20.dp),
                                contentAlignment = alignment
                            ) {
                                Row(
                                    verticalAlignment = Alignment.CenterVertically,
                                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                                ) {
                                    Icon(
                                        imageVector = Icons.Default.Delete,
                                        contentDescription = "Swipe to Delete",
                                        tint = MaterialTheme.colorScheme.onErrorContainer
                                    )
                                    Text(
                                        text = "Delete Class",
                                        style = MaterialTheme.typography.labelLarge.copy(
                                            fontWeight = FontWeight.Bold
                                        ),
                                        color = MaterialTheme.colorScheme.onErrorContainer
                                    )
                                }
                            }
                        },
                        modifier = Modifier
                            .fillMaxWidth()
                            .testTag("swipe_to_delete_calendar_box_${event.id}")
                    ) {
                        AcademicClassCard(
                            event = event,
                            onToggleCompletion = { isCompleted ->
                                onToggleCompletion(event.id, isCompleted)
                            },
                            onToggleAlarm = { isEnabled ->
                                onToggleAlarm(event.id, isEnabled)
                            },
                            onEditClick = { onEditEvent(event) },
                            onDeleteClick = { onDeleteEvent(event) },
                            onNavigateToVenue = onNavigateToVenue
                        )
                    }
                }

                item {
                    Spacer(modifier = Modifier.height(80.dp)) // Extra space for FAB clearance
                }
            }
        }
    }
}
