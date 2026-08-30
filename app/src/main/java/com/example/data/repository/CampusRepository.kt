package com.example.data.repository

import com.example.data.local.AppDatabase
import com.example.data.local.entity.AcademicScheduleEventEntity
import com.example.data.local.entity.CampusAlertEntity
import com.example.data.local.entity.CampusLibraryEntity
import com.example.data.local.entity.CampusLocationEntity
import com.example.data.local.entity.CourseAssessmentEntity
import com.example.data.local.entity.CourseScheduleEntity
import com.example.data.local.entity.ExamScheduleEntity
import com.example.data.local.entity.GpaCourseEntity
import com.example.data.local.entity.LibraryFloorEntity
import com.example.data.local.entity.StudyResourceEntity
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.map
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import kotlin.math.roundToInt
import kotlin.math.sqrt

enum class SeatOccupancyLevel {
    HIGH_AVAILABILITY, // > 40% available (Green)
    MODERATE,          // 20% - 40% available (Amber)
    NEARLY_FULL,       // 5% - 20% available (Orange)
    FULL               // < 5% available (Red)
}

data class LibraryWithFloors(
    val library: CampusLibraryEntity,
    val floors: List<LibraryFloorEntity>,
    val occupancyPercentage: Int, // (total - available) * 100 / total
    val occupancyLevel: SeatOccupancyLevel,
    val statusText: String
)

data class GpaSummary(
    val cumulativeGpa: Double,
    val totalCreditHours: Int,
    val classification: String,
    val semesterBreakdowns: List<SemesterGpa>
)

data class SemesterGpa(
    val semesterName: String,
    val gpa: Double,
    val credits: Int,
    val courses: List<GpaCourseEntity>
)

data class CourseWeightedGradeSummary(
    val course: GpaCourseEntity,
    val assessments: List<CourseAssessmentEntity>,
    val totalWeightAssigned: Double, // e.g. 60.0%
    val remainingWeight: Double, // 100.0 - totalWeightAssigned = 40.0%
    val currentWeightedScore: Double, // sum of (scoreAchieved / maxScore * weightPercentage) -> e.g. 54.2
    val currentNormalizedPercentage: Double, // on completed work (54.2 / 60.0 * 100) -> e.g. 90.3%
    val finalCalculatedPercentage: Double,
    val letterGrade: String, // "A", "B+", "B", "C+", "C", "D+", "D", "F"
    val gradePoint: Double, // 4.0, 3.5, etc.
    val targetGrade: String, // e.g. "A"
    val targetScoreThreshold: Double,
    val scoreNeededOnRemainingForTarget: Double?,
    val scoreNeededForA: Double?,
    val scoreNeededForBPlus: Double?,
    val scoreNeededForB: Double?,
    val scoreNeededForC: Double?,
    val isTargetGuaranteed: Boolean,
    val isTargetImpossible: Boolean
)

data class NavigationRoute(
    val fromLocation: CampusLocationEntity,
    val toLocation: CampusLocationEntity,
    val distanceMeters: Int,
    val estimatedWalkingMinutes: Int,
    val steps: List<String>,
    val pathPoints: List<Pair<Float, Float>>
)

class CampusRepository(private val db: AppDatabase) {

    // Timetables
    val allSchedules: Flow<List<CourseScheduleEntity>> = db.courseScheduleDao().getAllSchedules()

    fun getSchedulesForDay(day: Int): Flow<List<CourseScheduleEntity>> =
        db.courseScheduleDao().getSchedulesForDay(day)

    suspend fun insertSchedule(schedule: CourseScheduleEntity) =
        db.courseScheduleDao().insertSchedule(schedule)

    suspend fun updateSchedule(schedule: CourseScheduleEntity) =
        db.courseScheduleDao().updateSchedule(schedule)

    suspend fun deleteSchedule(schedule: CourseScheduleEntity) =
        db.courseScheduleDao().deleteSchedule(schedule)

    suspend fun updateVenue(id: Long, newVenue: String, note: String) =
        db.courseScheduleDao().updateVenue(id, newVenue, note)

    suspend fun toggleScheduleAlarm(id: Long, enabled: Boolean) =
        db.courseScheduleDao().toggleAlarm(id, enabled)

