package com.example.data.local.entity

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "course_schedules")
data class CourseScheduleEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val courseCode: String,
    val courseTitle: String,
    val lecturer: String,
    val dayOfWeek: Int, // 1 = Monday, 2 = Tuesday, 3 = Wednesday, 4 = Thursday, 5 = Friday
    val startTime: String, // e.g. "08:30"
    val endTime: String,   // e.g. "10:30"
    val venue: String,     // e.g. "KAB 1"
    val creditHours: Int = 3,
    val colorHex: Long = 0xFF1E3A8A,
    val isCancelledOrMoved: Boolean = false,
    val changeNote: String? = null,
    val reminderMinutesBefore: Int = 15,
    val isAlarmEnabled: Boolean = true
)

@Entity(tableName = "exam_schedules")
data class ExamScheduleEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val courseCode: String,
    val courseTitle: String,
    val examDate: String, // e.g. "2026-08-25"
    val startTime: String, // "14:00"
    val endTime: String,   // "17:00"
    val venue: String,     // "KAB 1 (Great Hall Annex)"
    val seatRange: String = "Index 10920000 - 10920150",
    val creditHours: Int = 3,
    val invigilator: String = "Prof. S. Osei / Dr. Mensah",
    val walkingTimeMinutes: Int = 15,
    val suggestedLeaveTime: String = "13:35",
    val isAlarmSet: Boolean = true,
    val rules: String = "Calculators permitted. No mobile phones or smartwatches. Bring Student ID Card."
)

@Entity(tableName = "campus_locations")
data class CampusLocationEntity(
    @PrimaryKey val id: String,
    val name: String,
    val shortCode: String,
    val category: String, // "Lecture Hall", "Examination Center", "Library", "Laboratory", "Hostel / Hall", "Cafeteria & Food", "Administration / Sports"
    val mapX: Float, // percentage coordinate 0..100
    val mapY: Float, // percentage coordinate 0..100
    val description: String,
    val floors: Int = 3,
    val hasAirConditioning: Boolean = true,
    val hasPowerSockets: Boolean = true,
    val wheelchairAccessible: Boolean = true,
    val walkingTimeFromHostelMinutes: Int = 12,
    val popularVenuesInside: String = "Room 101, Room 102, Main Auditorium"
)

@Entity(tableName = "campus_alerts")
data class CampusAlertEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val title: String,
    val message: String,
    val category: String, // "VENUE_CHANGE", "EXAM_ALERT", "ACADEMIC", "CAMPUS_NEWS", "EMERGENCY"
    val author: String,
    val timestamp: Long = System.currentTimeMillis(),
    val isPinned: Boolean = false,
    val courseCode: String? = null,
    val isRead: Boolean = false
)

@Entity(tableName = "gpa_courses")
data class GpaCourseEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val semesterName: String, // "Year 3 - Semester 1"
    val courseCode: String,
    val courseTitle: String,
    val creditHours: Int,
    val grade: String = "A", // "A", "B+", "B", "C+", "C", "D+", "D", "F"
    val gradePoint: Double = 4.0, // 4.0, 3.5, etc.
    val targetGrade: String = "A", // User target grade
    val isWeightedFromAssessments: Boolean = true
)

@Entity(
    tableName = "course_assessments"
)
data class CourseAssessmentEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val courseId: Long, // references GpaCourseEntity.id
    val title: String, // e.g. "Midterm Exam", "Lab Report 1", "Quiz 1", "Final Exam"
    val category: String = "Exam", // "Exam", "Quiz", "Assignment", "Project", "Lab", "Attendance"
    val scoreAchieved: Double, // e.g. 85.0
    val maxScore: Double = 100.0, // e.g. 100.0
    val weightPercentage: Double, // e.g. 30.0 (meaning 30% of final course grade)
    val date: String = "", // e.g. "2026-08-10"
    val notes: String = ""
)

@Entity(tableName = "study_resources")
data class StudyResourceEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val courseCode: String,
    val courseTitle: String,
    val title: String,
    val year: String,
    val fileType: String = "PDF",
    val fileSize: String = "2.4 MB",
    val summaryText: String,
    val downloadCount: Int = 142,
    val isBookmarked: Boolean = false
)

