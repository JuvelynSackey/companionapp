package com.example.ui.components

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.expandVertically
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.shrinkVertically
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
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
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.ContextCompat
import com.example.data.local.entity.CampusAlertEntity
import com.example.ui.MainViewModel
import com.example.ui.NavigationTab
import com.example.ui.UserRole
import com.example.ui.theme.*
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Student Alert Notification Component:
 * Displays active campus-wide announcements and background worker sync notifications.
 * Allows students and class representatives to receive, manage, filter, and trigger
 * background worker announcement checks.
 */
@Composable
fun StudentAlertNotificationComponent(
    viewModel: MainViewModel,
    modifier: Modifier = Modifier,
    onNavigateToVenue: ((String) -> Unit)? = null
) {
    val context = LocalContext.current
    val alerts by viewModel.allAlerts.collectAsState()
    val currentRole by viewModel.currentRole.collectAsState()
    val unreadCount = remember(alerts) { alerts.count { !it.isRead } }
    val urgentRelocations = remember(alerts) { alerts.filter { it.category == "VENUE_CHANGE" && !it.isRead } }

    var selectedFilter by remember { mutableStateOf("ALL") }
    var isExpanded by remember { mutableStateOf(true) }
    var hasNotificationPermission by remember {
        mutableStateOf(
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                ContextCompat.checkSelfPermission(
                    context,
                    Manifest.permission.POST_NOTIFICATIONS
                ) == PackageManager.PERMISSION_GRANTED
            } else {
                true
            }
        )
    }

    val permissionLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.RequestPermission()
    ) { isGranted ->
        hasNotificationPermission = isGranted
    }

    val filteredAlerts = remember(alerts, selectedFilter) {
        when (selectedFilter) {
            "ALL" -> alerts
            "UNREAD" -> alerts.filter { !it.isRead }
            "VENUE_CHANGE" -> alerts.filter { it.category == "VENUE_CHANGE" }
            "EXAM_ALERT" -> alerts.filter { it.category == "EXAM_ALERT" }
            "ACADEMIC" -> alerts.filter { it.category == "ACADEMIC" }
            else -> alerts
        }
    }

    Card(
        modifier = modifier
            .fillMaxWidth()
            .testTag("student_alert_notification_component"),
        shape = RoundedCornerShape(22.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
        border = BorderStroke(1.dp, HighDensityBorder)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
        ) {
            // Header Bar
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Surface(
                        shape = CircleShape,
                        color = if (unreadCount > 0) CampusRed else HighDensityDeepPurple,
                        modifier = Modifier.size(36.dp)
                    ) {
                        Box(contentAlignment = Alignment.Center) {
                            Icon(
                                imageVector = if (unreadCount > 0) Icons.Filled.NotificationsActive else Icons.Filled.Campaign,
                                contentDescription = "Alerts",
                                tint = Color.White,
                                modifier = Modifier.size(20.dp)
                            )
                        }
                    }

                    Spacer(modifier = Modifier.width(10.dp))

                    Column {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Text(
                                text = "STUDENT ALERTS & NOTICES",
                                style = MaterialTheme.typography.labelSmall.copy(
                                    fontSize = 11.sp,
                                    fontWeight = FontWeight.ExtraBold,
                                    letterSpacing = 0.8.sp
                                ),
                                color = HighDensityText
                            )
                            if (unreadCount > 0) {
                                Spacer(modifier = Modifier.width(6.dp))
                                Surface(
                                    shape = RoundedCornerShape(10.dp),
                                    color = CampusRed
                                ) {
                                    Text(
                                        text = "$unreadCount NEW",
                                        modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp),
                                        style = MaterialTheme.typography.labelSmall.copy(fontSize = 9.sp),
                                        color = Color.White,
                                        fontWeight = FontWeight.Bold
                                    )
                                }
                            }
                        }
                        Text(
                            text = "Background Worker Synced • Push Notifications Active",
                            style = MaterialTheme.typography.bodySmall.copy(fontSize = 11.sp),
                            color = Slate600
                        )
                    }
                }

                IconButton(
                    onClick = { isExpanded = !isExpanded },
                    modifier = Modifier.testTag("toggle_alerts_expansion")
                ) {
                    Icon(
                        imageVector = if (isExpanded) Icons.Filled.ExpandLess else Icons.Filled.ExpandMore,
                        contentDescription = if (isExpanded) "Collapse" else "Expand",
                        tint = HighDensityText
                    )
                }
            }

            // Notification Permission Banner (If missing on Android 13+)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU && !hasNotificationPermission) {
                Spacer(modifier = Modifier.height(10.dp))
                Surface(
                    shape = RoundedCornerShape(12.dp),
                    color = AcademicGold.copy(alpha = 0.12f),
                    border = BorderStroke(1.dp, AcademicGold.copy(alpha = 0.4f)),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Row(
                        modifier = Modifier.padding(10.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Row(modifier = Modifier.weight(1f), verticalAlignment = Alignment.CenterVertically) {
                            Icon(Icons.Filled.NotificationsOff, contentDescription = null, tint = AcademicGold, modifier = Modifier.size(20.dp))
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(
                                text = "Enable system notifications to receive instant venue change alarms.",
                                style = MaterialTheme.typography.bodySmall.copy(fontSize = 11.sp),
                                color = HighDensityText
                            )
                        }
                        Button(
                            onClick = { permissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS) },
                            colors = ButtonDefaults.buttonColors(containerColor = AcademicGold),
                            contentPadding = PaddingValues(horizontal = 10.dp, vertical = 4.dp),
                            shape = RoundedCornerShape(8.dp)
                        ) {
                            Text("Enable", style = MaterialTheme.typography.labelSmall)
                        }
                    }
                }
            }

            AnimatedVisibility(
                visible = isExpanded,
                enter = fadeIn() + expandVertically(),
                exit = fadeOut() + shrinkVertically()
            ) {
                Column(modifier = Modifier.padding(top = 12.dp)) {
                    // Quick Action Tools: Background Worker Sync & Broadcast
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        OutlinedButton(
                            onClick = { viewModel.triggerBackgroundWorkerAlertCheck() },
                            modifier = Modifier
                                .weight(1f)
                                .testTag("btn_trigger_worker_sync"),
                            shape = RoundedCornerShape(12.dp),
                            contentPadding = PaddingValues(horizontal = 8.dp, vertical = 8.dp)
                        ) {
                            Icon(Icons.Filled.Sync, contentDescription = null, modifier = Modifier.size(16.dp), tint = HighDensityPurplePrimary)
                            Spacer(modifier = Modifier.width(6.dp))
                            Text("Worker Sync", style = MaterialTheme.typography.labelSmall, color = HighDensityPurplePrimary)
                        }

                        if (currentRole == UserRole.CLASS_REPRESENTATIVE || currentRole == UserRole.ADMINISTRATOR) {
                            Button(
                                onClick = { viewModel.setSelectedTab(NavigationTab.ALERTS) },
                                modifier = Modifier
                                    .weight(1f)
                                    .testTag("btn_compose_broadcast"),
                                shape = RoundedCornerShape(12.dp),
                                colors = ButtonDefaults.buttonColors(containerColor = CampusRed),
                                contentPadding = PaddingValues(horizontal = 8.dp, vertical = 8.dp)
                            ) {
                                Icon(Icons.Filled.Campaign, contentDescription = null, modifier = Modifier.size(16.dp))
                                Spacer(modifier = Modifier.width(6.dp))
                                Text("Broadcast", style = MaterialTheme.typography.labelSmall)
                            }
                        }
                    }

                    Spacer(modifier = Modifier.height(10.dp))

                    // Category Chips
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(6.dp)
                    ) {
                        val filters = listOf("ALL" to "All", "UNREAD" to "Unread ($unreadCount)", "VENUE_CHANGE" to "Venues", "EXAM_ALERT" to "Exams")
                        filters.forEach { (key, label) ->
                            val isSelected = selectedFilter == key
                            FilterChip(
                                selected = isSelected,
                                onClick = { selectedFilter = key },
                                label = { Text(label, style = MaterialTheme.typography.labelSmall.copy(fontSize = 10.sp)) },
                                shape = RoundedCornerShape(100.dp),
                                colors = FilterChipDefaults.filterChipColors(
                                    selectedContainerColor = HighDensityLavenderContainer,
                                    selectedLabelColor = HighDensityDeepPurple
                                )
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(8.dp))

                    // Alert Items Feed
                    if (filteredAlerts.isEmpty()) {
                        Box(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(vertical = 16.dp),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                text = "No notifications match this category.",
                                style = MaterialTheme.typography.bodySmall,
                                color = Slate600
                            )
                        }
                    } else {
                        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                            filteredAlerts.take(4).forEach { alert ->
                                AlertNotificationFeedItem(
                                    alert = alert,
                                    onMarkRead = { viewModel.markAlertAsRead(alert.id) },
                                    onNavigateToVenue = onNavigateToVenue
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun AlertNotificationFeedItem(
    alert: CampusAlertEntity,
    onMarkRead: () -> Unit,
    onNavigateToVenue: ((String) -> Unit)? = null
) {
    val dateStr = remember(alert.timestamp) {
        val sdf = SimpleDateFormat("h:mm a", Locale.getDefault())
        sdf.format(Date(alert.timestamp))
    }

    val (badgeBg, badgeColor, categoryIcon) = when (alert.category) {
        "VENUE_CHANGE" -> Triple(CampusRedContainer, CampusRed, Icons.Filled.DirectionsWalk)
        "EXAM_ALERT" -> Triple(AcademicGold.copy(alpha = 0.15f), AcademicGold, Icons.Filled.Assignment)
        "EMERGENCY" -> Triple(CampusRedContainer, CampusRed, Icons.Filled.Warning)
        "ACADEMIC" -> Triple(HighDensityBlueContainer, HighDensityBlueText, Icons.Filled.School)
        else -> Triple(HighDensityLavenderContainer, HighDensityDeepPurple, Icons.Filled.Campaign)
    }

    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { onMarkRead() }
            .testTag("notification_feed_item_${alert.id}"),
        shape = RoundedCornerShape(14.dp),
        color = if (!alert.isRead) badgeBg.copy(alpha = 0.45f) else Color.White,
        border = BorderStroke(1.dp, if (!alert.isRead) badgeColor.copy(alpha = 0.35f) else HighDensityBorder)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            verticalAlignment = Alignment.Top
        ) {
            Surface(
                shape = RoundedCornerShape(10.dp),
                color = badgeBg,
                modifier = Modifier.size(34.dp)
            ) {
                Box(contentAlignment = Alignment.Center) {
                    Icon(
                        imageVector = categoryIcon,
                        contentDescription = null,
                        tint = badgeColor,
                        modifier = Modifier.size(18.dp)
                    )
                }
            }

            Spacer(modifier = Modifier.width(10.dp))

            Column(modifier = Modifier.weight(1f)) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = alert.title,
                        style = MaterialTheme.typography.titleSmall.copy(fontSize = 13.sp),
                        fontWeight = if (!alert.isRead) FontWeight.Bold else FontWeight.SemiBold,
                        color = HighDensityText,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                        modifier = Modifier.weight(1f)
                    )
                    Spacer(modifier = Modifier.width(6.dp))
                    Text(
                        text = dateStr,
                        style = MaterialTheme.typography.labelSmall.copy(fontSize = 10.sp),
                        color = Slate600
                    )
                }

                Spacer(modifier = Modifier.height(3.dp))

                Text(
                    text = alert.message,
                    style = MaterialTheme.typography.bodySmall.copy(fontSize = 11.sp, lineHeight = 15.sp),
                    color = Slate700,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis
                )

                Spacer(modifier = Modifier.height(6.dp))

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "Source: ${alert.author}",
                        style = MaterialTheme.typography.labelSmall.copy(fontSize = 9.sp),
                        color = Slate600
                    )

                    if (!alert.isRead) {
                        Text(
                            text = "Tap to mark read",
                            style = MaterialTheme.typography.labelSmall.copy(fontSize = 9.sp),
                            color = HighDensityPurplePrimary,
                            fontWeight = FontWeight.Bold
                        )
                    }
                }
            }
        }
    }
}