    // Examinations
    val allExams: Flow<List<ExamScheduleEntity>> = db.examScheduleDao().getAllExams()

    suspend fun insertExam(exam: ExamScheduleEntity) =
        db.examScheduleDao().insertExam(exam)

    suspend fun updateExam(exam: ExamScheduleEntity) =
        db.examScheduleDao().updateExam(exam)

    suspend fun deleteExam(exam: ExamScheduleEntity) =
        db.examScheduleDao().deleteExam(exam)

    suspend fun toggleExamAlarm(id: Long, enabled: Boolean) =
        db.examScheduleDao().toggleExamAlarm(id, enabled)

    // Campus Locations & Map
    val allLocations: Flow<List<CampusLocationEntity>> = db.campusLocationDao().getAllLocations()

    suspend fun insertLocation(location: CampusLocationEntity) =
        db.campusLocationDao().insertLocation(location)

    suspend fun updateLocation(location: CampusLocationEntity) =
        db.campusLocationDao().updateLocation(location)

    suspend fun deleteLocation(location: CampusLocationEntity) =
        db.campusLocationDao().deleteLocation(location)

    // Alerts
    val allAlerts: Flow<List<CampusAlertEntity>> = db.campusAlertDao().getAllAlerts()

    suspend fun insertAlert(alert: CampusAlertEntity) =
        db.campusAlertDao().insertAlert(alert)

    suspend fun markAlertAsRead(id: Long) =
        db.campusAlertDao().markAsRead(id)

    suspend fun deleteAlert(alert: CampusAlertEntity) =
        db.campusAlertDao().deleteAlert(alert)

    // GPA & Course Assessments
    val allGpaCourses: Flow<List<GpaCourseEntity>> = db.gpaCourseDao().getAllGpaCourses()
    val allAssessments: Flow<List<CourseAssessmentEntity>> = db.courseAssessmentDao().getAllAssessments()

    fun getAssessmentsForCourse(courseId: Long): Flow<List<CourseAssessmentEntity>> =
        db.courseAssessmentDao().getAssessmentsForCourse(courseId)

    val courseWeightedSummaries: Flow<List<CourseWeightedGradeSummary>> =
        combine(allGpaCourses, allAssessments) { courses, assessments ->
            val assessmentMap = assessments.groupBy { it.courseId }
            courses.map { course ->
                calculateCourseWeightedSummary(course, assessmentMap[course.id] ?: emptyList())
            }
        }

    val gpaSummary: Flow<GpaSummary> =
        combine(allGpaCourses, allAssessments) { courses, assessments ->
            val assessmentMap = assessments.groupBy { it.courseId }
            // Dynamically update course letter grade and grade points if weighted from assessments
            val dynamicCourses = courses.map { course ->
                if (course.isWeightedFromAssessments) {
                    val summary = calculateCourseWeightedSummary(course, assessmentMap[course.id] ?: emptyList())
                    course.copy(
                        grade = summary.letterGrade,
                        gradePoint = summary.gradePoint
                    )
                } else {
                    course
                }
            }
            calculateGpaSummary(dynamicCourses)
        }

    suspend fun insertGpaCourse(course: GpaCourseEntity): Long =
        db.gpaCourseDao().insertCourse(course)

    suspend fun updateGpaCourse(course: GpaCourseEntity) =
        db.gpaCourseDao().updateCourse(course)

    suspend fun deleteGpaCourse(course: GpaCourseEntity) {
        db.courseAssessmentDao().deleteAssessmentsForCourse(course.id)
        db.gpaCourseDao().deleteCourse(course)
    }

    suspend fun insertAssessment(assessment: CourseAssessmentEntity): Long =
        db.courseAssessmentDao().insertAssessment(assessment)

    suspend fun updateAssessment(assessment: CourseAssessmentEntity) =
        db.courseAssessmentDao().updateAssessment(assessment)

    suspend fun deleteAssessment(assessment: CourseAssessmentEntity) =
        db.courseAssessmentDao().deleteAssessment(assessment)

    // Study Resources
    val allResources: Flow<List<StudyResourceEntity>> = db.studyResourceDao().getAllResources()

