package com.example.ui.screens

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.*
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.R
import com.example.data.local.entity.CourseScheduleEntity
import com.example.data.local.entity.ExamScheduleEntity
import com.example.ui.MainViewModel
import com.example.ui.NavigationTab
import com.example.ui.UserRole
import com.example.ui.components.NextExamQuickViewCard
import com.example.ui.components.SmartAlarmComponent
import com.example.ui.components.StudentAlertNotificationComponent
import com.example.ui.theme.*

@Composable
fun DashboardScreen(
    viewModel: MainViewModel,
    modifier: Modifier = Modifier
) {
    val schedules by viewModel.allSchedules.collectAsState()
    val exams by viewModel.allExams.collectAsState()
    val alerts by viewModel.allAlerts.collectAsState()
    val gpaSummary by viewModel.gpaSummary.collectAsState()
    val locations by viewModel.allLocations.collectAsState()
    val librariesWithFloors by viewModel.librariesWithFloors.collectAsState()
    val currentRole by viewModel.currentRole.collectAsState()

    val unreadAlerts = alerts.count { !it.isRead }
    val urgentRelocations = schedules.filter { it.isCancelledOrMoved }
    val nextExam = exams.firstOrNull()
    val nextClass = schedules.firstOrNull()
    val totalAvailableDesks = librariesWithFloors.sumOf { it.library.availableSeats }
    val currentInstitution by viewModel.currentInstitution.collectAsState()
    val metricResult by viewModel.academicMetricResult.collectAsState()
    var showInstitutionDialog by remember { mutableStateOf(false) }

    LazyColumn(
        modifier = modifier
            .fillMaxSize()
            .background(HighDensityBg)
            .padding(horizontal = 16.dp),
        contentPadding = PaddingValues(bottom = 96.dp, top = 8.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp)
    ) {
        // Multi-Tenant Active University Context Bar
        item {
            Surface(
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable { showInstitutionDialog = true }
                    .testTag("dashboard_tenant_bar"),
                shape = RoundedCornerShape(16.dp),
                color = Color(currentInstitution.primaryColorHex).copy(alpha = 0.08f),
                border = androidx.compose.foundation.BorderStroke(
                    1.dp,
                    Color(currentInstitution.primaryColorHex).copy(alpha = 0.25f)
                )
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 14.dp, vertical = 10.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Row(
                        modifier = Modifier.weight(1f),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Surface(
                            shape = CircleShape,
                            color = Color(currentInstitution.primaryColorHex),
                            modifier = Modifier.size(32.dp)
                        ) {
                            Box(contentAlignment = Alignment.Center) {
                                Text(
                                    text = currentInstitution.shortCode.take(2),
                                    style = MaterialTheme.typography.labelMedium.copy(fontSize = 11.sp),
                                    fontWeight = FontWeight.Black,
                                    color = Color.White
                                )
                            }
                        }
                        Spacer(modifier = Modifier.width(10.dp))
                        Column {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Text(
                                    text = currentInstitution.shortCode,
                                    style = MaterialTheme.typography.titleSmall,
                                    fontWeight = FontWeight.Bold,
                                    color = MaterialTheme.colorScheme.onSurface
                                )
                                Spacer(modifier = Modifier.width(6.dp))
                                Text(
                                    text = "• ${currentInstitution.city}",
                                    style = MaterialTheme.typography.bodySmall,
                                    color = Slate600
                                )
                            }
                            Text(
                                text = "${currentInstitution.gradingMetricName} • ${metricResult.formattedScore}",
                                style = MaterialTheme.typography.labelSmall.copy(fontSize = 11.sp),
                                color = Color(currentInstitution.primaryColorHex),
                                fontWeight = FontWeight.SemiBold
                            )
                        }
                    }

                    Surface(
                        shape = RoundedCornerShape(8.dp),
                        color = Color(currentInstitution.primaryColorHex).copy(alpha = 0.12f)
                    ) {
                        Row(
                            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                text = "Switch",
                                style = MaterialTheme.typography.labelSmall,
                                fontWeight = FontWeight.Bold,
                                color = Color(currentInstitution.primaryColorHex)
                            )
                            Icon(
                                Icons.Filled.SwapHoriz,
                                contentDescription = null,
                                tint = Color(currentInstitution.primaryColorHex),
                                modifier = Modifier.size(14.dp)
                            )
                        }
                    }
                }
            }
        }
        // High Density: Next Class / Exam Highlight Hero
        item {
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .testTag("dashboard_hero_card"),
                shape = RoundedCornerShape(28.dp),
                colors = CardDefaults.cardColors(containerColor = HighDensityLavenderContainer),
                elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(18.dp),
                    verticalArrangement = Arrangement.SpaceBetween
                ) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.Top
                    ) {
                        Surface(
                            shape = RoundedCornerShape(100.dp),
                            color = HighDensityDeepPurple
                        ) {
                            Text(
                                text = if (nextClass != null) "NEXT CLASS" else "UPCOMING EVENT",
                                modifier = Modifier.padding(horizontal = 10.dp, vertical = 4.dp),
                                style = MaterialTheme.typography.labelSmall.copy(
                                    fontSize = 10.sp,
                                    fontWeight = FontWeight.Bold,
                                    letterSpacing = 0.8.sp
                                ),
                                color = Color.White
                            )
                        }
                        Column(horizontalAlignment = Alignment.End) {
                            Text(
                                text = nextClass?.let { "${it.startTime} — ${it.endTime}" } ?: "2:00 PM — 3:30 PM",
                                style = MaterialTheme.typography.labelSmall,
                                color = HighDensityDeepPurple.copy(alpha = 0.75f),
                                fontWeight = FontWeight.Medium
                            )
                            Text(
                                text = nextClass?.venue ?: "Hall KAB 1",
                                style = MaterialTheme.typography.bodySmall,
                                fontWeight = FontWeight.Bold,
                                color = HighDensityDeepPurple
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(14.dp))

                    Column {
                        Text(
                            text = nextClass?.courseTitle ?: "Software Engineering II",
                            style = MaterialTheme.typography.headlineSmall.copy(
                                fontSize = 22.sp,
                                fontWeight = FontWeight.ExtraBold,
                                lineHeight = 26.sp
                            ),
                            color = HighDensityDeepPurple
                        )
                        Spacer(modifier = Modifier.height(2.dp))
                        Text(
                            text = nextClass?.let { "${it.courseCode} • ${it.lecturer}" } ?: "CS 402 • Dr. Sarah Jenkins",
                            style = MaterialTheme.typography.bodyMedium,
                            color = HighDensityDeepPurple.copy(alpha = 0.82f)
                        )
                    }

                    Spacer(modifier = Modifier.height(14.dp))

                    HorizontalDivider(color = HighDensityDeepPurple.copy(alpha = 0.12f), thickness = 1.dp)

                    Spacer(modifier = Modifier.height(10.dp))

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(
                                imageVector = Icons.Filled.Schedule,
                                contentDescription = null,
                                tint = HighDensityDeepPurple,
                                modifier = Modifier.size(18.dp)
                            )
                            Spacer(modifier = Modifier.width(6.dp))
                            Text(
                                text = "Starts in 42 minutes",
                                style = MaterialTheme.typography.labelSmall,
                                fontWeight = FontWeight.SemiBold,
                                color = HighDensityDeepPurple
                            )
                        }

                        if (nextExam != null) {
                            Button(
                                onClick = {
                                    viewModel.triggerSimulatedAlarm(
                                        title = nextExam.courseCode + " Exam",
                                        venue = nextExam.venue,
                                        leaveTime = nextExam.suggestedLeaveTime
                                    )
                                },
                                colors = ButtonDefaults.buttonColors(
                                    containerColor = HighDensityDeepPurple,
                                    contentColor = Color.White
                                ),
                                contentPadding = PaddingValues(horizontal = 10.dp, vertical = 4.dp),
                                shape = RoundedCornerShape(12.dp),
                                modifier = Modifier.testTag("test_alarm_button")
                            ) {
                                Icon(Icons.Filled.Alarm, contentDescription = null, modifier = Modifier.size(14.dp))
                                Spacer(modifier = Modifier.width(4.dp))
                                Text("Test Alarm", style = MaterialTheme.typography.labelSmall)
                            }
                        }
                    }
                }
            }
        }

        // Student Life & Campus Companion Quick Hub
        item {
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .testTag("dashboard_student_hub_card"),
                shape = RoundedCornerShape(22.dp),
                colors = CardDefaults.cardColors(containerColor = Color.White),
                border = androidx.compose.foundation.BorderStroke(1.dp, Slate200),
                elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Column {
                            Text(
                                text = "STUDENT LIFE SERVICES",
                                style = MaterialTheme.typography.labelSmall.copy(
                                    fontSize = 10.sp,
                                    fontWeight = FontWeight.Bold,
                                    letterSpacing = 1.sp
                                ),
                                color = Color(currentInstitution.primaryColorHex)
                            )
                            Text(
                                text = "Ghana Campus Services Hub",
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.Bold,
                                color = HighDensityText
                            )
                        }

                        TextButton(
                            onClick = { viewModel.setSelectedTab(NavigationTab.STUDENT_HUB) }
                        ) {
                            Text("Open Hub", fontWeight = FontWeight.Bold, color = Color(currentInstitution.primaryColorHex))
                            Icon(Icons.AutoMirrored.Filled.ArrowForward, contentDescription = null, modifier = Modifier.size(16.dp), tint = Color(currentInstitution.primaryColorHex))
                        }
                    }

                    Spacer(modifier = Modifier.height(12.dp))

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(10.dp)
                    ) {
                        // Shuttles Pill
                        Surface(
                            modifier = Modifier
                                .weight(1f)
                                .clickable { viewModel.setSelectedTab(NavigationTab.STUDENT_HUB) },
                            shape = RoundedCornerShape(14.dp),
                            color = Color(0xFFF0FDF4),
                            border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFFBBF7D0))
                        ) {
                            Column(
                                modifier = Modifier.padding(12.dp),
                                horizontalAlignment = Alignment.Start
                            ) {
                                Icon(Icons.Filled.DirectionsBus, contentDescription = null, tint = Color(0xFF16A34A), modifier = Modifier.size(22.dp))
                                Spacer(modifier = Modifier.height(6.dp))
                                Text("Shuttles", style = MaterialTheme.typography.labelMedium, fontWeight = FontWeight.Bold, color = Color(0xFF166534))
                                Text("Live GPS & ETAs", style = MaterialTheme.typography.labelSmall.copy(fontSize = 10.sp), color = Color(0xFF15803D))
                            }
                        }

                        // MoMo Dues Pill
                        Surface(
                            modifier = Modifier
                                .weight(1f)
                                .clickable { viewModel.setSelectedTab(NavigationTab.STUDENT_HUB) },
                            shape = RoundedCornerShape(14.dp),
                            color = Color(0xFFFEF3C7),
                            border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFFFDE68A))
                        ) {
                            Column(
                                modifier = Modifier.padding(12.dp),
                                horizontalAlignment = Alignment.Start
                            ) {
                                Icon(Icons.Filled.Payments, contentDescription = null, tint = Color(0xFFD97706), modifier = Modifier.size(22.dp))
                                Spacer(modifier = Modifier.height(6.dp))
                                Text("MoMo Dues", style = MaterialTheme.typography.labelMedium, fontWeight = FontWeight.Bold, color = Color(0xFF92400E))
                                Text("Pay & Receipts", style = MaterialTheme.typography.labelSmall.copy(fontSize = 10.sp), color = Color(0xFFB45309))
                            }
                        }

                        // Lost & Found Pill
                        Surface(
                            modifier = Modifier
                                .weight(1f)
                                .clickable { viewModel.setSelectedTab(NavigationTab.STUDENT_HUB) },
                            shape = RoundedCornerShape(14.dp),
                            color = Color(0xFFEFF6FF),
                            border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFFBFDBFE))
                        ) {
                            Column(
                                modifier = Modifier.padding(12.dp),
                                horizontalAlignment = Alignment.Start
                            ) {
                                Icon(Icons.Filled.Search, contentDescription = null, tint = Color(0xFF2563EB), modifier = Modifier.size(22.dp))
                                Spacer(modifier = Modifier.height(6.dp))
                                Text("Lost/Found", style = MaterialTheme.typography.labelMedium, fontWeight = FontWeight.Bold, color = Color(0xFF1E40AF))
                                Text("Post & Claim", style = MaterialTheme.typography.labelSmall.copy(fontSize = 10.sp), color = Color(0xFF1D4ED8))
                            }
                        }
                    }
                }
            }
        }

        // High Density: Campus Assistant / Departure Smart Alert Section
        item {
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .testTag("smart_departure_card"),
                shape = RoundedCornerShape(18.dp),
                colors = CardDefaults.cardColors(containerColor = HighDensityRoseContainer),
                border = androidx.compose.foundation.BorderStroke(1.dp, HighDensityRoseBorder),
                elevation = CardDefaults.cardElevation(defaultElevation = 0.dp)
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(14.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Surface(
                        shape = RoundedCornerShape(12.dp),
                        color = HighDensityRoseIcon,
                        modifier = Modifier.size(42.dp)
                    ) {
                        Box(contentAlignment = Alignment.Center) {
                            Icon(
                                imageVector = Icons.Filled.SmartToy,
                                contentDescription = null,
                                tint = HighDensityRoseText,
                                modifier = Modifier.size(24.dp)
                            )
                        }
                    }

                    Spacer(modifier = Modifier.width(12.dp))

                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = "CAMPUS ASSISTANT",
                            style = MaterialTheme.typography.labelSmall.copy(
                                fontSize = 10.sp,
                                fontWeight = FontWeight.ExtraBold,
                                letterSpacing = 1.sp
                            ),
                            color = HighDensityRoseText
                        )
                        Spacer(modifier = Modifier.height(2.dp))
                        Text(
                            text = if (nextExam != null) {
                                "Walk to ${nextExam.venue} will take ~${nextExam.walkingTimeMinutes} mins. Leave by ${nextExam.suggestedLeaveTime} to arrive safely."
                            } else {
                                "Walk to KAB 1 will take 12 mins. Leave by 1:48 PM to arrive on time."
                            },
                            style = MaterialTheme.typography.bodySmall.copy(fontSize = 13.sp, lineHeight = 17.sp),
                            color = HighDensityRoseText
                        )
                    }

                    IconButton(
                        onClick = { viewModel.setSelectedTab(NavigationTab.AI_ASSISTANT) }
                    ) {
                        Icon(
                            imageVector = Icons.Filled.ChevronRight,
                            contentDescription = "Open Assistant",
                            tint = HighDensityRoseText
                        )
                    }
                }
            }
        }

        // Quick View Next Exam Countdown Card
        item {
            NextExamQuickViewCard(
                viewModel = viewModel,
                onNavigateToExams = { viewModel.setSelectedTab(NavigationTab.EXAMS) },
                onNavigateToVenue = { dest -> viewModel.planRouteTo(dest) }
            )
        }

        // Intelligent Smart Alarm (Room Schedule + Weather API)
        item {
            SmartAlarmComponent(
                viewModel = viewModel,
                onNavigateToTimetable = { viewModel.setSelectedTab(NavigationTab.TIMETABLE) }
            )
        }

        // Student Alert Notification Component (Worker-Backed Hub)
        item {
            StudentAlertNotificationComponent(
                viewModel = viewModel,
                onNavigateToVenue = { venueCode ->
                    val dest = locations.find { it.name.contains(venueCode, ignoreCase = true) || it.shortCode.contains(venueCode, ignoreCase = true) }
                    if (dest != null) viewModel.planRouteTo(dest)
                    else viewModel.setSelectedTab(NavigationTab.MAP_NAV)
                }
            )
        }

        // Campus Libraries Live Seat Availability Tracker Card
        item {
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable { viewModel.setSelectedTab(NavigationTab.RESOURCES) }
                    .testTag("dashboard_library_seats_card"),
                shape = RoundedCornerShape(22.dp),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                border = androidx.compose.foundation.BorderStroke(1.dp, MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.6f)),
                elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Row(
                        modifier = Modifier.weight(1f),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        Surface(
                            shape = RoundedCornerShape(14.dp),
                            color = HighDensityLavenderContainer
                        ) {
                            Box(
                                modifier = Modifier.size(44.dp),
                                contentAlignment = Alignment.Center
                            ) {
                                Icon(
                                    imageVector = Icons.Filled.LocalLibrary,
                                    contentDescription = null,
                                    tint = HighDensityDeepPurple,
                                    modifier = Modifier.size(24.dp)
                                )
                            }
                        }

                        Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.spacedBy(6.dp)
                            ) {
                                Text(
                                    text = "Campus Libraries",
                                    style = MaterialTheme.typography.titleSmall,
                                    fontWeight = FontWeight.Bold,
                                    color = MaterialTheme.colorScheme.onSurface
                                )
                                Surface(
                                    shape = RoundedCornerShape(6.dp),
                                    color = StatusGreen.copy(alpha = 0.15f)
                                ) {
                                    Text(
                                        text = "$totalAvailableDesks Desks Free",
                                        modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp),
                                        style = MaterialTheme.typography.labelSmall.copy(fontSize = 10.sp),
                                        fontWeight = FontWeight.Bold,
                                        color = StatusGreen
                                    )
                                }
                            }
                            Text(
                                text = "Balme, UGBS & Law • Floor maps & live seat sensors",
                                style = MaterialTheme.typography.bodySmall,
                                color = HighDensityMutedText,
                                maxLines = 1,
                                overflow = TextOverflow.Ellipsis
                            )
                        }
                    }

                    Icon(
                        imageVector = Icons.Filled.ChevronRight,
                        contentDescription = "View Libraries",
                        tint = HighDensityMutedText
                    )
                }
            }
        }

        // Urgent Venue Relocation Alert Banner (if any)
        if (urgentRelocations.isNotEmpty()) {
            item {
                urgentRelocations.forEach { movedClass ->
                    Card(
                        modifier = Modifier
                            .fillMaxWidth()
                            .testTag("urgent_relocation_card"),
                        shape = RoundedCornerShape(16.dp),
                        colors = CardDefaults.cardColors(containerColor = CampusRedContainer)
                    ) {
                        Row(
                            modifier = Modifier.padding(14.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(
                                imageVector = Icons.Filled.Warning,
                                contentDescription = null,
                                tint = CampusRed,
                                modifier = Modifier.size(28.dp)
                            )
                            Spacer(modifier = Modifier.width(12.dp))
                            Column(modifier = Modifier.weight(1f)) {
                                Text(
                                    text = "⚡ Class Moved: ${movedClass.courseCode}",
                                    style = MaterialTheme.typography.titleSmall,
                                    fontWeight = FontWeight.Bold,
                                    color = CampusRed
                                )
                                Text(
                                    text = movedClass.changeNote ?: "Relocated to ${movedClass.venue}",
                                    style = MaterialTheme.typography.bodySmall,
                                    color = Slate900
                                )
                            }
                            IconButton(
                                onClick = {
                                    val dest = locations.find { it.name.contains("Science") || it.shortCode == "SCI-3" }
                                    if (dest != null) viewModel.planRouteTo(dest)
                                }
                            ) {
                                Icon(Icons.Filled.Navigation, contentDescription = "Navigate", tint = CampusRed)
                            }
                        }
                    }
                }
            }
        }

        // High Density 2x2 Feature Navigation Grid
        item {
            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    // Card 1: Campus Map (Lavender)
                    Card(
                        modifier = Modifier
                            .weight(1f)
                            .height(104.dp)
                            .clickable { viewModel.setSelectedTab(NavigationTab.MAP_NAV) }
                            .testTag("feature_card_campus_map"),
                        shape = RoundedCornerShape(18.dp),
                        colors = CardDefaults.cardColors(containerColor = HighDensityLavenderMuted),
                        elevation = CardDefaults.cardElevation(defaultElevation = 0.dp)
                    ) {
                        Column(
                            modifier = Modifier
                                .fillMaxSize()
                                .padding(14.dp),
                            verticalArrangement = Arrangement.SpaceBetween
                        ) {
                            Icon(
                                imageVector = Icons.Filled.Map,
                                contentDescription = null,
                                tint = Color(0xFF1D192B),
                                modifier = Modifier.size(24.dp)
                            )
                            Column {
                                Text(
                                    text = "Campus Map",
                                    style = MaterialTheme.typography.titleSmall,
                                    fontWeight = FontWeight.Bold,
                                    color = Color(0xFF1D192B)
                                )
                                Text(
                                    text = "Find venues & labs",
                                    style = MaterialTheme.typography.labelSmall.copy(fontSize = 10.sp),
                                    color = Color(0xFF1D192B).copy(alpha = 0.7f),
                                    maxLines = 1
                                )
                            }
                        }
                    }

                    // Card 2: Academic Stats (Soft Blue)
                    Card(
                        modifier = Modifier
                            .weight(1f)
                            .height(104.dp)
                            .clickable { viewModel.setSelectedTab(NavigationTab.ANALYTICS) }
                            .testTag("feature_card_academic_stats"),
                        shape = RoundedCornerShape(18.dp),
                        colors = CardDefaults.cardColors(containerColor = HighDensityBlueContainer),
                        elevation = CardDefaults.cardElevation(defaultElevation = 0.dp)
                    ) {
                        Column(
                            modifier = Modifier
                                .fillMaxSize()
                                .padding(14.dp),
                            verticalArrangement = Arrangement.SpaceBetween
                        ) {
                            Icon(
                                imageVector = Icons.Filled.TrendingUp,
                                contentDescription = null,
                                tint = HighDensityBlueText,
                                modifier = Modifier.size(24.dp)
                            )
                            Column {
                                Text(
                                    text = "Academic Stats",
                                    style = MaterialTheme.typography.titleSmall,
                                    fontWeight = FontWeight.Bold,
                                    color = HighDensityBlueText
                                )
                                Text(
                                    text = "Current CGPA: ${String.format("%.2f", gpaSummary.cumulativeGpa)}",
                                    style = MaterialTheme.typography.labelSmall.copy(fontSize = 10.sp),
                                    color = HighDensityBlueText.copy(alpha = 0.75f),
                                    maxLines = 1
                                )
                            }
                        }
                    }
                }

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    // Card 3: Resources (White with Border)
                    Card(
                        modifier = Modifier
                            .weight(1f)
                            .height(104.dp)
                            .clickable { viewModel.setSelectedTab(NavigationTab.RESOURCES) }
                            .testTag("feature_card_resources"),
                        shape = RoundedCornerShape(18.dp),
                        colors = CardDefaults.cardColors(containerColor = Color.White),
                        border = androidx.compose.foundation.BorderStroke(1.dp, HighDensityBorder),
                        elevation = CardDefaults.cardElevation(defaultElevation = 0.dp)
                    ) {
                        Column(
                            modifier = Modifier
                                .fillMaxSize()
                                .padding(14.dp),
                            verticalArrangement = Arrangement.SpaceBetween
                        ) {
                            Icon(
                                imageVector = Icons.Filled.FolderOpen,
                                contentDescription = null,
                                tint = HighDensityMutedText,
                                modifier = Modifier.size(24.dp)
                            )
                            Column {
                                Text(
                                    text = "Resources",
                                    style = MaterialTheme.typography.titleSmall,
                                    fontWeight = FontWeight.Bold,
                                    color = HighDensityMutedText
                                )
                                Text(
                                    text = "Past questions & notes",
                                    style = MaterialTheme.typography.labelSmall.copy(fontSize = 10.sp),
                                    color = HighDensityMutedText.copy(alpha = 0.7f),
                                    maxLines = 1
                                )
                            }
                        }
                    }

                    // Card 4: Notices / Alerts (White with Border)
                    Card(
                        modifier = Modifier
                            .weight(1f)
                            .height(104.dp)
                            .clickable { viewModel.setSelectedTab(NavigationTab.ALERTS) }
                            .testTag("feature_card_notices"),
                        shape = RoundedCornerShape(18.dp),
                        colors = CardDefaults.cardColors(containerColor = Color.White),
                        border = androidx.compose.foundation.BorderStroke(1.dp, HighDensityBorder),
                        elevation = CardDefaults.cardElevation(defaultElevation = 0.dp)
                    ) {
                        Column(
                            modifier = Modifier
                                .fillMaxSize()
                                .padding(14.dp),
                            verticalArrangement = Arrangement.SpaceBetween
                        ) {
                            Icon(
                                imageVector = Icons.Filled.Campaign,
                                contentDescription = null,
                                tint = HighDensityMutedText,
                                modifier = Modifier.size(24.dp)
                            )
                            Column {
                                Text(
                                    text = "Notices",
                                    style = MaterialTheme.typography.titleSmall,
                                    fontWeight = FontWeight.Bold,
                                    color = HighDensityMutedText
                                )
                                Text(
                                    text = "$unreadAlerts new announcements",
                                    style = MaterialTheme.typography.labelSmall.copy(fontSize = 10.sp),
                                    color = HighDensityMutedText.copy(alpha = 0.7f),
                                    maxLines = 1
                                )
                            }
                        }
                    }
                }
            }
        }

        // Today's Lectures
        item {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Today's Academic Schedule",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = HighDensityText
                )
                TextButton(onClick = { viewModel.setSelectedTab(NavigationTab.TIMETABLE) }) {
                    Text("View Full Week", color = HighDensityPurplePrimary, fontWeight = FontWeight.Bold)
                }
            }
        }

        items(schedules.take(3)) { schedule ->
            ScheduleRowItem(
                schedule = schedule,
                onAlarmToggle = { viewModel.toggleScheduleAlarm(schedule) },
                onNavigate = {
                    val dest = locations.find { loc -> schedule.venue.contains(loc.shortCode, ignoreCase = true) }
                    if (dest != null) viewModel.planRouteTo(dest)
                    else viewModel.setSelectedTab(NavigationTab.MAP_NAV)
                }
            )
        }
    }

    if (showInstitutionDialog) {
        com.example.ui.components.InstitutionSelectorDialog(
            viewModel = viewModel,
            onDismiss = { showInstitutionDialog = false }
        )
    }
}

