package com.example.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
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
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.data.local.entity.GpaCourseEntity
import com.example.ui.MainViewModel
import com.example.ui.components.CourseGradeTrackerComponent
import com.example.ui.theme.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AnalyticsScreen(
    viewModel: MainViewModel,
    modifier: Modifier = Modifier
) {
    val gpaSummary by viewModel.gpaSummary.collectAsState()
    val allCourses by viewModel.allGpaCourses.collectAsState()
    val courseSummaries by viewModel.courseWeightedSummaries.collectAsState()
    val currentInstitution by viewModel.currentInstitution.collectAsState()
    val metricResult by viewModel.academicMetricResult.collectAsState()

    var showAddCourseDialog by remember { mutableStateOf(false) }
    var showInstitutionDialog by remember { mutableStateOf(false) }

    // Count letter grades for distribution bar
    val gradeCounts = remember(courseSummaries) {
        val map = mutableMapOf("A" to 0, "B+" to 0, "B" to 0, "C+" to 0, "C" to 0, "Other" to 0)
        courseSummaries.forEach { summary ->
            when (summary.letterGrade) {
                "A" -> map["A"] = (map["A"] ?: 0) + 1
                "B+" -> map["B+"] = (map["B+"] ?: 0) + 1
                "B" -> map["B"] = (map["B"] ?: 0) + 1
                "C+" -> map["C+"] = (map["C+"] ?: 0) + 1
                "C" -> map["C"] = (map["C"] ?: 0) + 1
                else -> map["Other"] = (map["Other"] ?: 0) + 1
            }
        }
        map
    }

    Scaffold(
        modifier = modifier.fillMaxSize(),
        floatingActionButton = {
            ExtendedFloatingActionButton(
                onClick = { showAddCourseDialog = true },
                containerColor = Color(currentInstitution.primaryColorHex),
                contentColor = Color.White,
                icon = { Icon(Icons.Filled.Add, contentDescription = null) },
                text = { Text("Add Course Grade") },
                modifier = Modifier.testTag("add_gpa_grade_fab")
            )
        }
    ) { padding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(horizontal = 16.dp),
            contentPadding = PaddingValues(top = 8.dp, bottom = 96.dp),
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
                        Text(
                            text = "${currentInstitution.shortCode} Academic Analytics",
                            style = MaterialTheme.typography.headlineSmall,
                            fontWeight = FontWeight.Bold,
                            color = MaterialTheme.colorScheme.onSurface
                        )
                        Text(
                            text = "Grading Engine: ${currentInstitution.gradingMetricName}",
                            style = MaterialTheme.typography.bodySmall,
                            color = Color(currentInstitution.primaryColorHex),
                            fontWeight = FontWeight.SemiBold
                        )
                    }

                    AssistChip(
                        onClick = { showInstitutionDialog = true },
                        label = { Text(currentInstitution.shortCode, fontWeight = FontWeight.Bold) },
                        leadingIcon = { Icon(Icons.Filled.School, contentDescription = null, modifier = Modifier.size(16.dp)) },
                        colors = AssistChipDefaults.assistChipColors(
                            containerColor = Color(currentInstitution.primaryColorHex).copy(alpha = 0.12f),
                            labelColor = Color(currentInstitution.primaryColorHex)
                        )
                    )
                }
            }

            // Metric Scorecard (GPA or CWA)
            item {
                Card(
                    modifier = Modifier
                        .fillMaxWidth()
                        .testTag("cgpa_scorecard"),
                    shape = RoundedCornerShape(24.dp),
                    colors = CardDefaults.cardColors(containerColor = Color(currentInstitution.primaryColorHex)),
                    elevation = CardDefaults.cardElevation(defaultElevation = 3.dp)
                ) {
                    Column(
                        modifier = Modifier.padding(22.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Text(
                            text = metricResult.metricLabel.uppercase(),
                            style = MaterialTheme.typography.labelSmall,
                            color = Color.White.copy(alpha = 0.8f),
                            fontWeight = FontWeight.ExtraBold,
                            letterSpacing = 1.sp
                        )

                        Spacer(modifier = Modifier.height(10.dp))

                        Row(
                            verticalAlignment = Alignment.Bottom,
                            horizontalArrangement = Arrangement.Center
                        ) {
                            Text(
                                text = if (metricResult.isCwa) {
                                    String.format(java.util.Locale.US, "%.2f", metricResult.scoreValue)
                                } else {
                                    String.format(java.util.Locale.US, "%.2f", metricResult.scoreValue)
                                },
                                style = MaterialTheme.typography.displayMedium,
                                fontWeight = FontWeight.Black,
                                color = Color.White
                            )
                            Spacer(modifier = Modifier.width(6.dp))
                            Text(
                                text = if (metricResult.isCwa) "% CWA" else "/ 4.00",
                                style = MaterialTheme.typography.titleMedium,
                                color = Color.White.copy(alpha = 0.8f),
                                modifier = Modifier.padding(bottom = 10.dp)
                            )
                        }

                        Spacer(modifier = Modifier.height(8.dp))

                        Surface(
                            shape = RoundedCornerShape(12.dp),
                            color = Color(metricResult.honoursColorHex)
                        ) {
                            Text(
                                text = "🏆 ${metricResult.honoursClass}",
                                modifier = Modifier.padding(horizontal = 14.dp, vertical = 6.dp),
                                style = MaterialTheme.typography.labelMedium,
                                color = Color.White,
                                fontWeight = FontWeight.Bold
                            )
                        }

                        Spacer(modifier = Modifier.height(16.dp))
                        Divider(color = Color.White.copy(alpha = 0.15f))
                        Spacer(modifier = Modifier.height(14.dp))

                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceAround
                        ) {
                            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                Text("TOTAL CREDITS", style = MaterialTheme.typography.labelSmall, color = Color.White.copy(alpha = 0.7f))
                                Text("${metricResult.totalCredits} Units", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold, color = Color.White)
                            }
                            Divider(modifier = Modifier.height(30.dp).width(1.dp), color = Color.White.copy(alpha = 0.2f))
                            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                Text("COURSES", style = MaterialTheme.typography.labelSmall, color = Color.White.copy(alpha = 0.7f))
                                Text("${allCourses.size} Total", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold, color = Color.White)
                            }
                            Divider(modifier = Modifier.height(30.dp).width(1.dp), color = Color.White.copy(alpha = 0.2f))
                            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                Text("TENANT SCHEME", style = MaterialTheme.typography.labelSmall, color = Color.White.copy(alpha = 0.7f))
                                Text(currentInstitution.shortCode, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold, color = Color.White)
                            }
                        }
                    }
                }
            }

            // Grade Distribution Bar
            item {
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(18.dp),
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                    elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
                ) {
                    Column(modifier = Modifier.padding(16.dp)) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                text = "Grade Distribution",
                                style = MaterialTheme.typography.titleSmall,
                                fontWeight = FontWeight.Bold
                            )
                            Text(
                                text = "${gradeCounts["A"] ?: 0} Distinctions (A)",
                                style = MaterialTheme.typography.labelSmall,
                                color = CampusGreen,
                                fontWeight = FontWeight.Bold
                            )
                        }

                        Spacer(modifier = Modifier.height(10.dp))

                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            GradeChip(label = "A", count = gradeCounts["A"] ?: 0, color = CampusGreen, modifier = Modifier.weight(1f))
                            GradeChip(label = "B+", count = gradeCounts["B+"] ?: 0, color = AcademicBlue, modifier = Modifier.weight(1f))
                            GradeChip(label = "B", count = gradeCounts["B"] ?: 0, color = AcademicBlue.copy(alpha = 0.75f), modifier = Modifier.weight(1f))
                            GradeChip(label = "C+", count = gradeCounts["C+"] ?: 0, color = AcademicGold, modifier = Modifier.weight(1f))
                            GradeChip(label = "C", count = gradeCounts["C"] ?: 0, color = AcademicGold.copy(alpha = 0.75f), modifier = Modifier.weight(1f))
                        }
                    }
                }
            }

            // Target Goal Estimator Card
            item {
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(18.dp),
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
                    elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
                ) {
                    Column(modifier = Modifier.padding(18.dp)) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(Icons.Filled.AutoGraph, contentDescription = null, tint = Color(currentInstitution.primaryColorHex))
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(
                                text = "${currentInstitution.shortCode} Honours Classification",
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.Bold
                            )
                        }

                        Spacer(modifier = Modifier.height(8.dp))

                        if (metricResult.isCwa) {
                            Text(
                                text = "🎓 KNUST CWA Honours Benchmark: First Class (≥70.0%), Second Class Upper (60.0% - 69.9%), Second Class Lower (50.0% - 59.9%), Pass (40.0% - 49.9%).\nYour Current Standing: ${metricResult.formattedScore} (${metricResult.honoursClass})",
                                style = MaterialTheme.typography.bodyMedium,
                                color = Slate800
                            )
                        } else {
                            Text(
                                text = "🎓 University Honours Benchmark: First Class (≥3.60), Second Class Upper (3.00 - 3.59), Second Class Lower (2.00 - 2.99), Pass (1.00 - 1.99).\nYour Current Standing: ${metricResult.formattedScore} (${metricResult.honoursClass})",
                                style = MaterialTheme.typography.bodyMedium,
                                color = Slate800
                            )
                        }
                    }
                }
            }

            // Interactive GPA & Course Assessment Grade Tracker
            item {
                CourseGradeTrackerComponent(
                    viewModel = viewModel,
                    modifier = Modifier.fillMaxWidth()
                )
            }
        }
    }

    if (showInstitutionDialog) {
        com.example.ui.components.InstitutionSelectorDialog(
            viewModel = viewModel,
            onDismiss = { showInstitutionDialog = false }
        )
    }

    // Add Course Grade Dialog
    if (showAddCourseDialog) {
        var semName by remember { mutableStateOf("Year 3 - Semester 2") }
        var code by remember { mutableStateOf("") }
        var title by remember { mutableStateOf("") }
        var credits by remember { mutableStateOf("3") }
        var selectedGrade by remember { mutableStateOf("A") }
        var selectedTargetGrade by remember { mutableStateOf("A") }
        var enableAssessmentTracking by remember { mutableStateOf(true) }

        val grades = listOf("A", "B+", "B", "C+", "C", "D+", "D", "F")

        AlertDialog(
            onDismissRequest = { showAddCourseDialog = false },
            title = {
                Text(
                    text = "Add Course to GPA Tracker",
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold
                )
            },
            text = {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = 4.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    OutlinedTextField(
                        value = semName,
                        onValueChange = { semName = it },
                        label = { Text("Semester *") },
                        placeholder = { Text("e.g. Year 3 - Semester 2") },
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(12.dp),
                        singleLine = true
                    )
                    OutlinedTextField(
                        value = code,
                        onValueChange = { code = it },
                        label = { Text("Course Code *") },
                        placeholder = { Text("e.g. CSCD 302") },
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(12.dp),
                        singleLine = true
                    )
                    OutlinedTextField(
                        value = title,
                        onValueChange = { title = it },
                        label = { Text("Course Title *") },
                        placeholder = { Text("e.g. Software Engineering") },
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(12.dp),
                        singleLine = true
                    )
                    OutlinedTextField(
                        value = credits,
                        onValueChange = { credits = it },
                        label = { Text("Credit Hours *") },
                        placeholder = { Text("3") },
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(12.dp),
                        singleLine = true
                    )

                    // Target Grade
                    Text("Target Grade to Achieve:", style = MaterialTheme.typography.labelSmall, fontWeight = FontWeight.Bold)
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(4.dp)
                    ) {
                        listOf("A", "B+", "B", "C+", "C").forEach { g ->
                            FilterChip(
                                selected = selectedTargetGrade == g,
                                onClick = { selectedTargetGrade = g },
                                label = { Text(g) },
                                modifier = Modifier.weight(1f),
                                shape = RoundedCornerShape(10.dp)
                            )
                        }
                    }
                }
            },
            confirmButton = {
                Button(
                    onClick = {
                        if (code.isNotBlank() && title.isNotBlank()) {
                            viewModel.addGpaCourse(
                                semName = semName,
                                code = code,
                                title = title,
                                credits = credits.toIntOrNull() ?: 3,
                                grade = selectedGrade,
                                targetGrade = selectedTargetGrade,
                                isWeighted = enableAssessmentTracking
                            )
                            showAddCourseDialog = false
                        }
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = AcademicBlue),
                    enabled = code.isNotBlank() && title.isNotBlank()
                ) {
                    Text("Save Course")
                }
            },
            dismissButton = {
                TextButton(onClick = { showAddCourseDialog = false }) {
                    Text("Cancel")
                }
            }
        )
    }
}

@Composable
fun GradeChip(
    label: String,
    count: Int,
    color: Color,
    modifier: Modifier = Modifier
) {
    Surface(
        shape = RoundedCornerShape(10.dp),
        color = color.copy(alpha = 0.12f),
        modifier = modifier
    ) {
        Column(
            modifier = Modifier.padding(vertical = 6.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = label,
                style = MaterialTheme.typography.labelSmall,
                fontWeight = FontWeight.Bold,
                color = color
            )
            Text(
                text = "$count",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Black,
                color = color
            )
        }
    }
}
