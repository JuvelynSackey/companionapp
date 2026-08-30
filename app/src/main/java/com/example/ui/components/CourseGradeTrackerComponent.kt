package com.example.ui.components

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
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
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.data.local.entity.CourseAssessmentEntity
import com.example.data.local.entity.GpaCourseEntity
import com.example.data.repository.CampusRepository
import com.example.data.repository.CourseWeightedGradeSummary
import com.example.ui.MainViewModel
import com.example.ui.theme.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CourseGradeTrackerComponent(
    viewModel: MainViewModel,
    modifier: Modifier = Modifier
) {
    val allCourses by viewModel.allGpaCourses.collectAsState()
    val courseSummaries by viewModel.courseWeightedSummaries.collectAsState()
    val selectedCourseForAssessment by viewModel.selectedCourseForAssessment.collectAsState()

    var selectedSemesterFilter by remember { mutableStateOf("All Semesters") }
    var showAddAssessmentDialog by remember { mutableStateOf(false) }
    var editingAssessment by remember { mutableStateOf<CourseAssessmentEntity?>(null) }
    var showTargetSelectorDialog by remember { mutableStateOf(false) }

    // Distinct list of semester names
    val semesters = remember(allCourses) {
        val list = mutableListOf("All Semesters")
        val semNames = allCourses.map { it.semesterName }.distinct()
        list.addAll(semNames)
        list
    }

    val filteredSummaries = remember(courseSummaries, selectedSemesterFilter) {
        if (selectedSemesterFilter == "All Semesters") {
            courseSummaries
        } else {
            courseSummaries.filter { it.course.semesterName == selectedSemesterFilter }
        }
    }

    Column(
        modifier = modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(14.dp)
    ) {
        // Semester Filter Chips
        LazyRow(
            modifier = Modifier
                .fillMaxWidth()
                .testTag("semester_filter_row"),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            contentPadding = PaddingValues(horizontal = 4.dp)
        ) {
            items(semesters) { sem ->
                val isSelected = sem == selectedSemesterFilter
                FilterChip(
                    selected = isSelected,
                    onClick = { selectedSemesterFilter = sem },
                    label = {
                        Text(
                            text = sem,
                            fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal
                        )
                    },
                    colors = FilterChipDefaults.filterChipColors(
                        selectedContainerColor = AcademicBlue,
                        selectedLabelColor = Color.White,
                        containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
                    ),
                    shape = RoundedCornerShape(12.dp)
                )
            }
        }

        // Section Title & Quick Stats
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column {
                Text(
                    text = "Course Grades & Assessment Weights",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.onSurface
                )
                Text(
                    text = "${filteredSummaries.size} courses in calculation • Tap to inspect assessments",
                    style = MaterialTheme.typography.bodySmall,
                    color = Slate600
                )
            }
        }

        // List of Course Cards
        if (filteredSummaries.isEmpty()) {
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.4f))
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(24.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Icon(
                        imageVector = Icons.Outlined.Assignment,
                        contentDescription = null,
                        tint = Slate400,
                        modifier = Modifier.size(40.dp)
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        text = "No course grades recorded for $selectedSemesterFilter",
                        style = MaterialTheme.typography.bodyMedium,
                        color = Slate600
                    )
                }
            }
        } else {
            filteredSummaries.forEach { summary ->
                CourseGradeSummaryCard(
                    summary = summary,
                    onClick = { viewModel.selectCourseForAssessment(summary.course) },
                    onDelete = { viewModel.deleteGpaCourse(summary.course) }
                )
            }
        }
    }

    // Course Assessment Detail & Simulator BottomSheet / Dialog
    selectedCourseForAssessment?.let { activeCourse ->
        val activeSummary = courseSummaries.find { it.course.id == activeCourse.id }
            ?: CampusRepository.calculateCourseWeightedSummary(activeCourse, emptyList())

        AssessmentDetailModal(
            summary = activeSummary,
            onDismiss = { viewModel.selectCourseForAssessment(null) },
            onAddAssessment = { showAddAssessmentDialog = true },
            onEditAssessment = { assessment -> editingAssessment = assessment },
            onDeleteAssessment = { assessment -> viewModel.deleteCourseAssessment(assessment) },
            onChangeTargetGrade = { newTarget ->
                viewModel.updateCourseTargetGrade(activeCourse, newTarget)
            }
        )
    }

    // Add / Edit Assessment Dialog
    if (showAddAssessmentDialog || editingAssessment != null) {
        val activeCourse = selectedCourseForAssessment
        if (activeCourse != null) {
            AssessmentEditDialog(
                course = activeCourse,
                existing = editingAssessment,
                onDismiss = {
                    showAddAssessmentDialog = false
                    editingAssessment = null
                },
                onSave = { title, category, score, maxScore, weight, date, notes ->
                    if (editingAssessment != null) {
                        viewModel.updateCourseAssessment(
                            editingAssessment!!.copy(
                                title = title,
                                category = category,
                                scoreAchieved = score,
                                maxScore = maxScore,
                                weightPercentage = weight,
                                date = date,
                                notes = notes
                            )
                        )
                    } else {
                        viewModel.addCourseAssessment(
                            courseId = activeCourse.id,
                            title = title,
                            category = category,
                            scoreAchieved = score,
                            maxScore = maxScore,
                            weightPercentage = weight,
                            date = date,
                            notes = notes
                        )
                    }
                    showAddAssessmentDialog = false
                    editingAssessment = null
                }
            )
        }
    }
}