@Composable
fun ScheduleRowItem(
    schedule: CourseScheduleEntity,
    onAlarmToggle: () -> Unit,
    onNavigate: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .testTag("schedule_item_${schedule.courseCode}"),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(
            containerColor = if (schedule.isCancelledOrMoved) CampusRedContainer.copy(alpha = 0.5f) else MaterialTheme.colorScheme.surface
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(14.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Time Badge
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                modifier = Modifier.width(60.dp)
            ) {
                Text(
                    text = schedule.startTime,
                    style = MaterialTheme.typography.titleSmall,
                    fontWeight = FontWeight.Bold,
                    color = AcademicBlue
                )
                Text(
                    text = schedule.endTime,
                    style = MaterialTheme.typography.labelSmall,
                    color = Slate600
                )
            }

            Spacer(modifier = Modifier.width(12.dp))
            Divider(
                modifier = Modifier
                    .height(40.dp)
                    .width(2.dp),
                color = Color(schedule.colorHex)
            )
            Spacer(modifier = Modifier.width(12.dp))

            Column(modifier = Modifier.weight(1f)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        text = schedule.courseCode,
                        style = MaterialTheme.typography.titleSmall,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                    Spacer(modifier = Modifier.width(6.dp))
                    Surface(
                        shape = RoundedCornerShape(6.dp),
                        color = MaterialTheme.colorScheme.primaryContainer
                    ) {
                        Text(
                            text = "${schedule.creditHours} Credits",
                            style = MaterialTheme.typography.labelSmall,
                            modifier = Modifier.padding(horizontal = 5.dp, vertical = 1.dp),
                            color = MaterialTheme.colorScheme.onPrimaryContainer
                        )
                    }
                }
                Text(
                    text = schedule.courseTitle,
                    style = MaterialTheme.typography.bodySmall,
                    color = Slate600,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
                Text(
                    text = "📍 ${schedule.venue} • 👤 ${schedule.lecturer}",
                    style = MaterialTheme.typography.labelSmall,
                    color = if (schedule.isCancelledOrMoved) CampusRed else Slate700,
                    fontWeight = if (schedule.isCancelledOrMoved) FontWeight.Bold else FontWeight.Normal
                )
            }

            IconButton(onClick = onNavigate) {
                Icon(Icons.Outlined.Navigation, contentDescription = "Navigate to Venue", tint = AcademicBlue)
            }

            IconButton(onClick = onAlarmToggle) {
                Icon(
                    imageVector = if (schedule.isAlarmEnabled) Icons.Filled.NotificationsActive else Icons.Outlined.NotificationsOff,
                    contentDescription = "Toggle Alarm",
                    tint = if (schedule.isAlarmEnabled) AcademicGold else Slate600
                )
            }
        }
    }
}