    suspend fun insertResource(resource: StudyResourceEntity) =
        db.studyResourceDao().insertResource(resource)

    suspend fun toggleBookmark(id: Long, isBookmarked: Boolean) =
        db.studyResourceDao().toggleBookmark(id, isBookmarked)

    suspend fun incrementDownload(id: Long) =
        db.studyResourceDao().incrementDownload(id)

    suspend fun deleteResource(resource: StudyResourceEntity) =
        db.studyResourceDao().deleteResource(resource)

    // Campus Libraries Directory
    val allLibraries: Flow<List<CampusLibraryEntity>> = db.campusLibraryDao().getAllLibraries()
    val allLibraryFloors: Flow<List<LibraryFloorEntity>> = db.campusLibraryDao().getAllFloors()

    val librariesWithFloors: Flow<List<LibraryWithFloors>> = combine(
        allLibraries,
        allLibraryFloors
    ) { libs, floors ->
        libs.map { lib ->
            val libFloors = floors.filter { it.libraryId == lib.id }
            val occupied = (lib.totalCapacity - lib.availableSeats).coerceAtLeast(0)
            val occPercent = if (lib.totalCapacity > 0) ((occupied * 100.0) / lib.totalCapacity).roundToInt() else 0
            val availPercent = if (lib.totalCapacity > 0) ((lib.availableSeats * 100.0) / lib.totalCapacity).roundToInt() else 0

            val occLevel = when {
                availPercent >= 35 -> SeatOccupancyLevel.HIGH_AVAILABILITY
                availPercent >= 18 -> SeatOccupancyLevel.MODERATE
                availPercent > 5 -> SeatOccupancyLevel.NEARLY_FULL
                else -> SeatOccupancyLevel.FULL
            }

            val status = when (occLevel) {
                SeatOccupancyLevel.HIGH_AVAILABILITY -> "Plenty of Desks"
                SeatOccupancyLevel.MODERATE -> "Moderate Occupancy"
                SeatOccupancyLevel.NEARLY_FULL -> "Filling Up Fast"
                SeatOccupancyLevel.FULL -> "Nearly Full / Standing Room"
            }

            LibraryWithFloors(
                library = lib,
                floors = libFloors,
                occupancyPercentage = occPercent,
                occupancyLevel = occLevel,
                statusText = status
            )
        }
    }

    fun getFloorsForLibrary(libraryId: String): Flow<List<LibraryFloorEntity>> =
        db.campusLibraryDao().getFloorsForLibrary(libraryId)

    fun searchLibraries(query: String): Flow<List<CampusLibraryEntity>> =
        db.campusLibraryDao().searchLibraries(query)

    suspend fun insertLibrary(library: CampusLibraryEntity) =
        db.campusLibraryDao().insertLibrary(library)

    suspend fun updateLibrary(library: CampusLibraryEntity) =
        db.campusLibraryDao().updateLibrary(library)

    suspend fun updateLibrarySeatCount(libraryId: String, availableSeats: Int) =
        db.campusLibraryDao().updateLibraryAvailableSeats(libraryId, availableSeats)

    suspend fun updateFloorSeatCount(floorId: Long, availableSeats: Int) =
        db.campusLibraryDao().updateFloorAvailableSeats(floorId, availableSeats)

    suspend fun insertFloor(floor: LibraryFloorEntity) =
        db.campusLibraryDao().insertFloor(floor)

    suspend fun updateFloor(floor: LibraryFloorEntity) =
        db.campusLibraryDao().updateFloor(floor)

    // Smart Leave Time Calculation
    fun calculateSuggestedLeaveTime(
        eventStartTime: String, // e.g. "14:00"
        walkingMinutes: Int,
        bufferMinutes: Int = 10
    ): String {
        try {
            val sdf = SimpleDateFormat("HH:mm", Locale.getDefault())
            val date = sdf.parse(eventStartTime) ?: return eventStartTime
            val calendar = Calendar.getInstance()
            calendar.time = date
            val totalMinutesToSubtract = walkingMinutes + bufferMinutes
            calendar.add(Calendar.MINUTE, -totalMinutesToSubtract)
            return sdf.format(calendar.time)
        } catch (e: Exception) {
            return eventStartTime
        }
    }