@Composable
fun CourseGradeSummaryCard(
    summary: CourseWeightedGradeSummary,
    onClick: () -> Unit,
    onDelete: () -> Unit,
    modifier: Modifier = Modifier
) {
    val course = summary.course
    val gradeColor = when (summary.letterGrade) {
        "A" -> CampusGreen
        "B+", "B" -> AcademicBlue
        "C+", "C" -> AcademicGold
        else -> CampusRed
    }

    Card(
        modifier = modifier
            .fillMaxWidth()
            .clickable { onClick() }
            .testTag("course_grade_card_${course.courseCode}"),
        shape = RoundedCornerShape(18.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.5.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
        ) {
            // Header Row: Code, Title, Credits, Grade Badge
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column(modifier = Modifier.weight(1f)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text(
                            text = course.courseCode,
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold,
                            color = AcademicBlue
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Surface(
                            shape = RoundedCornerShape(6.dp),
                            color = Slate100
                        ) {
                            Text(
                                text = "${course.creditHours} Credits",
                                modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp),
                                style = MaterialTheme.typography.labelSmall,
                                color = Slate700,
                                fontWeight = FontWeight.SemiBold
                            )
                        }
                    }
                    Text(
                        text = course.courseTitle,
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurface,
                        fontWeight = FontWeight.Medium,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                }

                Spacer(modifier = Modifier.width(12.dp))

                // Letter Grade Pill
                Surface(
                    shape = RoundedCornerShape(12.dp),
                    color = gradeColor.copy(alpha = 0.14f)
                ) {
                    Row(
                        modifier = Modifier.padding(horizontal = 10.dp, vertical = 6.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Text(
                                text = summary.letterGrade,
                                style = MaterialTheme.typography.titleLarge,
                                fontWeight = FontWeight.ExtraBold,
                                color = gradeColor
                            )
                            Text(
                                text = "${summary.gradePoint} GP",
                                style = MaterialTheme.typography.labelSmall,
                                fontWeight = FontWeight.Bold,
                                color = gradeColor
                            )
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(12.dp))

            // Assessment Weight Progress Bar
            Column {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text(
                        text = if (summary.assessments.isNotEmpty()) {
                            "${summary.assessments.size} Assessments (${String.format("%.0f", summary.totalWeightAssigned)}% assessed)"
                        } else {
                            "No assessments added yet"
                        },
                        style = MaterialTheme.typography.bodySmall,
                        color = Slate600
                    )
                    Text(
                        text = if (summary.remainingWeight > 0) {
                            "${String.format("%.0f", summary.remainingWeight)}% Final Exam remaining"
                        } else {
                            "100% Completed"
                        },
                        style = MaterialTheme.typography.bodySmall,
                        fontWeight = FontWeight.SemiBold,
                        color = if (summary.remainingWeight > 0) AcademicBlue else CampusGreen
                    )
                }

                Spacer(modifier = Modifier.height(6.dp))

                val progress = (summary.totalWeightAssigned / 100.0).toFloat().coerceIn(0f, 1f)
                LinearProgressIndicator(
                    progress = { progress },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(8.dp)
                        .clip(RoundedCornerShape(4.dp)),
                    color = if (progress >= 1f) CampusGreen else AcademicBlue,
                    trackColor = Slate200
                )
            }

            Spacer(modifier = Modifier.height(10.dp))

            // Running Weighted Score & Target Forecast Info
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(Slate50, RoundedCornerShape(10.dp))
                    .padding(horizontal = 10.dp, vertical = 8.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        imageVector = Icons.Filled.Calculate,
                        contentDescription = null,
                        tint = AcademicBlue,
                        modifier = Modifier.size(16.dp)
                    )
                    Spacer(modifier = Modifier.width(6.dp))
                    Text(
                        text = "Score: ${String.format("%.1f", summary.finalCalculatedPercentage)}%",
                        style = MaterialTheme.typography.bodySmall,
                        fontWeight = FontWeight.Bold,
                        color = Slate900
                    )
                }

                // Target forecast indicator
                if (summary.remainingWeight > 0) {
                    val needed = summary.scoreNeededOnRemainingForTarget
                    if (needed != null && needed <= 100.0) {
                        Text(
                            text = "Target ${summary.targetGrade}: Need ${String.format("%.1f", needed)}% on final",
                            style = MaterialTheme.typography.labelSmall,
                            fontWeight = FontWeight.SemiBold,
                            color = if (needed <= 75.0) CampusGreen else AcademicGold
                        )
                    } else if (needed != null && needed > 100.0) {
                        Text(
                            text = "Target ${summary.targetGrade}: Out of reach",
                            style = MaterialTheme.typography.labelSmall,
                            fontWeight = FontWeight.SemiBold,
                            color = CampusRed
                        )
                    } else {
                        Text(
                            text = "Target ${summary.targetGrade}: Secured 🎉",
                            style = MaterialTheme.typography.labelSmall,
                            fontWeight = FontWeight.SemiBold,
                            color = CampusGreen
                        )
                    }
                } else {
                    Text(
                        text = "Final Grade Locked",
                        style = MaterialTheme.typography.labelSmall,
                        fontWeight = FontWeight.Bold,
                        color = CampusGreen
                    )
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AssessmentDetailModal(
    summary: CourseWeightedGradeSummary,
    onDismiss: () -> Unit,
    onAddAssessment: () -> Unit,
    onEditAssessment: (CourseAssessmentEntity) -> Unit,
    onDeleteAssessment: (CourseAssessmentEntity) -> Unit,
    onChangeTargetGrade: (String) -> Unit
) {
    val course = summary.course
    val targetGrades = listOf("A", "B+", "B", "C+", "C", "D+", "D")

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        dragHandle = { BottomSheetDefaults.DragHandle() },
        containerColor = MaterialTheme.colorScheme.surface,
        shape = RoundedCornerShape(topStart = 28.dp, topEnd = 28.dp)
    ) {
        LazyColumn(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 20.dp),
            contentPadding = PaddingValues(bottom = 40.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Header Info
            item {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.Top
                ) {
                    Column(modifier = Modifier.weight(1f)) {
                        Surface(
                            shape = RoundedCornerShape(8.dp),
                            color = AcademicBlue.copy(alpha = 0.12f)
                        ) {
                            Text(
                                text = course.semesterName,
                                modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                                style = MaterialTheme.typography.labelSmall,
                                color = AcademicBlue,
                                fontWeight = FontWeight.Bold
                            )
                        }
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(
                            text = "${course.courseCode}: ${course.courseTitle}",
                            style = MaterialTheme.typography.titleLarge,
                            fontWeight = FontWeight.Bold,
                            color = MaterialTheme.colorScheme.onSurface
                        )
                        Text(
                            text = "${course.creditHours} Credit Units • Weighted Grading Scheme",
                            style = MaterialTheme.typography.bodySmall,
                            color = Slate600
                        )
                    }

                    Surface(
                        shape = RoundedCornerShape(16.dp),
                        color = when (summary.letterGrade) {
                            "A" -> CampusGreen
                            "B+", "B" -> AcademicBlue
                            "C+", "C" -> AcademicGold
                            else -> CampusRed
                        }
                    ) {
                        Column(
                            modifier = Modifier.padding(horizontal = 14.dp, vertical = 8.dp),
                            horizontalAlignment = Alignment.CenterHorizontally
                        ) {
                            Text(
                                text = summary.letterGrade,
                                style = MaterialTheme.typography.titleLarge,
                                fontWeight = FontWeight.ExtraBold,
                                color = Color.White
                            )
                            Text(
                                text = "${String.format("%.1f", summary.finalCalculatedPercentage)}%",
                                style = MaterialTheme.typography.labelSmall,
                                fontWeight = FontWeight.Bold,
                                color = Color.White.copy(alpha = 0.9f)
                            )
                        }
                    }
                }
            }

            // What-If Final Grade Simulator Card
            item {
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(20.dp),
                    colors = CardDefaults.cardColors(containerColor = Navy900)
                ) {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(18.dp)
                    ) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Icon(Icons.Filled.AutoAwesome, contentDescription = null, tint = AcademicGoldLight)
                                Spacer(modifier = Modifier.width(8.dp))
                                Text(
                                    text = "Final Exam & Target Simulator",
                                    style = MaterialTheme.typography.titleSmall,
                                    fontWeight = FontWeight.Bold,
                                    color = Color.White
                                )
                            }
                            Text(
                                text = "${String.format("%.0f", summary.remainingWeight)}% Remaining",
                                style = MaterialTheme.typography.labelSmall,
                                color = Slate200,
                                fontWeight = FontWeight.SemiBold
                            )
                        }

                        Spacer(modifier = Modifier.height(12.dp))

                        // Target Grade Selector
                        Text(
                            text = "SELECT YOUR TARGET GRADE:",
                            style = MaterialTheme.typography.labelSmall,
                            color = Slate300,
                            fontWeight = FontWeight.Bold,
                            letterSpacing = 0.8.sp
                        )

                        Spacer(modifier = Modifier.height(6.dp))

                        LazyRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            items(targetGrades) { grade ->
                                val isSelected = summary.targetGrade.equals(grade, ignoreCase = true)
                                Surface(
                                    shape = RoundedCornerShape(10.dp),
                                    color = if (isSelected) AcademicGold else Color.White.copy(alpha = 0.12f),
                                    modifier = Modifier.clickable { onChangeTargetGrade(grade) }
                                ) {
                                    Text(
                                        text = grade,
                                        modifier = Modifier.padding(horizontal = 14.dp, vertical = 6.dp),
                                        style = MaterialTheme.typography.labelMedium,
                                        fontWeight = FontWeight.Bold,
                                        color = if (isSelected) Navy900 else Color.White
                                    )
                                }
                            }
                        }

                        Spacer(modifier = Modifier.height(14.dp))

                        // Target Calculation Result
                        val needed = summary.scoreNeededOnRemainingForTarget
                        if (summary.remainingWeight <= 0) {
                            Surface(
                                shape = RoundedCornerShape(12.dp),
                                color = CampusGreen.copy(alpha = 0.2f),
                                modifier = Modifier.fillMaxWidth()
                            ) {
                                Row(
                                    modifier = Modifier.padding(12.dp),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Icon(Icons.Filled.CheckCircle, contentDescription = null, tint = CampusGreenLight)
                                    Spacer(modifier = Modifier.width(10.dp))
                                    Text(
                                        text = "All assessments submitted! Final weighted grade is locked at ${String.format("%.1f", summary.finalCalculatedPercentage)}% (${summary.letterGrade}).",
                                        style = MaterialTheme.typography.bodySmall,
                                        color = Color.White
                                    )
                                }
                            }
                        } else if (summary.isTargetGuaranteed) {
                            Surface(
                                shape = RoundedCornerShape(12.dp),
                                color = CampusGreen.copy(alpha = 0.25f),
                                modifier = Modifier.fillMaxWidth()
                            ) {
                                Row(
                                    modifier = Modifier.padding(12.dp),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Icon(Icons.Filled.Lock, contentDescription = null, tint = CampusGreenLight)
                                    Spacer(modifier = Modifier.width(10.dp))
                                    Text(
                                        text = "🔒 Target ${summary.targetGrade} Secured! You have accumulated ${String.format("%.1f", summary.currentWeightedScore)}% so far, exceeding the ${String.format("%.0f", summary.targetScoreThreshold)}% requirement.",
                                        style = MaterialTheme.typography.bodySmall,
                                        color = Color.White
                                    )
                                }
                            }
                        } else if (needed != null && needed <= 100.0) {
                            Surface(
                                shape = RoundedCornerShape(12.dp),
                                color = if (needed <= 75.0) CampusGreen.copy(alpha = 0.2f) else AcademicGold.copy(alpha = 0.2f),
                                modifier = Modifier.fillMaxWidth()
                            ) {
                                Column(modifier = Modifier.padding(12.dp)) {
                                    Row(verticalAlignment = Alignment.CenterVertically) {
                                        Icon(
                                            imageVector = Icons.Filled.TrendingUp,
                                            contentDescription = null,
                                            tint = if (needed <= 75.0) CampusGreenLight else AcademicGoldLight
                                        )
                                        Spacer(modifier = Modifier.width(8.dp))
                                        Text(
                                            text = "Score Needed on Remaining ${String.format("%.0f", summary.remainingWeight)}%: ${String.format("%.1f", needed)}%",
                                            style = MaterialTheme.typography.titleSmall,
                                            fontWeight = FontWeight.Bold,
                                            color = Color.White
                                        )
                                    }
                                    Spacer(modifier = Modifier.height(4.dp))
                                    Text(
                                        text = if (needed <= 70.0) {
                                            "🎯 Highly Achievable! Scoring at least ${String.format("%.1f", needed)}% on your upcoming Final Exam guarantees an '${summary.targetGrade}'."
                                        } else {
                                            "⚡ Dedicated Revision Needed: Aim for ${String.format("%.1f", needed)}%+ on the remaining assessments to reach your target '${summary.targetGrade}'."
                                        },
                                        style = MaterialTheme.typography.bodySmall,
                                        color = Slate200
                                    )
                                }
                            }
                        } else {
                            Surface(
                                shape = RoundedCornerShape(12.dp),
                                color = CampusRed.copy(alpha = 0.25f),
                                modifier = Modifier.fillMaxWidth()
                            ) {
                                Row(
                                    modifier = Modifier.padding(12.dp),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Icon(Icons.Filled.Warning, contentDescription = null, tint = CampusRedLight)
                                    Spacer(modifier = Modifier.width(10.dp))
                                    Text(
                                        text = "Target '${summary.targetGrade}' requires ${String.format("%.1f", needed ?: 0.0)}% on the remaining weight, which is above 100%. Aim for next tier grade.",
                                        style = MaterialTheme.typography.bodySmall,
                                        color = Color.White
                                    )
                                }
                            }
                        }
                    }
                }
            }

            // Assessments Section Header with + Add Button
            item {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column {
                        Text(
                            text = "Assessment Score Breakdown",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold
                        )
                        Text(
                            text = "${summary.assessments.size} recorded • ${String.format("%.0f", summary.totalWeightAssigned)}% total weight",
                            style = MaterialTheme.typography.bodySmall,
                            color = Slate600
                        )
                    }

                    FilledTonalButton(
                        onClick = onAddAssessment,
                        shape = RoundedCornerShape(12.dp),
                        colors = ButtonDefaults.filledTonalButtonColors(
                            containerColor = AcademicBlue.copy(alpha = 0.12f),
                            contentColor = AcademicBlue
                        ),
                        modifier = Modifier.testTag("add_assessment_button")
                    ) {
                        Icon(Icons.Filled.Add, contentDescription = null, modifier = Modifier.size(18.dp))
                        Spacer(modifier = Modifier.width(6.dp))
                        Text("Add Score", fontWeight = FontWeight.Bold)
                    }
                }
            }

            // Assessment Items
            if (summary.assessments.isEmpty()) {
                item {
                    Card(
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(14.dp),
                        colors = CardDefaults.cardColors(containerColor = Slate100)
                    ) {
                        Column(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(20.dp),
                            horizontalAlignment = Alignment.CenterHorizontally
                        ) {
                            Text(
                                text = "No individual assessment scores recorded yet.",
                                style = MaterialTheme.typography.bodyMedium,
                                color = Slate700
                            )
                            Spacer(modifier = Modifier.height(6.dp))
                            Text(
                                text = "Tap 'Add Score' to add Quizzes, Midterms, Lab Reports, or Assignments.",
                                style = MaterialTheme.typography.bodySmall,
                                color = Slate500
                            )
                        }
                    }
                }
            } else {
                items(summary.assessments) { assessment ->
                    AssessmentScoreRow(
                        assessment = assessment,
                        onEdit = { onEditAssessment(assessment) },
                        onDelete = { onDeleteAssessment(assessment) }
                    )
                }
            }
        }
    }
}