@Entity(tableName = "campus_libraries")
data class CampusLibraryEntity(
    @PrimaryKey val id: String, // e.g. "balme_main", "law_library", "ugbs_library", "science_library", "chs_library"
    val name: String,
    val campusZone: String, // "Central Campus", "Legon West", "South Campus", "Korle-Bu Annex"
    val totalCapacity: Int,
    val availableSeats: Int,
    val openingHoursWeekdays: String, // "07:30 AM - 10:00 PM"
    val openingHoursWeekends: String, // "09:00 AM - 08:00 PM"
    val openingHoursExams: String, // "24/7 24-Hour Study Mode"
    val isOpenNow: Boolean = true,
    val currentNoiseLevel: String = "Silent Study", // "Silent Study", "Quiet Carrels", "Group Discussion Allowed"
    val hasPowerSockets: Boolean = true,
    val hasWiFi: Boolean = true,
    val hasAirConditioning: Boolean = true,
    val hasDiscussionRooms: Boolean = true,
    val hasPrintingStation: Boolean = true,
    val hasComputerLab: Boolean = true,
    val contactPhone: String = "+233 30 250 0150",
    val librarianHelpDesk: String = "Ground Floor Central Lobby",
    val mapLocationCode: String = "BLM",
    val totalFloorsCount: Int = 3,
    val description: String = "The premier academic research repository with extensive Africana collections, carrels, and digital archives."
)

@Entity(
    tableName = "library_floors",
    foreignKeys = [
        androidx.room.ForeignKey(
            entity = CampusLibraryEntity::class,
            parentColumns = ["id"],
            childColumns = ["libraryId"],
            onDelete = androidx.room.ForeignKey.CASCADE
        )
    ],
    indices = [androidx.room.Index("libraryId")]
)
data class LibraryFloorEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val libraryId: String,
    val floorNumber: Int, // 0 = Ground Floor, 1 = 1st Floor, 2 = 2nd Floor, 3 = 3rd Floor
    val floorName: String, // e.g. "Ground Floor (Africana & Reference)", "1st Floor (General Stacks & Carrels)"
    val totalFloorSeats: Int,
    val availableFloorSeats: Int,
    val noisePolicy: String, // "Deep Silence - No Whispering", "Quiet Study Only", "Collaborative Discussion Permitted"
    val sectionsDescription: String, // "Africana Collection, Reference Desk, Computer Lab A, Fast Copy Center"
    val powerSocketAvailabilityPercent: Int = 85,
    val crowdStatus: String = "Moderate Density", // "Low Density", "Moderate Density", "High / Nearly Full"
    val interactiveMapZones: String = "North Wing Carrels (Free: 45); East Stack Desks (Free: 22); South Study Pods (Full); Tech Hub (Free: 18)"
)

enum class AcademicEventType {
    CLASS,
    EXAM,
    STUDY_SESSION,
    LAB,
    TUTORIAL,
    ASSIGNMENT_DEADLINE
}

@Entity(tableName = "academic_schedule_events")
data class AcademicScheduleEventEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val title: String,
    val courseCode: String = "",
    val eventType: String = "CLASS", // "CLASS", "EXAM", "STUDY_SESSION", "LAB", "TUTORIAL", "ASSIGNMENT_DEADLINE"
    val dayOfWeek: Int? = null, // 1 = Monday .. 7 = Sunday (for weekly recurring events)
    val eventDate: String? = null, // "YYYY-MM-DD" for single/date-specific events
    val startTime: String, // "08:30"
    val endTime: String,   // "10:30"
    val venue: String,     // "KAB 1 (Kwame Nkrumah Complex)" or "Balme Library Study Pod 3"
    val campusLocationCode: String? = null, // e.g. "KAB", "BLM", "JQB", "NNB"
    val instructorOrLead: String = "",
    val notes: String = "",
    val colorHex: Long = 0xFF1E3A8A,
    val reminderMinutesBefore: Int = 15,
    val isAlarmEnabled: Boolean = true,
    val isCompleted: Boolean = false,
    val isRecurring: Boolean = false,
    val priority: String = "NORMAL", // "LOW", "NORMAL", "HIGH", "URGENT"
    val createdAt: Long = System.currentTimeMillis()
)

