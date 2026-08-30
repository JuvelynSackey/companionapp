package com.example.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
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
import com.example.data.local.entity.CampusAlertEntity
import com.example.ui.MainViewModel
import com.example.ui.UserRole
import com.example.ui.components.StudentAlertNotificationComponent
import com.example.ui.theme.*
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AlertsScreen(
    viewModel: MainViewModel,
    modifier: Modifier = Modifier
) {
    val alerts by viewModel.allAlerts.collectAsState()
    val currentRole by viewModel.currentRole.collectAsState()

    var showBroadcastDialog by remember { mutableStateOf(false) }

    Scaffold(
        modifier = modifier.fillMaxSize(),
        floatingActionButton = {
            if (currentRole == UserRole.CLASS_REPRESENTATIVE || currentRole == UserRole.ADMINISTRATOR) {
                ExtendedFloatingActionButton(
                    onClick = { showBroadcastDialog = true },
                    containerColor = CampusRed,
                    contentColor = Color.White,
                    icon = { Icon(Icons.Filled.Campaign, contentDescription = null) },
                    text = { Text("Broadcast Alert") },
                    modifier = Modifier.testTag("broadcast_alert_fab")
                )
            }
        }
    ) { padding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(horizontal = 16.dp),
            contentPadding = PaddingValues(top = 8.dp, bottom = 96.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp)
        ) {
            // Header
            item {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column {
                        Text(
                            text = "Campus Alerts & Broadcasts",
                            style = MaterialTheme.typography.headlineSmall,
                            fontWeight = FontWeight.Bold,
                            color = MaterialTheme.colorScheme.onSurface
                        )
                        Text(
                            text = "Instant class venue changes, exam notices & student alerts",
                            style = MaterialTheme.typography.bodySmall,
                            color = Slate600
                        )
                    }
                }
            }

            // Background Worker Notification Hub Component
            item {
                StudentAlertNotificationComponent(
                    viewModel = viewModel
                )
            }

            // Alerts List
            items(alerts) { alert ->
                CampusAlertCard(
                    alert = alert,
                    onMarkRead = { viewModel.markAlertAsRead(alert.id) }
                )
            }
        }
    }

    // Broadcast Notice Composer Dialog (Rep & Admin)
    if (showBroadcastDialog) {
        var title by remember { mutableStateOf("") }
        var message by remember { mutableStateOf("") }
        var category by remember { mutableStateOf("VENUE_CHANGE") }
        var courseCode by remember { mutableStateOf("CSCD 302") }

        val categoryOptions = listOf(
            "VENUE_CHANGE" to "Venue Relocation",
            "EXAM_ALERT" to "Exam Announcement",
            "ACADEMIC" to "Academic Affairs",
            "CAMPUS_NEWS" to "General Campus Bulletin"
        )

        AlertDialog(
            onDismissRequest = { showBroadcastDialog = false },
            title = {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Filled.Campaign, contentDescription = null, tint = CampusRed)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Broadcast Campus Alert")
                }
            },
            text = {
                Column(
                    modifier = Modifier.fillMaxWidth(),
                    verticalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    Text(
                        text = "This alert will be instantly pushed to all registered student devices and pinned to dashboards.",
                        style = MaterialTheme.typography.bodySmall,
                        color = Slate600
                    )

                    OutlinedTextField(
                        value = title,
                        onValueChange = { title = it },
                        label = { Text("Alert Headline / Title") },
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth()
                    )

                    OutlinedTextField(
                        value = courseCode,
                        onValueChange = { courseCode = it },
                        label = { Text("Affected Course Code (Optional)") },
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth()
                    )

                    OutlinedTextField(
                        value = message,
                        onValueChange = { message = it },
                        label = { Text("Detailed Alert Message / Instructions") },
                        maxLines = 4,
                        modifier = Modifier.fillMaxWidth()
                    )
                }
            },
            confirmButton = {
                Button(
                    onClick = {
                        if (title.isNotBlank() && message.isNotBlank()) {
                            viewModel.broadcastAlert(
                                title = title,
                                message = message,
                                category = category,
                                courseCode = courseCode
                            )
                            showBroadcastDialog = false
                        }
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = CampusRed)
                ) {
                    Text("Send Broadcast")
                }
            },
            dismissButton = {
                TextButton(onClick = { showBroadcastDialog = false }) {
                    Text("Cancel")
                }
            }
        )
    }
}

@Composable
fun CampusAlertCard(
    alert: CampusAlertEntity,
    onMarkRead: () -> Unit
) {
    val dateStr = remember(alert.timestamp) {
        val sdf = SimpleDateFormat("MMM d, h:mm a", Locale.getDefault())
        sdf.format(Date(alert.timestamp))
    }

    val categoryColor = when (alert.category) {
        "VENUE_CHANGE" -> CampusRed
        "EXAM_ALERT" -> AcademicGold
        "ACADEMIC" -> AcademicBlue
        else -> CampusGreen
    }

    Card(
        modifier = Modifier
            .fillMaxWidth()
            .testTag("alert_card_${alert.id}"),
        shape = RoundedCornerShape(18.dp),
        colors = CardDefaults.cardColors(
            containerColor = if (!alert.isRead) categoryColor.copy(alpha = 0.08f) else MaterialTheme.colorScheme.surface
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            // Top Row
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Surface(
                        shape = RoundedCornerShape(6.dp),
                        color = categoryColor.copy(alpha = 0.15f)
                    ) {
                        Text(
                            text = when (alert.category) {
                                "VENUE_CHANGE" -> "⚡ VENUE RELOCATION"
                                "EXAM_ALERT" -> "📅 EXAM ALERT"
                                "ACADEMIC" -> "📚 ACADEMIC"
                                else -> "📢 BULLETIN"
                            },
                            modifier = Modifier.padding(horizontal = 8.dp, vertical = 3.dp),
                            style = MaterialTheme.typography.labelSmall,
                            fontWeight = FontWeight.Bold,
                            color = categoryColor
                        )
                    }

                    if (alert.isPinned) {
                        Spacer(modifier = Modifier.width(6.dp))
                        Icon(Icons.Filled.PushPin, contentDescription = "Pinned", tint = CampusRed, modifier = Modifier.size(16.dp))
                    }
                }

                Text(
                    text = dateStr,
                    style = MaterialTheme.typography.labelSmall,
                    color = Slate600
                )
            }

            Spacer(modifier = Modifier.height(8.dp))

            Text(
                text = alert.title,
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onSurface
            )

            Spacer(modifier = Modifier.height(6.dp))

            Text(
                text = alert.message,
                style = MaterialTheme.typography.bodyMedium,
                color = Slate800,
                lineHeight = 20.sp
            )

            Spacer(modifier = Modifier.height(10.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Filled.VerifiedUser, contentDescription = null, tint = AcademicBlue, modifier = Modifier.size(14.dp))
                    Spacer(modifier = Modifier.width(4.dp))
                    Text(
                        text = "Source: ${alert.author}",
                        style = MaterialTheme.typography.labelSmall,
                        color = Slate600,
                        fontWeight = FontWeight.Medium
                    )
                }

                if (!alert.isRead) {
                    TextButton(onClick = onMarkRead) {
                        Text("Mark Read", style = MaterialTheme.typography.labelSmall, color = AcademicBlue)
                    }
                }
            }
        }
    }
}