@Composable
fun AssessmentScoreRow(
    assessment: CourseAssessmentEntity,
    onEdit: () -> Unit,
    onDelete: () -> Unit,
    modifier: Modifier = Modifier
) {
    val percentage = if (assessment.maxScore > 0) {
        (assessment.scoreAchieved / assessment.maxScore) * 100.0
    } else 0.0

    val weightedContribution = (percentage / 100.0) * assessment.weightPercentage

    Card(
        modifier = modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.35f)),
        elevation = CardDefaults.cardElevation(defaultElevation = 0.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(14.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            // Category Icon / Pill
            Surface(
                shape = RoundedCornerShape(12.dp),
                color = when (assessment.category.lowercase()) {
                    "exam" -> CampusRed.copy(alpha = 0.12f)
                    "quiz" -> AcademicBlue.copy(alpha = 0.12f)
                    "project" -> CampusGreen.copy(alpha = 0.12f)
                    "lab" -> AcademicGold.copy(alpha = 0.18f)
                    else -> Slate200
                },
                modifier = Modifier.size(46.dp)
            ) {
                Box(contentAlignment = Alignment.Center) {
                    Icon(
                        imageVector = when (assessment.category.lowercase()) {
                            "exam" -> Icons.Filled.School
                            "quiz" -> Icons.Filled.Quiz
                            "project" -> Icons.Filled.Code
                            "lab" -> Icons.Filled.Science
                            else -> Icons.Filled.Assignment
                        },
                        contentDescription = null,
                        tint = when (assessment.category.lowercase()) {
                            "exam" -> CampusRed
                            "quiz" -> AcademicBlue
                            "project" -> CampusGreen
                            "lab" -> AcademicGold
                            else -> Slate700
                        },
                        modifier = Modifier.size(24.dp)
                    )
                }
            }

            Spacer(modifier = Modifier.width(12.dp))

            // Title & Details
            Column(modifier = Modifier.weight(1f)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        text = assessment.title,
                        style = MaterialTheme.typography.titleSmall,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onSurface,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                }

                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        text = "Score: ${String.format("%.1f", assessment.scoreAchieved)} / ${String.format("%.0f", assessment.maxScore)} (${String.format("%.1f", percentage)}%)",
                        style = MaterialTheme.typography.bodySmall,
                        color = Slate700,
                        fontWeight = FontWeight.SemiBold
                    )
                }

                Text(
                    text = "Weight: ${String.format("%.0f", assessment.weightPercentage)}% • Contributes +${String.format("%.1f", weightedContribution)}%",
                    style = MaterialTheme.typography.labelSmall,
                    color = AcademicBlue,
                    fontWeight = FontWeight.SemiBold
                )

                if (assessment.notes.isNotBlank()) {
                    Text(
                        text = "Note: ${assessment.notes}",
                        style = MaterialTheme.typography.labelSmall,
                        color = Slate500,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                }
            }

            // Actions (Edit & Delete)
            Row(verticalAlignment = Alignment.CenterVertically) {
                IconButton(onClick = onEdit, modifier = Modifier.size(34.dp)) {
                    Icon(
                        imageVector = Icons.Filled.Edit,
                        contentDescription = "Edit",
                        tint = Slate600,
                        modifier = Modifier.size(18.dp)
                    )
                }
                IconButton(onClick = onDelete, modifier = Modifier.size(34.dp)) {
                    Icon(
                        imageVector = Icons.Filled.DeleteOutline,
                        contentDescription = "Delete",
                        tint = CampusRed,
                        modifier = Modifier.size(18.dp)
                    )
                }
            }
        }
    }
}