    // Navigation Route calculation between 2 campus buildings
    fun calculateRoute(
        start: CampusLocationEntity,
        destination: CampusLocationEntity
    ): NavigationRoute {
        val dx = destination.mapX - start.mapX
        val dy = destination.mapY - start.mapY
        val directDistanceUnits = sqrt((dx * dx + dy * dy).toDouble())
        // Campus scale: 100 units is approx 1,400 meters
        val distanceMeters = (directDistanceUnits * 14.0).roundToInt().coerceAtLeast(60)
        // Average campus walking speed: 80 meters/min
        val walkingMinutes = ((distanceMeters / 75.0).roundToInt()).coerceAtLeast(2)

        // Intermediate waypoints for realistic campus walkway paths
        val midX1 = start.mapX + dx * 0.35f + if (dy != 0f) -3f else 3f
        val midY1 = start.mapY + dy * 0.25f
        val midX2 = start.mapX + dx * 0.70f
        val midY2 = start.mapY + dy * 0.75f + if (dx != 0f) 4f else -4f

        val pathPoints = listOf(
            Pair(start.mapX, start.mapY),
            Pair(midX1, midY1),
            Pair(midX2, midY2),
            Pair(destination.mapX, destination.mapY)
        )

        val steps = listOf(
            "Start from ${start.name} entrance and head toward Central Walkway.",
            "Continue straight along University Avenue past the main quad (~${distanceMeters / 2}m).",
            "Take the shaded pedestrian walkway directly toward ${destination.shortCode}.",
            "Arrive at ${destination.name}. Enter through main gate or ground floor foyer."
        )

        return NavigationRoute(
            fromLocation = start,
            toLocation = destination,
            distanceMeters = distanceMeters,
            estimatedWalkingMinutes = walkingMinutes,
            steps = steps,
            pathPoints = pathPoints
        )
    }

