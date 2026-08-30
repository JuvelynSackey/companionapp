package com.example.data.repository

import com.example.data.local.entity.GpaCourseEntity
import com.example.data.model.GradingSystemType
import com.example.data.model.HonoursThreshold
import com.example.data.model.InstitutionProfile
import com.example.data.model.InstitutionRegistry

data class AcademicMetricResult(
    val scoreValue: Double, // e.g. 3.82 for GPA, or 78.4% for CWA
    val formattedScore: String, // "3.82 / 4.00" or "78.40% CWA"
    val honoursClass: String, // "First Class Honours"
    val honoursColorHex: Long,
    val totalCredits: Int,
    val isCwa: Boolean,
    val metricLabel: String, // "Cumulative GPA" or "Cumulative Weighted Average (CWA)"
    val statusSummary: String
)

object GradingEngine {

    /**
     * Calculates the overall academic performance (GPA or CWA) based on the active institution's grading system.
     */
    fun calculateAcademicMetric(
        courses: List<GpaCourseEntity>,
        institution: InstitutionProfile
    ): AcademicMetricResult {
        if (courses.isEmpty()) {
            val isCwa = institution.gradingSystem == GradingSystemType.KNUST_CWA
            return AcademicMetricResult(
                scoreValue = 0.0,
                formattedScore = if (isCwa) "0.00% CWA" else "0.00 / 4.00",
                honoursClass = "No Data",
                honoursColorHex = 0xFF6B7280,
                totalCredits = 0,
                isCwa = isCwa,
                metricLabel = if (isCwa) "Cumulative CWA" else "Cumulative GPA",
                statusSummary = "Add courses to compute your ${if (isCwa) "CWA" else "GPA"}"
            )
        }

        val isCwa = institution.gradingSystem == GradingSystemType.KNUST_CWA
        var totalCreditHours = 0
        var totalWeightedPoints = 0.0

        for (course in courses) {
            val credits = course.creditHours.coerceAtLeast(1)
            totalCreditHours += credits
            
            if (isCwa) {
                // In KNUST CWA system: Score is percentage (e.g. 85%), weighted = credits * percentageScore
                // If grade is letter, convert to midpoint percentage or use gradePoint mapped
                val percentageScore = getPercentageFromGrade(course.grade, course.gradePoint)
                totalWeightedPoints += (credits * percentageScore)
            } else {
                // Standard GPA system (e.g. 4.0 scale): weighted = credits * gradePoint
                totalWeightedPoints += (credits * course.gradePoint)
            }
        }

        val calculatedScore = if (totalCreditHours > 0) totalWeightedPoints / totalCreditHours else 0.0
        val honours = getHonoursClassification(calculatedScore, institution)

        val formatted = if (isCwa) {
            String.format(java.util.Locale.US, "%.2f%% CWA", calculatedScore)
        } else {
            String.format(java.util.Locale.US, "%.2f / 4.00", calculatedScore)
        }

        val statusText = "${honours.title} • $totalCreditHours Total Credit Hours"

        return AcademicMetricResult(
            scoreValue = calculatedScore,
            formattedScore = formatted,
            honoursClass = honours.title,
            honoursColorHex = honours.colorHex,
            totalCredits = totalCreditHours,
            isCwa = isCwa,
            metricLabel = if (isCwa) "Cumulative CWA" else "Cumulative GPA",
            statusSummary = statusText
        )
    }

    private fun getPercentageFromGrade(gradeLetter: String, gradePoint: Double): Double {
        return when (gradeLetter.trim().uppercase()) {
            "A" -> 85.0
            "B+" -> 75.0
            "B" -> 65.0
            "C+" -> 55.0
            "C" -> 50.0
            "D+" -> 45.0
            "D" -> 42.0
            "F" -> 30.0
            else -> {
                // Fallback: interpolate gradePoint 0..4 to 0..100
                (gradePoint / 4.0) * 100.0
            }
        }
    }

    fun getHonoursClassification(score: Double, institution: InstitutionProfile): HonoursThreshold {
        for (threshold in institution.honoursThresholds) {
            if (score >= threshold.minScore) {
                return threshold
            }
        }
        return institution.honoursThresholds.lastOrNull()
            ?: HonoursThreshold("Pass", 0.0, 100.0, 0xFF6B7280)
    }

    /**
     * Converts letter grade to grade point or default percentage based on institution type
     */
    fun gradeToValue(grade: String, gradingType: GradingSystemType): Double {
        return when (gradingType) {
            GradingSystemType.KNUST_CWA -> when (grade.uppercase()) {
                "A" -> 85.0
                "B+" -> 75.0
                "B" -> 65.0
                "C+" -> 55.0
                "C" -> 50.0
                "D+" -> 45.0
                "D" -> 42.0
                "F" -> 0.0
                else -> 70.0
            }
            GradingSystemType.SCALE_5_0 -> when (grade.uppercase()) {
                "A" -> 5.0
                "B" -> 4.0
                "C" -> 3.0
                "D" -> 2.0
                "E" -> 1.0
                "F" -> 0.0
                else -> 4.0
            }
            GradingSystemType.GPA_4_0, GradingSystemType.SCALE_4_3 -> when (grade.uppercase()) {
                "A" -> 4.0
                "B+" -> 3.5
                "B" -> 3.0
                "C+" -> 2.5
                "C" -> 2.0
                "D+" -> 1.5
                "D" -> 1.0
                "F" -> 0.0
                else -> 4.0
            }
        }
    }
}