@Composable
fun AssessmentEditDialog(
    course: GpaCourseEntity,
    existing: CourseAssessmentEntity?,
    onDismiss: () -> Unit,
    onSave: (title: String, category: String, score: Double, maxScore: Double, weight: Double, date: String, notes: String) -> Unit
) {
    var title by remember { mutableStateOf(existing?.title ?: "") }
    var category by remember { mutableStateOf(existing?.category ?: "Exam") }
    var scoreAchieved by remember { mutableStateOf(existing?.scoreAchieved?.toString() ?: "") }
    var maxScore by remember { mutableStateOf(existing?.maxScore?.toString() ?: "100") }
    var weightPercentage by remember { mutableStateOf(existing?.weightPercentage?.toString() ?: "20") }
    var date by remember { mutableStateOf(existing?.date ?: "") }
    var notes by remember { mutableStateOf(existing?.notes ?: "") }

    val categories = listOf("Exam", "Quiz", "Assignment", "Project", "Lab", "Attendance")

    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Text(
                text = if (existing != null) "Edit Assessment Score" else "Add Assessment Score",
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold
            )
        },
        text = {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 4.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                Text(
                    text = "Course: ${course.courseCode} (${course.courseTitle})",
                    style = MaterialTheme.typography.bodySmall,
                    color = AcademicBlue,
                    fontWeight = FontWeight.SemiBold
                )

                OutlinedTextField(
                    value = title,
                    onValueChange = { title = it },
                    label = { Text("Assessment Title *") },
                    placeholder = { Text("e.g. Midterm Exam, Quiz 1, Lab 2") },
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(12.dp),
                    singleLine = true
                )

                // Category Selection Chips
                Text("Category:", style = MaterialTheme.typography.labelSmall, fontWeight = FontWeight.Bold)
                LazyRow(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    items(categories) { cat ->
                        val isSelected = cat.equals(category, ignoreCase = true)
                        FilterChip(
                            selected = isSelected,
                            onClick = { category = cat },
                            label = { Text(cat) },
                            shape = RoundedCornerShape(10.dp)
                        )
                    }
                }

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    OutlinedTextField(
                        value = scoreAchieved,
                        onValueChange = { scoreAchieved = it },
                        label = { Text("Score *") },
                        placeholder = { Text("85") },
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                        modifier = Modifier.weight(1f),
                        shape = RoundedCornerShape(12.dp),
                        singleLine = true
                    )
                    OutlinedTextField(
                        value = maxScore,
                        onValueChange = { maxScore = it },
                        label = { Text("Out of *") },
                        placeholder = { Text("100") },
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                        modifier = Modifier.weight(1f),
                        shape = RoundedCornerShape(12.dp),
                        singleLine = true
                    )
                    OutlinedTextField(
                        value = weightPercentage,
                        onValueChange = { weightPercentage = it },
                        label = { Text("Weight % *") },
                        placeholder = { Text("25") },
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                        modifier = Modifier.weight(1f),
                        shape = RoundedCornerShape(12.dp),
                        singleLine = true
                    )
                }

                OutlinedTextField(
                    value = notes,
                    onValueChange = { notes = it },
                    label = { Text("Notes / Feedback (Optional)") },
                    placeholder = { Text("e.g. UML diagrams feedback") },
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(12.dp),
                    maxLines = 2
                )
            }
        },
        confirmButton = {
            Button(
                onClick = {
                    val s = scoreAchieved.toDoubleOrNull() ?: 0.0
                    val m = maxScore.toDoubleOrNull() ?: 100.0
                    val w = weightPercentage.toDoubleOrNull() ?: 20.0
                    if (title.isNotBlank()) {
                        onSave(title, category, s, m, w, date, notes)
                    }
                },
                enabled = title.isNotBlank() && scoreAchieved.isNotBlank(),
                colors = ButtonDefaults.buttonColors(containerColor = AcademicBlue)
            ) {
                Text(if (existing != null) "Update Score" else "Save Score")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    )
}