    companion object {
        fun calculateCourseWeightedSummary(
            course: GpaCourseEntity,
            assessments: List<CourseAssessmentEntity>
        ): CourseWeightedGradeSummary {
            if (assessments.isEmpty()) {
                val gradeInfo = scoreToLetterAndGpa(course.gradePoint * 20.0)
                return CourseWeightedGradeSummary(
                    course = course,
                    assessments = emptyList(),
                    totalWeightAssigned = 0.0,
                    remainingWeight = 100.0,
                    currentWeightedScore = 0.0,
                    currentNormalizedPercentage = if (course.gradePoint > 0) course.gradePoint * 20.0 else 80.0,
                    finalCalculatedPercentage = if (course.gradePoint > 0) course.gradePoint * 20.0 else 80.0,
                    letterGrade = course.grade,
                    gradePoint = course.gradePoint,
                    targetGrade = course.targetGrade,
                    targetScoreThreshold = gradeToThreshold(course.targetGrade),
                    scoreNeededOnRemainingForTarget = calculateNeeded(gradeToThreshold(course.targetGrade), 0.0, 100.0),
                    scoreNeededForA = calculateNeeded(80.0, 0.0, 100.0),
                    scoreNeededForBPlus = calculateNeeded(75.0, 0.0, 100.0),
                    scoreNeededForB = calculateNeeded(70.0, 0.0, 100.0),
                    scoreNeededForC = calculateNeeded(60.0, 0.0, 100.0),
                    isTargetGuaranteed = false,
                    isTargetImpossible = false
                )
            }

            var totalWeight = 0.0
            var currentWeightedScore = 0.0

            assessments.forEach { assessment ->
                val max = if (assessment.maxScore > 0) assessment.maxScore else 100.0
                val ratio = (assessment.scoreAchieved / max).coerceAtLeast(0.0)
                val contribution = ratio * assessment.weightPercentage
                totalWeight += assessment.weightPercentage
                currentWeightedScore += contribution
            }

            val remainingWeight = (100.0 - totalWeight).coerceAtLeast(0.0)
            val normalizedPercentage = if (totalWeight > 0) {
                (currentWeightedScore / totalWeight) * 100.0
            } else 0.0

            // If 100% of weight is assessed, final percentage is currentWeightedScore.
            // If assessments are partially in progress, final percentage estimate is normalized on completed work.
            val finalPercentage = if (remainingWeight <= 0.001) currentWeightedScore else normalizedPercentage
            val (letter, gp) = scoreToLetterAndGpa(finalPercentage)

            val targetThreshold = gradeToThreshold(course.targetGrade)
            val neededForTarget = calculateNeeded(targetThreshold, currentWeightedScore, remainingWeight)
            val neededForA = calculateNeeded(80.0, currentWeightedScore, remainingWeight)
            val neededForBPlus = calculateNeeded(75.0, currentWeightedScore, remainingWeight)
            val neededForB = calculateNeeded(70.0, currentWeightedScore, remainingWeight)
            val neededForC = calculateNeeded(60.0, currentWeightedScore, remainingWeight)

            val isGuaranteed = currentWeightedScore >= targetThreshold
            val isImpossible = neededForTarget != null && neededForTarget > 100.0

            return CourseWeightedGradeSummary(
                course = course,
                assessments = assessments,
                totalWeightAssigned = (totalWeight * 10.0).roundToInt() / 10.0,
                remainingWeight = (remainingWeight * 10.0).roundToInt() / 10.0,
                currentWeightedScore = (currentWeightedScore * 10.0).roundToInt() / 10.0,
                currentNormalizedPercentage = (normalizedPercentage * 10.0).roundToInt() / 10.0,
                finalCalculatedPercentage = (finalPercentage * 10.0).roundToInt() / 10.0,
                letterGrade = letter,
                gradePoint = gp,
                targetGrade = course.targetGrade,
                targetScoreThreshold = targetThreshold,
                scoreNeededOnRemainingForTarget = neededForTarget,
                scoreNeededForA = neededForA,
                scoreNeededForBPlus = neededForBPlus,
                scoreNeededForB = neededForB,
                scoreNeededForC = neededForC,
                isTargetGuaranteed = isGuaranteed,
                isTargetImpossible = isImpossible
            )
        }

        fun scoreToLetterAndGpa(score: Double): Pair<String, Double> {
            val rounded = (score * 10.0).roundToInt() / 10.0
            return when {
                rounded >= 79.5 -> "A" to 4.0
                rounded >= 74.5 -> "B+" to 3.5
                rounded >= 69.5 -> "B" to 3.0
                rounded >= 64.5 -> "C+" to 2.5
                rounded >= 59.5 -> "C" to 2.0
                rounded >= 54.5 -> "D+" to 1.5
                rounded >= 49.5 -> "D" to 1.0
                else -> "F" to 0.0
            }
        }

        fun gradeToThreshold(grade: String): Double {
            return when (grade.uppercase().trim()) {
                "A" -> 80.0
                "B+" -> 75.0
                "B" -> 70.0
                "C+" -> 65.0
                "C" -> 60.0
                "D+" -> 55.0
                "D" -> 50.0
                else -> 0.0
            }
        }

        private fun calculateNeeded(
            targetThreshold: Double,
            currentWeightedScore: Double,
            remainingWeight: Double
        ): Double? {
            if (remainingWeight <= 0.0) {
                return if (currentWeightedScore >= targetThreshold) 0.0 else null
            }
            val needed = ((targetThreshold - currentWeightedScore) / remainingWeight) * 100.0
            val rounded = (needed * 10.0).roundToInt() / 10.0
            return if (rounded <= 0.0) 0.0 else rounded
        }
    }

