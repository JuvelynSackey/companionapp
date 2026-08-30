package com.example.data.local

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.sqlite.db.SupportSQLiteDatabase
import com.example.data.local.dao.AcademicScheduleEventDao
import com.example.data.local.dao.CampusAlertDao
import com.example.data.local.dao.CampusLibraryDao
import com.example.data.local.dao.CampusLocationDao
import com.example.data.local.dao.CourseAssessmentDao
import com.example.data.local.dao.CourseScheduleDao
import com.example.data.local.dao.ExamScheduleDao
import com.example.data.local.dao.GpaCourseDao
import com.example.data.local.dao.StudyResourceDao
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
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

@Database(
    entities = [
        CourseScheduleEntity::class,
        ExamScheduleEntity::class,
        CampusLocationEntity::class,
        CampusAlertEntity::class,
        GpaCourseEntity::class,
        CourseAssessmentEntity::class,
        StudyResourceEntity::class,
        CampusLibraryEntity::class,
        LibraryFloorEntity::class,
        AcademicScheduleEventEntity::class
    ],
    version = 4,
    exportSchema = false
)
abstract class AppDatabase : RoomDatabase() {
    abstract fun courseScheduleDao(): CourseScheduleDao
    abstract fun examScheduleDao(): ExamScheduleDao
    abstract fun campusLocationDao(): CampusLocationDao
    abstract fun campusAlertDao(): CampusAlertDao
    abstract fun gpaCourseDao(): GpaCourseDao
    abstract fun courseAssessmentDao(): CourseAssessmentDao
    abstract fun studyResourceDao(): StudyResourceDao
    abstract fun campusLibraryDao(): CampusLibraryDao
    abstract fun academicScheduleEventDao(): AcademicScheduleEventDao

