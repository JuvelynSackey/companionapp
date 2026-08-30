package com.example.ui.components

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
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.data.alarm.SmartAlarmCalculation
import com.example.data.alarm.SmartAlarmManager
import com.example.ui.MainViewModel
import com.example.ui.NavigationTab
import com.example.ui.theme.*

/**
 * Smart Alarm Component:
 * Automatically calculates wakeup times from the Room database schedule and live API weather data.
 */
@Composable
fun SmartAlarmComponent(
    viewModel: MainViewModel,
    modifier: Modifier = Modifier,
    onNavigateToTimetable: (() -> Unit)? = null
) {
    val context = LocalContext.current
    val smartAlarmCalc by viewModel.smartAlarmCalculation.collectAsState()
    val weather by viewModel.currentWeather.collectAsState()
    val isAlarmEnabled by viewModel.isSmartAlarmEnabled.collectAsState()
    val prepTime by viewModel.smartAlarmPrepMinutes.collectAsState()
    val transitTime by viewModel.smartAlarmTransitMinutes.collectAsState()
    val weatherAdjustmentEnabled by viewModel.smartAlarmWeatherAdjustmentEnabled.collectAsState()

    var showConfigDialog by remember { mutableStateOf(false) }
    var isAlarmTesting by remember { mutableStateOf(false) }

    Card(
        modifier = modifier
            .fillMaxWidth()
            .testTag("smart_alarm_card"),
        shape = RoundedCornerShape(22.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 3.dp),
        border = BorderStroke(1.dp, HighDensityBorder)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(18.dp)
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
                        color = if (isAlarmEnabled) HighDensityPurplePrimary else Slate400,
                        modifier = Modifier.size(38.dp)
                    ) {
                        Box(contentAlignment = Alignment.Center) {
                            Icon(
                                imageVector = if (isAlarmEnabled) Icons.Filled.AlarmOn else Icons.Filled.AlarmOff,
                                contentDescription = "Smart Alarm Icon",
                                tint = Color.White,
                                modifier = Modifier.size(22.dp)
                            )
                        }
                    }

                    Spacer(modifier = Modifier.width(10.dp))

                    Column {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Text(
                                text = "INTELLIGENT SMART ALARM",
                                style = MaterialTheme.typography.labelSmall.copy(
                                    fontSize = 11.sp,
                                    fontWeight = FontWeight.ExtraBold,
                                    letterSpacing = 0.8.sp
                                ),
                                color = HighDensityText
                            )
                            Spacer(modifier = Modifier.width(6.dp))
                            Surface(
                                shape = RoundedCornerShape(6.dp),
                                color = if (isAlarmEnabled) HighDensityLavenderContainer else Slate200
                            ) {
                                Text(
                                    text = if (isAlarmEnabled) "ACTIVE" else "MUTED",
                                    modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp),
                                    style = MaterialTheme.typography.labelSmall.copy(fontSize = 9.sp),
                                    color = if (isAlarmEnabled) HighDensityDeepPurple else Slate600,
                                    fontWeight = FontWeight.Bold
                                )
                            }
                        }
                        Text(
                            text = "Auto-synced with Room Timetable & Weather API",
                            style = MaterialTheme.typography.bodySmall.copy(fontSize = 11.sp),
                            color = Slate600
                        )
                    }
                }

                Switch(
                    checked = isAlarmEnabled,
                    onCheckedChange = { viewModel.toggleSmartAlarmEnabled(it) },
                    modifier = Modifier.testTag("toggle_smart_alarm_switch")
                )
            }

            Spacer(modifier = Modifier.height(14.dp))

            // Calculated Wakeup Display Hero
            Surface(
                shape = RoundedCornerShape(16.dp),
                color = if (isAlarmEnabled) HighDensityLavenderContainer.copy(alpha = 0.5f) else Slate100,
                border = BorderStroke(1.dp, if (isAlarmEnabled) HighDensityPurplePrimary.copy(alpha = 0.2f) else Slate200),
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(modifier = Modifier.padding(14.dp)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Column {
                            Text(
                                text = "CALCULATED WAKEUP TIME",
                                style = MaterialTheme.typography.labelSmall.copy(fontSize = 10.sp, fontWeight = FontWeight.Bold),
                                color = Slate600
                            )
                            Text(
                                text = if (isAlarmEnabled) smartAlarmCalc.calculatedWakeupTimeString else "Alarm Paused",
                                style = MaterialTheme.typography.headlineMedium.copy(fontSize = 28.sp, fontWeight = FontWeight.Black),
                                color = if (isAlarmEnabled) HighDensityText else Slate500
                            )
                        }

                        // Weather Badge
                        Surface(
                            shape = RoundedCornerShape(12.dp),
                            color = if (weather.isRaining) CampusRedContainer else HighDensityBlueContainer,
                            modifier = Modifier.clickable { viewModel.refreshCampusWeather() }
                        ) {
                            Row(
                                modifier = Modifier.padding(horizontal = 10.dp, vertical = 6.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Text(text = weather.weatherIconEmoji, fontSize = 16.sp)
                                Spacer(modifier = Modifier.width(6.dp))
                                Column {
                                    Text(
                                        text = "${weather.temperatureCelsius.toInt()}°C • ${weather.weatherCondition}",
                                        style = MaterialTheme.typography.labelSmall.copy(fontSize = 10.sp, fontWeight = FontWeight.Bold),
                                        color = if (weather.isRaining) CampusRed else HighDensityBlueText
                                    )
                                    if (weather.weatherDelayMinutes > 0) {
                                        Text(
                                            text = "+${weather.weatherDelayMinutes}m rain buffer",
                                            style = MaterialTheme.typography.labelSmall.copy(fontSize = 9.sp),
                                            color = CampusRed,
                                            fontWeight = FontWeight.Bold
                                        )
                                    }
                                }
                            }
                        }
                    }

                    Spacer(modifier = Modifier.height(10.dp))

                    // First Class Target Info
                    smartAlarmCalc.firstClass?.let { firstClass ->
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(Icons.Filled.School, contentDescription = null, tint = HighDensityDeepPurple, modifier = Modifier.size(16.dp))
                            Spacer(modifier = Modifier.width(6.dp))
                            Text(
                                text = "First Lecture: ",
                                style = MaterialTheme.typography.bodySmall.copy(fontSize = 11.sp, fontWeight = FontWeight.Bold),
                                color = HighDensityText
                            )
                            Text(
                                text = "${firstClass.courseCode} at ${firstClass.startTime} (${firstClass.venue})",
                                style = MaterialTheme.typography.bodySmall.copy(fontSize = 11.sp),
                                color = HighDensityDeepPurple,
                                fontWeight = FontWeight.SemiBold,
                                maxLines = 1,
                                overflow = TextOverflow.Ellipsis
                            )
                        }
                    } ?: run {
                        Text(
                            text = "No scheduled morning lecture detected for today.",
                            style = MaterialTheme.typography.bodySmall.copy(fontSize = 11.sp),
                            color = Slate600
                        )
                    }

                    Spacer(modifier = Modifier.height(8.dp))

                    // Formula Breakdown Badges
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(6.dp)
                    ) {
                        BufferPill(
                            label = "Prep: ${prepTime}m",
                            icon = Icons.Filled.SelfImprovement,
                            color = HighDensityDeepPurple
                        )
                        BufferPill(
                            label = "Walk: ${transitTime}m",
                            icon = Icons.Filled.DirectionsWalk,
                            color = AcademicBlue
                        )
                        if (weatherAdjustmentEnabled && weather.weatherDelayMinutes > 0) {
                            BufferPill(
                                label = "Weather: +${weather.weatherDelayMinutes}m",
                                icon = Icons.Filled.Thunderstorm,
                                color = CampusRed
                            )
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(10.dp))

            // Justification / Advisory Note
            Text(
                text = smartAlarmCalc.justificationMessage,
                style = MaterialTheme.typography.bodySmall.copy(fontSize = 11.sp, lineHeight = 15.sp),
                color = Slate600
            )

            Spacer(modifier = Modifier.height(12.dp))

            // Action Buttons
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                OutlinedButton(
                    onClick = {
                        isAlarmTesting = true
                        SmartAlarmManager.testAlarmToneAndHaptics(context)
                    },
                    modifier = Modifier
                        .weight(1f)
                        .testTag("btn_test_alarm_sound"),
                    shape = RoundedCornerShape(12.dp),
                    contentPadding = PaddingValues(horizontal = 8.dp, vertical = 6.dp)
                ) {
                    Icon(
                        imageVector = if (isAlarmTesting) Icons.Filled.VolumeUp else Icons.Filled.PlayArrow,
                        contentDescription = null,
                        modifier = Modifier.size(16.dp),
                        tint = HighDensityPurplePrimary
                    )
                    Spacer(modifier = Modifier.width(6.dp))
                    Text(
                        text = if (isAlarmTesting) "Testing Chime..." else "Test Audio & Haptic",
                        style = MaterialTheme.typography.labelSmall,
                        color = HighDensityPurplePrimary
                    )
                }

                Button(
                    onClick = { showConfigDialog = true },
                    modifier = Modifier
                        .weight(1f)
                        .testTag("btn_customize_smart_alarm"),
                    shape = RoundedCornerShape(12.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = HighDensityDeepPurple),
                    contentPadding = PaddingValues(horizontal = 8.dp, vertical = 6.dp)
                ) {
                    Icon(Icons.Filled.Tune, contentDescription = null, modifier = Modifier.size(16.dp))
                    Spacer(modifier = Modifier.width(6.dp))
                    Text("Configure", style = MaterialTheme.typography.labelSmall)
                }
            }
        }
    }

    // Smart Alarm Configuration Dialog
    if (showConfigDialog) {
        var tempPrep by remember { mutableStateOf(prepTime.toFloat()) }
        var tempTransit by remember { mutableStateOf(transitTime.toFloat()) }
        var tempWeatherAdj by remember { mutableStateOf(weatherAdjustmentEnabled) }

        AlertDialog(
            onDismissRequest = { showConfigDialog = false },
            title = {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Filled.Alarm, contentDescription = null, tint = HighDensityPurplePrimary)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Smart Alarm Preferences")
                }
            },
            text = {
                Column(
                    modifier = Modifier.fillMaxWidth(),
                    verticalArrangement = Arrangement.spacedBy(14.dp)
                ) {
                    Text(
                        text = "Customize how your wakeup time is calculated from your Room timetable and weather condition APIs.",
                        style = MaterialTheme.typography.bodySmall,
                        color = Slate600
                    )

                    // Prep Time Slider
                    Column {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            Text("Morning Preparation Time:", style = MaterialTheme.typography.bodySmall, fontWeight = FontWeight.Bold)
                            Text("${tempPrep.toInt()} mins", style = MaterialTheme.typography.bodySmall, color = HighDensityPurplePrimary, fontWeight = FontWeight.Bold)
                        }
                        Slider(
                            value = tempPrep,
                            onValueChange = { tempPrep = it },
                            valueRange = 15f..90f,
                            steps = 14
                        )
                    }

                    // Transit Time Slider
                    Column {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            Text("Campus Walk / Transit Time:", style = MaterialTheme.typography.bodySmall, fontWeight = FontWeight.Bold)
                            Text("${tempTransit.toInt()} mins", style = MaterialTheme.typography.bodySmall, color = HighDensityPurplePrimary, fontWeight = FontWeight.Bold)
                        }
                        Slider(
                            value = tempTransit,
                            onValueChange = { tempTransit = it },
                            valueRange = 5f..60f,
                            steps = 10
                        )
                    }

                    // Weather Adjustment Switch
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Column(modifier = Modifier.weight(1f)) {
                            Text("Weather API Auto-Adjustment", style = MaterialTheme.typography.bodySmall, fontWeight = FontWeight.Bold)
                            Text(
                                text = "Automatically advances wakeup by +15–30 min when rain, storms, or severe weather are detected on campus.",
                                style = MaterialTheme.typography.labelSmall.copy(fontSize = 10.sp),
                                color = Slate600
                            )
                        }
                        Switch(
                            checked = tempWeatherAdj,
                            onCheckedChange = { tempWeatherAdj = it }
                        )
                    }
                }
            },
            confirmButton = {
                Button(
                    onClick = {
                        viewModel.updateSmartAlarmSettings(
                            prepMinutes = tempPrep.toInt(),
                            transitMinutes = tempTransit.toInt(),
                            weatherAdjustmentEnabled = tempWeatherAdj
                        )
                        showConfigDialog = false
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = HighDensityDeepPurple)
                ) {
                    Text("Save Settings")
                }
            },
            dismissButton = {
                TextButton(onClick = { showConfigDialog = false }) {
                    Text("Cancel")
                }
            }
        )
    }
}

@Composable
private fun BufferPill(
    label: String,
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    color: Color
) {
    Surface(
        shape = RoundedCornerShape(8.dp),
        color = color.copy(alpha = 0.12f),
        border = BorderStroke(1.dp, color.copy(alpha = 0.25f))
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 6.dp, vertical = 3.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(icon, contentDescription = null, tint = color, modifier = Modifier.size(12.dp))
            Spacer(modifier = Modifier.width(4.dp))
            Text(
                text = label,
                style = MaterialTheme.typography.labelSmall.copy(fontSize = 10.sp, fontWeight = FontWeight.Bold),
                color = color
            )
        }
    }
}