    private fun calculateGpaSummary(courses: List<GpaCourseEntity>): GpaSummary {
        if (courses.isEmpty()) {
            return GpaSummary(
                cumulativeGpa = 0.0,
                totalCreditHours = 0,
                classification = "No Grades Recorded",
                semesterBreakdowns = emptyList()
            )
        }

        val grouped = courses.groupBy { it.semesterName }
        val semesterList = grouped.map { (semName, semCourses) ->
            val semCredits = semCourses.sumOf { it.creditHours }
            val semQualityPoints = semCourses.sumOf { it.creditHours * it.gradePoint }
            val semGpa = if (semCredits > 0) (semQualityPoints / semCredits) else 0.0
            SemesterGpa(
                semesterName = semName,
                gpa = (semGpa * 100).roundToInt() / 100.0,
                credits = semCredits,
                courses = semCourses
            )
        }

        val totalCredits = courses.sumOf { it.creditHours }
        val totalQualityPoints = courses.sumOf { it.creditHours * it.gradePoint }
        val cgpa = if (totalCredits > 0) (totalQualityPoints / totalCredits) else 0.0
        val roundedCgpa = (cgpa * 100).roundToInt() / 100.0

        val classification = when {
            roundedCgpa >= 3.60 -> "First Class Honours (Distinction)"
            roundedCgpa >= 3.00 -> "Second Class Honours (Upper Division)"
            roundedCgpa >= 2.00 -> "Second Class Honours (Lower Division)"
            roundedCgpa >= 1.50 -> "Third Class Honours"
            roundedCgpa >= 1.00 -> "Pass"
            else -> "Fail / Probation"
        }

        return GpaSummary(
            cumulativeGpa = roundedCgpa,
            totalCreditHours = totalCredits,
            classification = classification,
            semesterBreakdowns = semesterList
        )
    }

    // Academic Schedule Events (Classes, Exams, Study Sessions, Labs)
    val allAcademicEvents: Flow<List<AcademicScheduleEventEntity>> =
        db.academicScheduleEventDao().getAllEvents()

    fun getAcademicEventsByType(type: String): Flow<List<AcademicScheduleEventEntity>> =
        db.academicScheduleEventDao().getEventsByType(type)

    fun getRecurringAcademicEventsForDay(dayOfWeek: Int): Flow<List<AcademicScheduleEventEntity>> =
        db.academicScheduleEventDao().getRecurringEventsForDay(dayOfWeek)

    fun getAcademicEventsForDate(date: String): Flow<List<AcademicScheduleEventEntity>> =
        db.academicScheduleEventDao().getEventsForDate(date)

    fun searchAcademicEvents(query: String): Flow<List<AcademicScheduleEventEntity>> =
        db.academicScheduleEventDao().searchEvents(query)

    suspend fun insertAcademicEvent(event: AcademicScheduleEventEntity): Long =
        db.academicScheduleEventDao().insertEvent(event)

    suspend fun updateAcademicEvent(event: AcademicScheduleEventEntity) =
        db.academicScheduleEventDao().updateEvent(event)

    suspend fun deleteAcademicEvent(event: AcademicScheduleEventEntity) =
        db.academicScheduleEventDao().deleteEvent(event)

    suspend fun setAcademicEventCompleted(id: Long, completed: Boolean) =
        db.academicScheduleEventDao().setEventCompleted(id, completed)

    suspend fun toggleAcademicEventAlarm(id: Long, enabled: Boolean) =
        db.academicScheduleEventDao().toggleAlarm(id, enabled)

    /**
     * Clears existing schedules, exams, and map locations to prevent data overlap when moving between campuses.
     */
    suspend fun clearCampusLocationsAndSchedules() {
        db.campusLocationDao().deleteAllLocations()
        db.courseScheduleDao().deleteAllSchedules()
        db.examScheduleDao().deleteAllExams()
    }

    /**
     * Replaces current campus locations and adds sample schedules for the newly activated institution profile.
     */
    suspend fun switchInstitutionData(
        profile: com.example.data.model.InstitutionProfile,
        replaceSchedules: Boolean = false,
        clearOldDataFirst: Boolean = false
    ) {
        if (clearOldDataFirst) {
            db.campusLocationDao().deleteAllLocations()
            if (replaceSchedules) {
                db.courseScheduleDao().deleteAllSchedules()
                db.examScheduleDao().deleteAllExams()
            }
        }

        // Insert new locations for the active institution
        for (location in profile.defaultLocations) {
            db.campusLocationDao().insertLocation(location)
        }

        if (replaceSchedules && profile.sampleSchedules.isNotEmpty()) {
            for (schedule in profile.sampleSchedules) {
                db.courseScheduleDao().insertSchedule(schedule)
            }
            for (exam in profile.sampleExams) {
                db.examScheduleDao().insertExam(exam)
            }
        }
    }
}