    companion object {
        @Volatile
        private var INSTANCE: AppDatabase? = null

        fun getDatabase(context: Context): AppDatabase {
            return INSTANCE ?: synchronized(this) {
                val instance = Room.databaseBuilder(
                    context.applicationContext,
                    AppDatabase::class.java,
                    "campus_companion_db"
                )
                    .addCallback(DatabaseCallback())
                    .fallbackToDestructiveMigration()
                    .build()
                INSTANCE = instance
                instance
            }
        }

        private class DatabaseCallback : Callback() {
            override fun onCreate(db: SupportSQLiteDatabase) {
                super.onCreate(db)
                INSTANCE?.let { database ->
                    CoroutineScope(Dispatchers.IO).launch {
                        populateInitialData(database)
                    }
                }
            }
        }

        suspend fun populateInitialData(db: AppDatabase) {
            // Seed Course Timetable
            val schedules = listOf(
                CourseScheduleEntity(
                    courseCode = "CSCD 302",
                    courseTitle = "Software Engineering Principles",
                    lecturer = "Dr. K. Mensah",
                    dayOfWeek = 1, // Monday
                    startTime = "08:30",
                    endTime = "10:30",
                    venue = "KAB 1 (Kwame Nkrumah)",
                    creditHours = 3,
                    colorHex = 0xFF0284C7,
                    isCancelledOrMoved = false,
                    reminderMinutesBefore = 15,
                    isAlarmEnabled = true
                ),
                CourseScheduleEntity(
                    courseCode = "MATH 223",
                    courseTitle = "Calculus & Multivariable Analysis",
                    lecturer = "Prof. S. Osei",
                    dayOfWeek = 1, // Monday
                    startTime = "11:30",
                    endTime = "13:30",
                    venue = "JQB 22 (Jones Quartey)",
                    creditHours = 3,
                    colorHex = 0xFF7C3AED,
                    isCancelledOrMoved = false,
                    reminderMinutesBefore = 20,
                    isAlarmEnabled = true
                ),
                CourseScheduleEntity(
                    courseCode = "DCIT 308",
                    courseTitle = "Database Management Systems",
                    lecturer = "Dr. E. Akoto",
                    dayOfWeek = 2, // Tuesday
                    startTime = "09:30",
                    endTime = "11:30",
                    venue = "Science Lab 3 (CS Dept)",
                    creditHours = 3,
                    colorHex = 0xFF059669,
                    isCancelledOrMoved = true,
                    changeNote = "Prof moved class from N-Block 104 to Science Lab 3 for hands-on SQL query session.",
                    reminderMinutesBefore = 15,
                    isAlarmEnabled = true
                ),
                CourseScheduleEntity(
                    courseCode = "CPEN 204",
                    courseTitle = "Digital System Design & Logic",
                    lecturer = "Dr. G. Arthur",
                    dayOfWeek = 3, // Wednesday
                    startTime = "13:30",
                    endTime = "15:30",
                    venue = "Great Hall Annex 2",
                    creditHours = 3,
                    colorHex = 0xFFD97706,
                    isCancelledOrMoved = false,
                    reminderMinutesBefore = 15,
                    isAlarmEnabled = true
                ),
                CourseScheduleEntity(
                    courseCode = "STAT 312",
                    courseTitle = "Probability & Operational Statistics",
                    lecturer = "Prof. B. Quaye",
                    dayOfWeek = 4, // Thursday
                    startTime = "08:30",
                    endTime = "10:30",
                    venue = "KAB 2",
                    creditHours = 3,
                    colorHex = 0xFFDC2626,
                    isCancelledOrMoved = false,
                    reminderMinutesBefore = 15,
                    isAlarmEnabled = true
                ),
                CourseScheduleEntity(
                    courseCode = "CSCD 314",
                    courseTitle = "Artificial Intelligence & Heuristics",
                    lecturer = "Dr. M. Boakye",
                    dayOfWeek = 5, // Friday
                    startTime = "10:30",
                    endTime = "12:30",
                    venue = "Balme ICT Auditorium",
                    creditHours = 3,
                    colorHex = 0xFF2563EB,
                    isCancelledOrMoved = false,
                    reminderMinutesBefore = 20,
                    isAlarmEnabled = true
                )
            )
            db.courseScheduleDao().insertSchedules(schedules)

            // Seed Examination Schedules
            val exams = listOf(
                ExamScheduleEntity(
                    courseCode = "CSCD 302",
                    courseTitle = "Software Engineering Principles Final",
                    examDate = "2026-08-25",
                    startTime = "14:00",
                    endTime = "17:00",
                    venue = "KAB 1 (Kwame Nkrumah Building)",
                    seatRange = "Index: 10920001 - 10920150",
                    creditHours = 3,
                    invigilator = "Dr. K. Mensah / Mrs. Ansah",
                    walkingTimeMinutes = 15,
                    suggestedLeaveTime = "13:35",
                    isAlarmSet = true,
                    rules = "Calculators permitted. No smartwatches or smartphones. Strict 30 min early arrival required."
                ),
                ExamScheduleEntity(
                    courseCode = "MATH 223",
                    courseTitle = "Calculus & Multivariable Analysis",
                    examDate = "2026-08-28",
                    startTime = "09:00",
                    endTime = "12:00",
                    venue = "Great Hall (Main Auditorium)",
                    seatRange = "Index: 10920001 - 10920300",
                    creditHours = 3,
                    invigilator = "Prof. S. Osei / Dept Examiners",
                    walkingTimeMinutes = 18,
                    suggestedLeaveTime = "08:30",
                    isAlarmSet = true,
                    rules = "Approved Non-programmable Scientific Calculators only. Formula sheets provided."
                ),
                ExamScheduleEntity(
                    courseCode = "DCIT 308",
                    courseTitle = "Database Management Systems Theory",
                    examDate = "2026-09-02",
                    startTime = "14:00",
                    endTime = "16:30",
                    venue = "JQB 22 (Jones Quartey Building)",
                    seatRange = "Index: 10920050 - 10920200",
                    creditHours = 3,
                    invigilator = "Dr. E. Akoto",
                    walkingTimeMinutes = 12,
                    suggestedLeaveTime = "13:40",
                    isAlarmSet = true,
                    rules = "No external materials permitted. Bring blue/black pens and valid student ID card."
                ),
                ExamScheduleEntity(
                    courseCode = "CPEN 204",
                    courseTitle = "Digital System Design & Logic",
                    examDate = "2026-09-05",
                    startTime = "09:00",
                    endTime = "11:30",
                    venue = "Science Lab Complex (Room 12)",
                    seatRange = "Index: 10920001 - 10920120",
                    creditHours = 3,
                    invigilator = "Dr. G. Arthur",
                    walkingTimeMinutes = 14,
                    suggestedLeaveTime = "08:35",
                    isAlarmSet = true,
                    rules = "Strict index check at entry door. Practical simulation reports must be submitted beforehand."
                )
            )
            db.examScheduleDao().insertExams(exams)

            // Seed Campus Locations
            val locations = listOf(
                CampusLocationEntity(
                    id = "loc_kab",
                    name = "Kwame Nkrumah Building (KAB)",
                    shortCode = "KAB",
                    category = "Lecture Hall",
                    mapX = 35f,
                    mapY = 40f,
                    description = "Major lecture auditorium complex housing KAB 1, KAB 2, and high-capacity seminar rooms.",
                    floors = 3,
                    hasAirConditioning = true,
                    hasPowerSockets = true,
                    wheelchairAccessible = true,
                    walkingTimeFromHostelMinutes = 15,
                    popularVenuesInside = "KAB 1 (Ground Floor, 400 seats), KAB 2 (1st Floor, 250 seats)"
                ),
                CampusLocationEntity(
                    id = "loc_jqb",
                    name = "Jones Quartey Building (JQB)",
                    shortCode = "JQB",
                    category = "Lecture Hall",
                    mapX = 48f,
                    mapY = 55f,
                    description = "Core lecture hall building for Humanities, Social Sciences, and Computing general courses.",
                    floors = 4,
                    hasAirConditioning = true,
                    hasPowerSockets = true,
                    wheelchairAccessible = true,
                    walkingTimeFromHostelMinutes = 12,
                    popularVenuesInside = "JQB 22, JQB 14, JQB Amphitheatre, Study Terrace"
                ),
                CampusLocationEntity(
                    id = "loc_greathall",
                    name = "The Great Hall",
                    shortCode = "GH",
                    category = "Examination Center",
                    mapX = 65f,
                    mapY = 25f,
                    description = "Iconic university landmark and premier central examination hall for major semester finals and matriculation.",
                    floors = 2,
                    hasAirConditioning = true,
                    hasPowerSockets = false,
                    wheelchairAccessible = true,
                    walkingTimeFromHostelMinutes = 18,
                    popularVenuesInside = "Main Auditorium (1,200 seats), Great Hall Annex 1 & 2"
                ),
                CampusLocationEntity(
                    id = "loc_balme",
                    name = "Balme Central Library",
                    shortCode = "BALME",
                    category = "Library",
                    mapX = 52f,
                    mapY = 38f,
                    description = "Main research and study repository with 24/7 reading halls, digital labs, and past question archives.",
                    floors = 3,
                    hasAirConditioning = true,
                    hasPowerSockets = true,
                    wheelchairAccessible = true,
                    walkingTimeFromHostelMinutes = 10,
                    popularVenuesInside = "Ground Floor Reading Hub, Africana Library, 24/7 Study Annex"
                ),
                CampusLocationEntity(
                    id = "loc_sciencelab",
                    name = "Science & CS Complex (Lab 3)",
                    shortCode = "SCI-3",
                    category = "Laboratory",
                    mapX = 28f,
                    mapY = 62f,
                    description = "Specialized hardware/software laboratory hub with Linux workstations, servers, and embedded testbeds.",
                    floors = 2,
                    hasAirConditioning = true,
                    hasPowerSockets = true,
                    wheelchairAccessible = false,
                    walkingTimeFromHostelMinutes = 14,
                    popularVenuesInside = "Lab 1 (Networking), Lab 2 (Robotics), Lab 3 (Software Dev)"
                ),
                CampusLocationEntity(
                    id = "loc_pentagon",
                    name = "Pentagon Student Hostels",
                    shortCode = "PENT",
                    category = "Hostel / Hall",
                    mapX = 15f,
                    mapY = 78f,
                    description = "Premier multi-block student residential halls (Blocks A, B, C) with study rooms and transit stops.",
                    floors = 5,
                    hasAirConditioning = false,
                    hasPowerSockets = true,
                    wheelchairAccessible = true,
                    walkingTimeFromHostelMinutes = 0,
                    popularVenuesInside = "Block A Lounge, Common Study Room, Shuttle Drop Point"
                ),
                CampusLocationEntity(
                    id = "loc_sarbah",
                    name = "Mensah Sarbah Hall",
                    shortCode = "SARBAH",
                    category = "Hostel / Hall",
                    mapX = 72f,
                    mapY = 68f,
                    description = "Traditional student residential hall with recreational quad, dining hall, and close access to main road.",
                    floors = 4,
                    hasAirConditioning = false,
                    hasPowerSockets = true,
                    wheelchairAccessible = true,
                    walkingTimeFromHostelMinutes = 8,
                    popularVenuesInside = "Sarbah Dining Hall, Viking Study Hub"
                ),
                CampusLocationEntity(
                    id = "loc_nightmarket",
                    name = "Night Market & Cafeteria Square",
                    shortCode = "MKT",
                    category = "Cafeteria & Food",
                    mapX = 40f,
                    mapY = 75f,
                    description = "Vibrant campus culinary hub featuring local and international meal options, fruit stands, and stationeries.",
                    floors = 1,
                    hasAirConditioning = false,
                    hasPowerSockets = false,
                    wheelchairAccessible = true,
                    walkingTimeFromHostelMinutes = 6,
                    popularVenuesInside = "Main Food Court, Central Smoothie Bar, Print & Copy Center"
                )
            )
            db.campusLocationDao().insertLocations(locations)

            // Seed Campus Alerts
            val alerts = listOf(
                CampusAlertEntity(
                    title = "⚡ URGENT: CSCD 302 Venue Relocation",
                    message = "Please take note: Today's CSCD 302 Software Engineering lecture has been moved from N-Block 104 to Science Lab 3 (CS Dept) for live database exercises.",
                    category = "VENUE_CHANGE",
                    author = "Alex K. (Class Representative)",
                    isPinned = true,
                    courseCode = "CSCD 302",
                    isRead = false
                ),
                CampusAlertEntity(
                    title = "📅 Final Semester Examination Timetable Released",
                    message = "The official second semester examination timetable has been published by Academic Affairs. Please verify your index number seat ranges and check suggested leave times.",
                    category = "EXAM_ALERT",
                    author = "Academic Affairs Directorate",
                    isPinned = true,
                    courseCode = null,
                    isRead = false
                ),
                CampusAlertEntity(
                    title = "📚 Balme Library 24-Hour Night Reading Hub",
                    message = "In preparation for revision week and finals, Balme Library ground reading floors and digital annex will remain open 24 hours daily with uninterrupted Wi-Fi and power sockets.",
                    category = "ACADEMIC",
                    author = "Library Administration",
                    isPinned = false,
                    courseCode = null,
                    isRead = true
                ),
                CampusAlertEntity(
                    title = "🚌 Campus Shuttle Route Schedule Update",
                    message = "Campus express shuttles from Pentagon Hall to Great Hall and KAB will operate every 10 minutes from 07:30 AM to 06:30 PM on weekdays.",
                    category = "CAMPUS_NEWS",
                    author = "Student Transport Services",
                    isPinned = false,
                    courseCode = null,
                    isRead = true
                )
            )
            db.campusAlertDao().insertAlerts(alerts)

            // Seed GPA Course History
            val gpaCourses = listOf(
                GpaCourseEntity(id = 1, semesterName = "Year 2 - Semester 2", courseCode = "CSCD 202", courseTitle = "Programming II (OOP)", creditHours = 3, grade = "A", gradePoint = 4.0),
                GpaCourseEntity(id = 2, semesterName = "Year 2 - Semester 2", courseCode = "MATH 221", courseTitle = "Algebra & Geometry", creditHours = 3, grade = "B+", gradePoint = 3.5),
                GpaCourseEntity(id = 3, semesterName = "Year 2 - Semester 2", courseCode = "DCIT 204", courseTitle = "Data Structures & Algorithms", creditHours = 3, grade = "A", gradePoint = 4.0),
                GpaCourseEntity(id = 4, semesterName = "Year 2 - Semester 2", courseCode = "STAT 224", courseTitle = "Introductory Statistics", creditHours = 3, grade = "B", gradePoint = 3.0),
                GpaCourseEntity(id = 5, semesterName = "Year 2 - Semester 2", courseCode = "CBAS 210", courseTitle = "Academic Writing II", creditHours = 3, grade = "A", gradePoint = 4.0),

                GpaCourseEntity(id = 6, semesterName = "Year 3 - Semester 1", courseCode = "CSCD 301", courseTitle = "Operating Systems", creditHours = 3, grade = "A", gradePoint = 4.0),
                GpaCourseEntity(id = 7, semesterName = "Year 3 - Semester 1", courseCode = "CSCD 305", courseTitle = "Computer Networks", creditHours = 3, grade = "A", gradePoint = 4.0),
                GpaCourseEntity(id = 8, semesterName = "Year 3 - Semester 1", courseCode = "DCIT 303", courseTitle = "Computer Architecture", creditHours = 3, grade = "B+", gradePoint = 3.5),
                GpaCourseEntity(id = 9, semesterName = "Year 3 - Semester 1", courseCode = "MATH 226", courseTitle = "Discrete Mathematics", creditHours = 3, grade = "A", gradePoint = 4.0),
                GpaCourseEntity(id = 10, semesterName = "Year 3 - Semester 1", courseCode = "CSCD 311", courseTitle = "Web Technologies", creditHours = 3, grade = "A", gradePoint = 4.0),

                // Current Semester: Active Courses with Live Assessment Tracking
                GpaCourseEntity(id = 11, semesterName = "Year 3 - Semester 2", courseCode = "CSCD 302", courseTitle = "Software Engineering Principles", creditHours = 3, grade = "A", gradePoint = 4.0, targetGrade = "A", isWeightedFromAssessments = true),
                GpaCourseEntity(id = 12, semesterName = "Year 3 - Semester 2", courseCode = "MATH 223", courseTitle = "Calculus & Multivariable Analysis", creditHours = 3, grade = "B+", gradePoint = 3.5, targetGrade = "A", isWeightedFromAssessments = true),
                GpaCourseEntity(id = 13, semesterName = "Year 3 - Semester 2", courseCode = "DCIT 308", courseTitle = "Database Management Systems", creditHours = 3, grade = "A", gradePoint = 4.0, targetGrade = "A", isWeightedFromAssessments = true),
                GpaCourseEntity(id = 14, semesterName = "Year 3 - Semester 2", courseCode = "CPEN 204", courseTitle = "Digital System Design & Logic", creditHours = 3, grade = "B+", gradePoint = 3.5, targetGrade = "A", isWeightedFromAssessments = true),
                GpaCourseEntity(id = 15, semesterName = "Year 3 - Semester 2", courseCode = "STAT 312", courseTitle = "Probability & Operational Statistics", creditHours = 3, grade = "A", gradePoint = 4.0, targetGrade = "A", isWeightedFromAssessments = true),
                GpaCourseEntity(id = 16, semesterName = "Year 3 - Semester 2", courseCode = "CSCD 314", courseTitle = "Artificial Intelligence & Heuristics", creditHours = 3, grade = "A", gradePoint = 4.0, targetGrade = "A", isWeightedFromAssessments = true)
            )
            db.gpaCourseDao().insertCourses(gpaCourses)

            // Seed Course Assessment Scores with Grading Weights
            val assessments = listOf(
                // CSCD 302 Assessments (Total: 60% marked, 40% Final Exam remaining)
                CourseAssessmentEntity(courseId = 11, title = "Quiz 1: Agile & Scrum Framework", category = "Quiz", scoreAchieved = 19.0, maxScore = 20.0, weightPercentage = 10.0, date = "2026-06-15", notes = "Scored 95% on user story estimation and sprint backlog"),
                CourseAssessmentEntity(courseId = 11, title = "Mid-Semester Examination", category = "Exam", scoreAchieved = 88.0, maxScore = 100.0, weightPercentage = 25.0, date = "2026-07-10", notes = "Highest score in class for UML Sequence diagrams"),
                CourseAssessmentEntity(courseId = 11, title = "Group Project: Android Architecture", category = "Project", scoreAchieved = 94.0, maxScore = 100.0, weightPercentage = 25.0, date = "2026-08-02", notes = "Full marks for Clean Architecture & Compose implementation"),
                
                // MATH 223 Assessments (Total: 50% marked, 50% Final Exam remaining)
                CourseAssessmentEntity(courseId = 12, title = "Assignment 1: Partial Differentiation", category = "Assignment", scoreAchieved = 45.0, maxScore = 50.0, weightPercentage = 15.0, date = "2026-06-20", notes = "Solid on Jacobian transformations"),
                CourseAssessmentEntity(courseId = 12, title = "Mid-Semester Exam: Double Integrals", category = "Exam", scoreAchieved = 76.0, maxScore = 100.0, weightPercentage = 25.0, date = "2026-07-14", notes = "Review polar coordinate transformation"),
                CourseAssessmentEntity(courseId = 12, title = "Quiz 2: Vector Fields & Divergence", category = "Quiz", scoreAchieved = 18.0, maxScore = 20.0, weightPercentage = 10.0, date = "2026-07-28", notes = "Good work on curl and flux integrals"),

                // DCIT 308 Assessments (Total: 60% marked, 40% Final Exam remaining)
                CourseAssessmentEntity(courseId = 13, title = "Lab 1: SQL Complex Joins & Subqueries", category = "Lab", scoreAchieved = 29.0, maxScore = 30.0, weightPercentage = 15.0, date = "2026-06-18", notes = "Perfect recursive CTE query structure"),
                CourseAssessmentEntity(courseId = 13, title = "Midterm: BCNF Normalization & ERD", category = "Exam", scoreAchieved = 91.0, maxScore = 100.0, weightPercentage = 25.0, date = "2026-07-16", notes = "Excellent functional dependency decompositions"),
                CourseAssessmentEntity(courseId = 13, title = "Project: PostgreSQL Transaction Concurrency", category = "Project", scoreAchieved = 96.0, maxScore = 100.0, weightPercentage = 20.0, date = "2026-08-05", notes = "Tested ACID isolation levels (MVCC)"),

                // CPEN 204 Assessments (Total: 55% marked, 45% Final Exam remaining)
                CourseAssessmentEntity(courseId = 14, title = "Lab 1: Verilog Combinational Logic", category = "Lab", scoreAchieved = 18.0, maxScore = 20.0, weightPercentage = 15.0, date = "2026-06-22", notes = "Synthesized 4-bit ALU testbench"),
                CourseAssessmentEntity(courseId = 14, title = "Midterm: Flip-Flops & State Machines", category = "Exam", scoreAchieved = 82.0, maxScore = 100.0, weightPercentage = 25.0, date = "2026-07-18", notes = "Mealy and Moore FSM state transitions"),
                CourseAssessmentEntity(courseId = 14, title = "Assignment 2: Karnaugh Map Simplification", category = "Assignment", scoreAchieved = 28.0, maxScore = 30.0, weightPercentage = 15.0, date = "2026-08-01", notes = "Minimal SOP equations verified"),

                // STAT 312 Assessments (Total: 50% marked, 50% Final Exam remaining)
                CourseAssessmentEntity(courseId = 15, title = "Quiz 1: Probability Distributions", category = "Quiz", scoreAchieved = 19.5, maxScore = 20.0, weightPercentage = 15.0, date = "2026-06-24", notes = "Poisson & Normal distributions"),
                CourseAssessmentEntity(courseId = 15, title = "Mid-Semester: Hypothesis Testing & ANOVA", category = "Exam", scoreAchieved = 90.0, maxScore = 100.0, weightPercentage = 25.0, date = "2026-07-22", notes = "Confidence intervals and p-values"),
                CourseAssessmentEntity(courseId = 15, title = "Assignment: R-Programming Dataset Regressions", category = "Assignment", scoreAchieved = 20.0, maxScore = 20.0, weightPercentage = 10.0, date = "2026-08-04", notes = "Clean multivariate regression graphs"),

                // CSCD 314 Assessments (Total: 60% marked, 40% Final Exam remaining)
                CourseAssessmentEntity(courseId = 16, title = "Assignment 1: A* & Heuristic Search Graph", category = "Assignment", scoreAchieved = 98.0, maxScore = 100.0, weightPercentage = 20.0, date = "2026-06-28", notes = "Manhattan vs Euclidean heuristics implemented"),
                CourseAssessmentEntity(courseId = 16, title = "Midterm: Minimax & Alpha-Beta Pruning", category = "Exam", scoreAchieved = 89.0, maxScore = 100.0, weightPercentage = 20.0, date = "2026-07-25", notes = "Optimal game tree decision evaluations"),
                CourseAssessmentEntity(courseId = 16, title = "Project: Neural Network Digit Classifier", category = "Project", scoreAchieved = 95.0, maxScore = 100.0, weightPercentage = 20.0, date = "2026-08-08", notes = "Backpropagation algorithm built from scratch")
            )
            db.courseAssessmentDao().insertAssessments(assessments)

            // Seed Study Resources
            val resources = listOf(
                StudyResourceEntity(
                    courseCode = "CSCD 302",
                    courseTitle = "Software Engineering Principles",
                    title = "2024 & 2025 Final Exam Past Questions & Solutions",
                    year = "2025",
                    fileType = "PDF",
                    fileSize = "3.2 MB",
                    summaryText = "Complete solved past questions focusing on Agile Scrum, UML Class & Sequence Diagrams, Software Testing metrics, and Design Patterns.",
                    downloadCount = 384,
                    isBookmarked = true
                ),
                StudyResourceEntity(
                    courseCode = "MATH 223",
                    courseTitle = "Calculus & Multivariable Analysis",
                    title = "Multivariable Calculus Formula & Proof Cheatsheet",
                    year = "2025",
                    fileType = "PDF",
                    fileSize = "1.8 MB",
                    summaryText = "High-yield summary of Partial Derivatives, Double/Triple Integrals, Green's Theorem, Divergence Theorem, and Stokes' Theorem.",
                    downloadCount = 520,
                    isBookmarked = true
                ),
                StudyResourceEntity(
                    courseCode = "DCIT 308",
                    courseTitle = "Database Management Systems",
                    title = "SQL Normalization & Indexing Revision Pack",
                    year = "2024",
                    fileType = "PDF",
                    fileSize = "2.6 MB",
                    summaryText = "Step-by-step guides for 1NF to BCNF decompositions, B-Tree vs Hash index trade-offs, and ACID transaction concurrency scenarios.",
                    downloadCount = 290,
                    isBookmarked = false
                ),
                StudyResourceEntity(
                    courseCode = "CPEN 204",
                    courseTitle = "Digital System Design & Logic",
                    title = "Karnaugh Maps & Sequential Circuit Design Lab Notes",
                    year = "2025",
                    fileType = "PDF",
                    fileSize = "4.1 MB",
                    summaryText = "Detailed notes on state transition diagrams, flip-flop conversions (JK, D, T), FPGA verilog syntheses, and ALU arithmetic blocks.",
                    downloadCount = 215,
                    isBookmarked = false
                )
            )
            db.studyResourceDao().insertResources(resources)

            // Seed Campus Libraries Directory
            val libraries = listOf(
                CampusLibraryEntity(
                    id = "balme_main",
                    name = "Balme Main Library",
                    campusZone = "Central Campus",
                    totalCapacity = 1200,
                    availableSeats = 342,
                    openingHoursWeekdays = "07:30 AM - 10:00 PM",
                    openingHoursWeekends = "09:00 AM - 08:00 PM",
                    openingHoursExams = "24/7 Continuous Study Mode",
                    isOpenNow = true,
                    currentNoiseLevel = "Silent Study",
                    hasPowerSockets = true,
                    hasWiFi = true,
                    hasAirConditioning = true,
                    hasDiscussionRooms = true,
                    hasPrintingStation = true,
                    hasComputerLab = true,
                    contactPhone = "+233 30 250 0150",
                    librarianHelpDesk = "Ground Floor Main Foyer",
                    mapLocationCode = "BLM",
                    totalFloorsCount = 3,
                    description = "The premier academic research repository featuring the Africana heritage wing, digital thesis commons, and 1,200 individual study desks."
                ),
                CampusLibraryEntity(
                    id = "ugbs_library",
                    name = "UGBS Graduate Library",
                    campusZone = "Legon West / Business Wing",
                    totalCapacity = 350,
                    availableSeats = 88,
                    openingHoursWeekdays = "08:00 AM - 10:00 PM",
                    openingHoursWeekends = "09:00 AM - 06:00 PM",
                    openingHoursExams = "07:00 AM - 12:00 Midnight",
                    isOpenNow = true,
                    currentNoiseLevel = "Quiet Carrels",
                    hasPowerSockets = true,
                    hasWiFi = true,
                    hasAirConditioning = true,
                    hasDiscussionRooms = true,
                    hasPrintingStation = true,
                    hasComputerLab = true,
                    contactPhone = "+233 30 250 0165",
                    librarianHelpDesk = "1st Floor Circulation Desk",
                    mapLocationCode = "UGBS",
                    totalFloorsCount = 2,
                    description = "Business & Economics specialist collection equipped with Bloomberg financial terminals and corporate syndicate rooms."
                ),
                CampusLibraryEntity(
                    id = "law_library",
                    name = "Law School Library",
                    campusZone = "Central Campus East",
                    totalCapacity = 280,
                    availableSeats = 42,
                    openingHoursWeekdays = "08:00 AM - 10:00 PM",
                    openingHoursWeekends = "09:00 AM - 07:00 PM",
                    openingHoursExams = "24/7 Exam Revision Hours",
                    isOpenNow = true,
                    currentNoiseLevel = "Deep Silence",
                    hasPowerSockets = true,
                    hasWiFi = true,
                    hasAirConditioning = true,
                    hasDiscussionRooms = false,
                    hasPrintingStation = true,
                    hasComputerLab = false,
                    contactPhone = "+233 30 250 0180",
                    librarianHelpDesk = "Ground Floor Reference Center",
                    mapLocationCode = "LAW",
                    totalFloorsCount = 2,
                    description = "Houses supreme court law reports from 1959 to present, Commonwealth jurisprudence, and silent research cubicles."
                ),
                CampusLibraryEntity(
                    id = "science_library",
                    name = "Science & Tech Library (CS & Engineering)",
                    campusZone = "Science Enclave",
                    totalCapacity = 500,
                    availableSeats = 215,
                    openingHoursWeekdays = "07:30 AM - 09:30 PM",
                    openingHoursWeekends = "08:30 AM - 06:30 PM",
                    openingHoursExams = "24/7 Study Mode",
                    isOpenNow = true,
                    currentNoiseLevel = "Collaborative / Quiet",
                    hasPowerSockets = true,
                    hasWiFi = true,
                    hasAirConditioning = true,
                    hasDiscussionRooms = true,
                    hasPrintingStation = true,
                    hasComputerLab = true,
                    contactPhone = "+233 30 250 0192",
                    librarianHelpDesk = "Makerspace Entrance",
                    mapLocationCode = "CS",
                    totalFloorsCount = 2,
                    description = "Features dual-monitor coding stations, algorithm reference stacks, hardware makerspace benches, and high-speed fiber WiFi."
                ),
                CampusLibraryEntity(
                    id = "chs_library",
                    name = "College of Health Sciences Library",
                    campusZone = "Medical & Health Wing",
                    totalCapacity = 320,
                    availableSeats = 140,
                    openingHoursWeekdays = "08:00 AM - 10:00 PM",
                    openingHoursWeekends = "09:00 AM - 08:00 PM",
                    openingHoursExams = "24/7 Clinical Board Exam Hours",
                    isOpenNow = true,
                    currentNoiseLevel = "Silent Study",
                    hasPowerSockets = true,
                    hasWiFi = true,
                    hasAirConditioning = true,
                    hasDiscussionRooms = true,
                    hasPrintingStation = true,
                    hasComputerLab = true,
                    contactPhone = "+233 30 250 0144",
                    librarianHelpDesk = "Ground Floor Clinical Reception",
                    mapLocationCode = "CHS",
                    totalFloorsCount = 2,
                    description = "Equipped with 3D anatomical model stations, PubMed clinical terminals, medical journals archive, and silent board review desks."
                )
            )
            db.campusLibraryDao().insertLibraries(libraries)

            // Seed Multi-Level Floor Maps & Zone Allocations
            val floors = listOf(
                // Balme Library Floors
                LibraryFloorEntity(
                    libraryId = "balme_main",
                    floorNumber = 0,
                    floorName = "Ground Floor (Africana & General Reference)",
                    totalFloorSeats = 400,
                    availableFloorSeats = 115,
                    noisePolicy = "Quiet Study Only",
                    sectionsDescription = "Africana Stacks, Central Information Desk, Book Scanners, Fast-Copy Hub, Accessible Ramps",
                    powerSocketAvailabilityPercent = 90,
                    crowdStatus = "Low Density",
                    interactiveMapZones = "Africana Research Wing (Free: 45); North Lobby Carrels (Free: 30); Reference Stack Desks (Free: 25); Tech Info Kiosk (Free: 15)"
                ),
                LibraryFloorEntity(
                    libraryId = "balme_main",
                    floorNumber = 1,
                    floorName = "1st Floor (General Stacks & Tech Carrels)",
                    totalFloorSeats = 450,
                    availableFloorSeats = 132,
                    noisePolicy = "Deep Silence - Individual Carrels",
                    sectionsDescription = "Engineering & Humanities Stacks, Individual Study Carrels, High-Density Power Island, Periodicals",
                    powerSocketAvailabilityPercent = 95,
                    crowdStatus = "Moderate Density",
                    interactiveMapZones = "East Carrel Pods (Free: 48); West Stacks Desks (Free: 38); Central Quiet Pavilion (Free: 32); Laptop Charging Bar (Free: 14)"
                ),
                LibraryFloorEntity(
                    libraryId = "balme_main",
                    floorNumber = 2,
                    floorName = "2nd Floor (Silent Postgraduate & Digital Commons)",
                    totalFloorSeats = 350,
                    availableFloorSeats = 95,
                    noisePolicy = "Absolute Silence - Research Focus",
                    sectionsDescription = "Postgraduate Dissertation Desks, Computer Lab A (50 PCs), Private Seminar Rooms, Thesis Archives",
                    powerSocketAvailabilityPercent = 85,
                    crowdStatus = "Moderate Density",
                    interactiveMapZones = "Postgraduate Carrels (Free: 40); Digital Commons PC Lab (Free: 25); Thesis Reading Zone (Free: 18); Seminar Rooms 1-4 (Free: 12)"
                ),

                // UGBS Library Floors
                LibraryFloorEntity(
                    libraryId = "ugbs_library",
                    floorNumber = 0,
                    floorName = "Ground Floor (Bloomberg Lab & Syndicate Pods)",
                    totalFloorSeats = 180,
                    availableFloorSeats = 38,
                    noisePolicy = "Collaborative Discussion Permitted",
                    sectionsDescription = "Bloomberg Financial Terminals, Group Case-Study Pods, Video Presentation Rehearsal Room",
                    powerSocketAvailabilityPercent = 100,
                    crowdStatus = "High Density",
                    interactiveMapZones = "Bloomberg Trading Lab (Free: 6); Group Pods A-E (Free: 12); Open Collaboration Tables (Free: 20)"
                ),
                LibraryFloorEntity(
                    libraryId = "ugbs_library",
                    floorNumber = 1,
                    floorName = "1st Floor (Quiet Executive Study & MBA Stacks)",
                    totalFloorSeats = 170,
                    availableFloorSeats = 50,
                    noisePolicy = "Quiet Study Only",
                    sectionsDescription = "Executive Desks, MBA & PhD Dissertation Wing, Digital Financial Journals Kiosk",
                    powerSocketAvailabilityPercent = 90,
                    crowdStatus = "Moderate Density",
                    interactiveMapZones = "Executive Carrels (Free: 22); MBA Research Desks (Free: 18); Quiet Stacks (Free: 10)"
                ),

                // Law Library Floors
                LibraryFloorEntity(
                    libraryId = "law_library",
                    floorNumber = 0,
                    floorName = "Ground Floor (Supreme Court Law Reports & Moot Vault)",
                    totalFloorSeats = 150,
                    availableFloorSeats = 18,
                    noisePolicy = "Silent Study",
                    sectionsDescription = "Ghana Law Reports (1959-2025), Commonwealth Statutes, Moot Court Archive",
                    powerSocketAvailabilityPercent = 80,
                    crowdStatus = "High / Nearly Full",
                    interactiveMapZones = "Statute Carrels (Free: 8); Law Report Reading Tables (Free: 6); Moot Prep Corner (Free: 4)"
                ),
                LibraryFloorEntity(
                    libraryId = "law_library",
                    floorNumber = 1,
                    floorName = "1st Floor (Constitutional Law & Reading Desks)",
                    totalFloorSeats = 130,
                    availableFloorSeats = 24,
                    noisePolicy = "Deep Silence - No Whispering",
                    sectionsDescription = "Private Silent Cubicles, International Treaties Section, Law Journal Archive",
                    powerSocketAvailabilityPercent = 85,
                    crowdStatus = "High / Nearly Full",
                    interactiveMapZones = "Deep Silence Cubicles (Free: 12); Treaties Stacks (Free: 8); Journal Desks (Free: 4)"
                ),

                // Science & Tech Library Floors
                LibraryFloorEntity(
                    libraryId = "science_library",
                    floorNumber = 0,
                    floorName = "Ground Floor (Makerspace & Dual-Monitor Coding Lab)",
                    totalFloorSeats = 260,
                    availableFloorSeats = 120,
                    noisePolicy = "Collaborative Discussion Permitted",
                    sectionsDescription = "Hardware Prototyping Benches, Dual-Monitor Workstations, Cloud Server Cluster Kiosks",
                    powerSocketAvailabilityPercent = 100,
                    crowdStatus = "Low Density",
                    interactiveMapZones = "Dual Monitor Coding Island (Free: 45); Hardware Benches (Free: 35); Open Collab Tables (Free: 40)"
                ),
                LibraryFloorEntity(
                    libraryId = "science_library",
                    floorNumber = 1,
                    floorName = "1st Floor (Quiet Mathematics & Algorithms Stacks)",
                    totalFloorSeats = 240,
                    availableFloorSeats = 95,
                    noisePolicy = "Quiet Study Only",
                    sectionsDescription = "Whiteboard Study Pods, Algorithmic Textbooks, Ergonomic Silent Desks",
                    powerSocketAvailabilityPercent = 95,
                    crowdStatus = "Moderate Density",
                    interactiveMapZones = "Whiteboard Study Pods (Free: 30); Algorithm Stacks (Free: 40); Silent Desks (Free: 25)"
                ),

                // CHS Health Sciences Floors
                LibraryFloorEntity(
                    libraryId = "chs_library",
                    floorNumber = 0,
                    floorName = "Ground Floor (Clinical Anatomy & Medical Journals)",
                    totalFloorSeats = 160,
                    availableFloorSeats = 68,
                    noisePolicy = "Quiet Study Only",
                    sectionsDescription = "Anatomy 3D Atlases, Lancet/NEJM Collections, Medical Reference Desk",
                    powerSocketAvailabilityPercent = 85,
                    crowdStatus = "Low Density",
                    interactiveMapZones = "Anatomy Model Desks (Free: 20); Medical Journals Wing (Free: 28); Reference Area (Free: 20)"
                ),
                LibraryFloorEntity(
                    libraryId = "chs_library",
                    floorNumber = 1,
                    floorName = "1st Floor (24/7 Clinical Residency & Board Exam Room)",
                    totalFloorSeats = 160,
                    availableFloorSeats = 72,
                    noisePolicy = "Deep Silence",
                    sectionsDescription = "24/7 Clinical Board Prep Desks, Private Lockers, High-Output Daylight Lamps",
                    powerSocketAvailabilityPercent = 90,
                    crowdStatus = "Moderate Density",
                    interactiveMapZones = "Board Exam Desks (Free: 38); Private Lockered Carrels (Free: 22); Silent Daylight Reading (Free: 12)"
                )
            )
            db.campusLibraryDao().insertFloors(floors)

            // Seed Academic Schedule Events (Classes, Exams, Study Sessions, Labs)
            val academicEvents = listOf(
                AcademicScheduleEventEntity(
                    title = "Software Engineering Principles Lecture",
                    courseCode = "CSCD 302",
                    eventType = "CLASS",
                    dayOfWeek = 1,
                    eventDate = null,
                    startTime = "08:30",
                    endTime = "10:30",
                    venue = "KAB 1 (Kwame Nkrumah Complex)",
                    campusLocationCode = "KAB",
                    instructorOrLead = "Dr. K. Mensah",
                    notes = "Agile development paradigms and architectural design patterns.",
                    colorHex = 0xFF0284C7,
                    reminderMinutesBefore = 15,
                    isAlarmEnabled = true,
                    isRecurring = true,
                    priority = "NORMAL"
                ),
                AcademicScheduleEventEntity(
                    title = "Calculus & Multivariable Analysis Exam",
                    courseCode = "MATH 223",
                    eventType = "EXAM",
                    dayOfWeek = null,
                    eventDate = "2026-08-25",
                    startTime = "14:00",
                    endTime = "17:00",
                    venue = "Great Hall (Main Auditorium)",
                    campusLocationCode = "GH",
                    instructorOrLead = "Prof. S. Osei",
                    notes = "Calculators allowed. Bring student identification card.",
                    colorHex = 0xFFDC2626,
                    reminderMinutesBefore = 30,
                    isAlarmEnabled = true,
                    isRecurring = false,
                    priority = "HIGH"
                ),
                AcademicScheduleEventEntity(
                    title = "Operating Systems Kernel Study Session",
                    courseCode = "CSCD 311",
                    eventType = "STUDY_SESSION",
                    dayOfWeek = 3,
                    eventDate = "2026-08-20",
                    startTime = "16:00",
                    endTime = "18:30",
                    venue = "Balme Library - Discussion Pod 2",
                    campusLocationCode = "BLM",
                    instructorOrLead = "Kwame & Sarah Study Group",
                    notes = "Semaphore synchronization algorithms & deadlock avoidance problems.",
                    colorHex = 0xFF059669,
                    reminderMinutesBefore = 20,
                    isAlarmEnabled = true,
                    isRecurring = false,
                    priority = "NORMAL"
                ),
                AcademicScheduleEventEntity(
                    title = "Database Systems Hands-on Practical Lab",
                    courseCode = "CSCD 314",
                    eventType = "LAB",
                    dayOfWeek = 4,
                    eventDate = null,
                    startTime = "13:30",
                    endTime = "15:30",
                    venue = "NNB Lab 3 (New Natural Science)",
                    campusLocationCode = "NNB",
                    instructorOrLead = "Ing. D. Abbey",
                    notes = "PostgreSQL indexing and EXPLAIN ANALYZE query tuning.",
                    colorHex = 0xFFD97706,
                    reminderMinutesBefore = 15,
                    isAlarmEnabled = true,
                    isRecurring = true,
                    priority = "NORMAL"
                ),
                AcademicScheduleEventEntity(
                    title = "Late Night Deep Revision: Data Structures & Graphs",
                    courseCode = "CSCD 205",
                    eventType = "STUDY_SESSION",
                    dayOfWeek = 5,
                    eventDate = "2026-08-22",
                    startTime = "19:00",
                    endTime = "22:00",
                    venue = "UGBS Graduate Library - 1st Floor Carrels",
                    campusLocationCode = "UGBS",
                    instructorOrLead = "Individual Silent Study",
                    notes = "Dijkstra, A*, and Minimum Spanning Trees exercises.",
                    colorHex = 0xFF7C3AED,
                    reminderMinutesBefore = 15,
                    isAlarmEnabled = true,
                    isRecurring = false,
                    priority = "NORMAL"
                )
            )
            db.academicScheduleEventDao().insertEvents(academicEvents)
        }
    }
}
