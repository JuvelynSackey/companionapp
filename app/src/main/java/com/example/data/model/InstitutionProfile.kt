package com.example.data.model

import com.example.data.local.entity.CampusLocationEntity
import com.example.data.local.entity.CourseScheduleEntity
import com.example.data.local.entity.ExamScheduleEntity

enum class GradingSystemType {
    GPA_4_0,       // UG, Ashesi, UCC (Letter grades 4.0 scale)
    KNUST_CWA,     // KNUST (Cumulative Weighted Average percentage 0-100%)
    SCALE_5_0,     // Technical Universities (5.0 scale)
    SCALE_4_3      // 4.3 Scale
}

data class HonoursThreshold(
    val title: String,
    val minScore: Double,
    val maxScore: Double,
    val colorHex: Long,
    val description: String = ""
)

data class InstitutionPortal(
    val id: String,
    val name: String,
    val description: String,
    val url: String,
    val category: String, // "LMS & Virtual Class", "Student Records / SIS", "Library & E-Resources", "Payments & Services"
    val iconType: String = "school"
)

data class InstitutionCampusZone(
    val id: String,
    val name: String,
    val shortCode: String,
    val description: String
)

data class InstitutionProfile(
    val id: String,
    val name: String,
    val shortCode: String,
    val motto: String,
    val city: String,
    val region: String,
    val country: String = "Ghana",
    val primaryColorHex: Long,
    val secondaryColorHex: Long,
    val accentColorHex: Long,
    val gradingSystem: GradingSystemType,
    val gradingMetricName: String,
    val honoursThresholds: List<HonoursThreshold>,
    val portals: List<InstitutionPortal>,
    val campusZones: List<InstitutionCampusZone>,
    val defaultLocations: List<CampusLocationEntity>,
    val sampleSchedules: List<CourseScheduleEntity>,
    val sampleExams: List<ExamScheduleEntity>,
    val studentPortalName: String,
    val lmsName: String,
    val libraryName: String,
    val isCustom: Boolean = false
)

object InstitutionRegistry {

    val UG_PROFILE = InstitutionProfile(
        id = "ug_legon",
        name = "University of Ghana",
        shortCode = "UG",
        motto = "Integri Procedamus (Proceed with Integrity)",
        city = "Legon, Accra",
        region = "Greater Accra",
        country = "Ghana",
        primaryColorHex = 0xFF1E3A8A, // Deep Academic Blue
        secondaryColorHex = 0xFFD97706, // Academic Gold
        accentColorHex = 0xFFDC2626, // Crimson
        gradingSystem = GradingSystemType.GPA_4_0,
        gradingMetricName = "GPA (4.0 Scale)",
        honoursThresholds = listOf(
            HonoursThreshold("First Class Honours", 3.60, 4.00, 0xFF10B981, "GPA >= 3.60"),
            HonoursThreshold("Second Class (Upper)", 3.00, 3.59, 0xFF3B82F6, "3.00 - 3.59 GPA"),
            HonoursThreshold("Second Class (Lower)", 2.00, 2.99, 0xFFF59E0B, "2.00 - 2.99 GPA"),
            HonoursThreshold("Third Class", 1.50, 1.99, 0xFFF97316, "1.50 - 1.99 GPA"),
            HonoursThreshold("Pass", 1.00, 1.49, 0xFF6B7280, "1.00 - 1.49 GPA"),
            HonoursThreshold("Fail", 0.00, 0.99, 0xFFEF4444, "GPA < 1.00")
        ),
        portals = listOf(
            InstitutionPortal("ug_sakai", "Sakai LMS", "Course materials, lecture slides, assignments & quiz submissions", "https://sakai.ug.edu.gh", "LMS & Virtual Class", "school"),
            InstitutionPortal("ug_mis", "MIS Web Portal", "Semester registration, grades slip, fees statement & student profile", "https://misweb.ug.edu.gh", "Student Records / SIS", "badge"),
            InstitutionPortal("ug_sts", "STS Portal", "Student Teaching and Lecturer Assessment System", "https://sts.ug.edu.gh", "Student Records / SIS", "rate_review"),
            InstitutionPortal("ug_balme", "Balme Digital Library", "UGRIS digital repository, e-journals, research theses & past questions", "http://balme.ug.edu.gh", "Library & E-Resources", "local_library")
        ),
        campusZones = listOf(
            InstitutionCampusZone("ug_central", "Central Campus", "CC", "Balme, Great Hall, Registry, JQB"),
            InstitutionCampusZone("ug_sciences", "Science Quadrangle", "SCI", "KAB, Chemistry, Physics, Math, CompSci"),
            InstitutionCampusZone("ug_diaspora", "Diaspora & Hostels", "HOSTEL", "Pentagon, TF, Evandy, Bani, Commonwealth"),
            InstitutionCampusZone("ug_law_ugbs", "Professional Quadrants", "BUS/LAW", "UGBS, School of Law, Cedi Conference")
        ),
        defaultLocations = listOf(
            CampusLocationEntity(
                id = "BLM",
                name = "Balme Library Complex",
                shortCode = "BLM",
                category = "Library",
                mapX = 50f,
                mapY = 48f,
                description = "The main academic research repository of University of Ghana. Features Africana library, quiet study carrels, and 24-hour reading rooms.",
                floors = 3,
                walkingTimeFromHostelMinutes = 8,
                popularVenuesInside = "Ground Floor Africana, 1st Floor Stacks, Tech Hub Carrels"
            ),
            CampusLocationEntity(
                id = "KAB",
                name = "Kwame Nkrumah Complex (KAB)",
                shortCode = "KAB",
                category = "Lecture Hall",
                mapX = 35f,
                mapY = 32f,
                description = "Primary multi-tier amphitheatre complex for Computer Science, Mathematics, and Engineering lectures.",
                floors = 3,
                walkingTimeFromHostelMinutes = 12,
                popularVenuesInside = "KAB 1 (Main Amphitheatre), KAB 2, KAB Lab 3"
            ),
            CampusLocationEntity(
                id = "JQB",
                name = "Jones Quartey Building (JQB)",
                shortCode = "JQB",
                category = "Lecture Hall",
                mapX = 65f,
                mapY = 38f,
                description = "Social sciences and humanities lecture halls with central audio systems.",
                floors = 2,
                walkingTimeFromHostelMinutes = 10,
                popularVenuesInside = "JQB 19, JQB 22, JQB 09"
            ),
            CampusLocationEntity(
                id = "GH",
                name = "The Great Hall",
                shortCode = "GH",
                category = "Examination Center",
                mapX = 50f,
                mapY = 20f,
                description = "Iconic university auditorium for matriculation, congregation ceremonies, and end-of-semester final examinations.",
                floors = 2,
                walkingTimeFromHostelMinutes = 15,
                popularVenuesInside = "Main Auditorium, Great Hall Annex"
            ),
            CampusLocationEntity(
                id = "CC",
                name = "Central Cafeteria & Student Union",
                shortCode = "CC",
                category = "Cafeteria & Food",
                mapX = 42f,
                mapY = 60f,
                description = "Central dining, convenience stores, photocopy center, and campus banking hubs.",
                floors = 2,
                walkingTimeFromHostelMinutes = 5,
                popularVenuesInside = "Main Food Court, SRC Union Office, Campus Bookshop"
            )
        ),
        sampleSchedules = listOf(
            CourseScheduleEntity(1, "CSCD 302", "Software Engineering Principles", "Dr. K. Mensah", 1, "08:30", "10:30", "KAB 1 (Kwame Nkrumah)", 3, 0xFF0284C7),
            CourseScheduleEntity(2, "CSCD 304", "Computer Networks & Telecom", "Prof. S. Osei", 2, "11:30", "13:30", "JQB 22 (Jones Quartey)", 3, 0xFF0D9488),
            CourseScheduleEntity(3, "CSCD 306", "Database Systems Design", "Dr. A. Addo", 3, "09:30", "11:30", "KAB Lab 3", 3, 0xFF7C3AED),
            CourseScheduleEntity(4, "MATH 354", "Linear Abstract Algebra", "Dr. E. Coffie", 4, "13:30", "15:30", "NNB 1 (New Science Block)", 3, 0xFFEA580C)
        ),
        sampleExams = listOf(
            ExamScheduleEntity(1, "CSCD 302", "Software Engineering", "2026-09-08", "09:00", "12:00", "KAB 1", "Index 10920001 - 10920150", 3, "Dr. K. Mensah", 12, "08:35"),
            ExamScheduleEntity(2, "CSCD 304", "Computer Networks", "2026-09-12", "14:00", "17:00", "Great Hall Annex", "Index 10920001 - 10920150", 3, "Prof. S. Osei", 15, "13:30"),
            ExamScheduleEntity(3, "CSCD 306", "Database Systems", "2026-09-16", "09:00", "12:00", "JQB 19", "Index 10920001 - 10920150", 3, "Dr. A. Addo", 10, "08:40")
        ),
        studentPortalName = "MIS Web",
        lmsName = "Sakai LMS",
        libraryName = "Balme Library"
    )

    val KNUST_PROFILE = InstitutionProfile(
        id = "knust_kumasi",
        name = "Kwame Nkrumah Univ. of Science & Tech",
        shortCode = "KNUST",
        motto = "Nyansapɔw Wɔsane No Badwemma (The knot of wisdom is untied only by the wise)",
        city = "Kumasi",
        region = "Ashanti Region",
        country = "Ghana",
        primaryColorHex = 0xFFB45309, // KNUST Gold
        secondaryColorHex = 0xFF15803D, // Forest Green
        accentColorHex = 0xFF881337, // Maroon
        gradingSystem = GradingSystemType.KNUST_CWA,
        gradingMetricName = "CWA (Cumulative Weighted Average %)",
        honoursThresholds = listOf(
            HonoursThreshold("First Class Honours", 70.0, 100.0, 0xFF10B981, "CWA >= 70.0%"),
            HonoursThreshold("Second Class (Upper)", 60.0, 69.99, 0xFF3B82F6, "60.0% - 69.9% CWA"),
            HonoursThreshold("Second Class (Lower)", 50.0, 59.99, 0xFFF59E0B, "50.0% - 59.9% CWA"),
            HonoursThreshold("Pass", 40.0, 49.99, 0xFFF97316, "40.0% - 49.9% CWA"),
            HonoursThreshold("Fail / Trail", 0.0, 39.99, 0xFFEF4444, "CWA < 40.0%")
        ),
        portals = listOf(
            InstitutionPortal("knust_vclass", "Virtual Classroom (VClass)", "KNUST official online learning portal and lecture materials", "https://vclass.knust.edu.gh", "LMS & Virtual Class", "school"),
            InstitutionPortal("knust_aim", "AIM Student App Portal", "Academic Information Manager: course registration, results & fees", "https://apps.knust.edu.gh/students", "Student Records / SIS", "badge"),
            InstitutionPortal("knust_mail", "KNUST Student Webmail", "Official university communication and notifications", "https://mail.knust.edu.gh", "Student Records / SIS", "mail"),
            InstitutionPortal("knust_prempeh", "Prempeh II Digital Library", "E-Repository, science publications, and research archives", "https://library.knust.edu.gh", "Library & E-Resources", "local_library")
        ),
        campusZones = listOf(
            InstitutionCampusZone("knust_central", "Central & Administration", "MAIN", "Great Hall, Prempeh II Library, Reg Office"),
            InstitutionCampusZone("knust_coe", "College of Engineering", "COE", "Petroleum Building, Civil, Electrical Labs"),
            InstitutionCampusZone("knust_cos", "College of Science", "COS", "Allotey Complex, Physics, Bio & Optometry"),
            InstitutionCampusZone("knust_halls", "Traditional & Unity Halls", "HALLS", "Unity Hall (Conti), Katanga, Queen's, Africa")
        ),
        defaultLocations = listOf(
            CampusLocationEntity(
                id = "PREMPEH",
                name = "Prempeh II Memorial Library",
                shortCode = "PLIB",
                category = "Library",
                mapX = 48f,
                mapY = 45f,
                description = "Central university library housing over 300,000 volumes, postgraduate research wing, and electronic journals hub.",
                floors = 4,
                walkingTimeFromHostelMinutes = 10,
                popularVenuesInside = "Ground Floor Reading Hall, Science Stacks, Tech Commons"
            ),
            CampusLocationEntity(
                id = "COE_AUD",
                name = "College of Engineering Complex",
                shortCode = "COE",
                category = "Lecture Hall",
                mapX = 30f,
                mapY = 35f,
                description = "Ultra-modern engineering auditoriums, simulation laboratories, and design workshops.",
                floors = 4,
                walkingTimeFromHostelMinutes = 14,
                popularVenuesInside = "Petroleum Aud 1, Electrical Lab 2, New Engineering Block"
            ),
            CampusLocationEntity(
                id = "COS_ALLOTEY",
                name = "Prof. Allotey Science Complex",
                shortCode = "COS",
                category = "Laboratory",
                mapX = 65f,
                mapY = 40f,
                description = "Faculty of Physical and Computational Sciences, computer laboratories, and lecture auditoriums.",
                floors = 3,
                walkingTimeFromHostelMinutes = 12,
                popularVenuesInside = "Allotey Hall, Physics Lab B, CompSci Lab 1"
            ),
            CampusLocationEntity(
                id = "KNUST_GH",
                name = "KNUST Great Hall",
                shortCode = "KGH",
                category = "Examination Center",
                mapX = 52f,
                mapY = 22f,
                description = "Grand amphitheatre for major university congregational examinations and ceremonies.",
                floors = 2,
                walkingTimeFromHostelMinutes = 15,
                popularVenuesInside = "Great Hall Main Floor, Balcony Exam Center"
            ),
            CampusLocationEntity(
                id = "COMMERCIAL",
                name = "Commercial Area & Banking Square",
                shortCode = "COMM",
                category = "Cafeteria & Food",
                mapX = 45f,
                mapY = 62f,
                description = "The bustling commercial hub of KNUST with dining joints, banks, pharmacy, and print shops.",
                floors = 2,
                walkingTimeFromHostelMinutes = 6,
                popularVenuesInside = "Royal Feast, Banking Alley, KNUST Bookshop"
            )
        ),
        sampleSchedules = listOf(
            CourseScheduleEntity(1, "COE 382", "Embedded Systems Design", "Prof. E. Kwesi", 1, "08:00", "10:00", "COE Petroleum Aud", 3, 0xFFB45309),
            CourseScheduleEntity(2, "CS 358", "Algorithm Analysis & Complexity", "Dr. Y. Boakye", 2, "10:30", "12:30", "Allotey Complex Hall 2", 3, 0xFF15803D),
            CourseScheduleEntity(3, "MATH 352", "Numerical Analysis for Engineers", "Dr. G. Arthur", 3, "13:00", "15:00", "New Engineering Block 102", 3, 0xFF0284C7),
            CourseScheduleEntity(4, "TE 364", "Wireless Communications", "Prof. J. Annan", 4, "08:00", "10:00", "Electrical Lab Amphitheatre", 3, 0xFF881337)
        ),
        sampleExams = listOf(
            ExamScheduleEntity(1, "COE 382", "Embedded Systems", "2026-09-09", "08:30", "11:30", "COE Petroleum Aud", "Index 20450001 - 20450200", 3, "Prof. E. Kwesi", 14, "08:05"),
            ExamScheduleEntity(2, "CS 358", "Algorithm Analysis", "2026-09-14", "13:30", "16:30", "KNUST Great Hall", "Index 20450001 - 20450200", 3, "Dr. Y. Boakye", 15, "13:05"),
            ExamScheduleEntity(3, "MATH 352", "Numerical Analysis", "2026-09-18", "08:30", "11:30", "Allotey Complex Hall 1", "Index 20450001 - 20450200", 3, "Dr. G. Arthur", 12, "08:05")
        ),
        studentPortalName = "AIM Portal",
        lmsName = "VClass (Virtual Classroom)",
        libraryName = "Prempeh II Library"
    )

    val ASHESI_PROFILE = InstitutionProfile(
        id = "ashesi_berekuso",
        name = "Ashesi University",
        shortCode = "ASHESI",
        motto = "Scholarship, Leadership, Citizenship",
        city = "Berekuso",
        region = "Eastern Region",
        country = "Ghana",
        primaryColorHex = 0xFF991B1B, // Ashesi Crimson/Maroon
        secondaryColorHex = 0xFFD97706, // Warm Ochre
        accentColorHex = 0xFF0F766E, // Teal
        gradingSystem = GradingSystemType.GPA_4_0,
        gradingMetricName = "GPA (4.0 Scale)",
        honoursThresholds = listOf(
            HonoursThreshold("Summa Cum Laude", 3.85, 4.00, 0xFF10B981, "GPA >= 3.85"),
            HonoursThreshold("Magna Cum Laude", 3.70, 3.84, 0xFF3B82F6, "3.70 - 3.84 GPA"),
            HonoursThreshold("Cum Laude", 3.50, 3.69, 0xFF8B5CF6, "3.50 - 3.69 GPA"),
            HonoursThreshold("Good Standing", 2.50, 3.49, 0xFFF59E0B, "2.50 - 3.49 GPA"),
            HonoursThreshold("Academic Warning", 2.00, 2.49, 0xFFF97316, "2.00 - 2.49 GPA"),
            HonoursThreshold("Probation / Fail", 0.00, 1.99, 0xFFEF4444, "GPA < 2.00")
        ),
        portals = listOf(
            InstitutionPortal("ashesi_canvas", "Canvas LMS", "Assignments, lecture discussions, and gradebook updates", "https://ashesi.instructure.com", "LMS & Virtual Class", "school"),
            InstitutionPortal("ashesi_sis", "Ashesi SIS Portal", "Course registration, degree audits, and financial account ledger", "https://sis.ashesi.edu.gh", "Student Records / SIS", "badge"),
            InstitutionPortal("ashesi_lib", "Todd & Diana Berman Library", "EBSCO, JSTOR, IEEE research databases, and archives", "https://library.ashesi.edu.gh", "Library & E-Resources", "local_library"),
            InstitutionPortal("ashesi_career", "Career & Internship Hub", "Resume reviews, campus recruitment, and alumni mentoring", "https://careers.ashesi.edu.gh", "Payments & Services", "work")
        ),
        campusZones = listOf(
            InstitutionCampusZone("ashesi_academic", "Academic Quad", "ACAD", "Norton-Motulsky Hall, Fab Lab, Archer Courtyard"),
            InstitutionCampusZone("ashesi_hive", "Innovation & Tech Hub", "HIVE", "Hive Labs, Robotics Alley, Maker Space"),
            InstitutionCampusZone("ashesi_housing", "Residential Commons", "HOUSING", "Oteng Korankye, Wangari Maathai, Berekuso Hall")
        ),
        defaultLocations = listOf(
            CampusLocationEntity(
                id = "BERMAN_LIB",
                name = "Todd & Diana Berman Library",
                shortCode = "LIB",
                category = "Library",
                mapX = 50f,
                mapY = 42f,
                description = "Modern collaborative learning center with breakout pods, digital carrels, and scenic views of the Berekuso hills.",
                floors = 2,
                walkingTimeFromHostelMinutes = 4,
                popularVenuesInside = "Quiet Study Wing, Discussion Pods A-D, Tech Help Desk"
            ),
            CampusLocationEntity(
                id = "NORTON",
                name = "Norton-Motulsky Academic Hall",
                shortCode = "NMH",
                category = "Lecture Hall",
                mapX = 38f,
                mapY = 32f,
                description = "Primary multidisciplinary lecture auditoriums with smart presentation systems.",
                floors = 3,
                walkingTimeFromHostelMinutes = 5,
                popularVenuesInside = "NMH 101, NMH 203, Computer Science Lab"
            ),
            CampusLocationEntity(
                id = "FAB_LAB",
                name = "Engineering Fab Lab & Hive",
                shortCode = "HIVE",
                category = "Laboratory",
                mapX = 62f,
                mapY = 35f,
                description = "State-of-the-art 3D printing, laser fabrication, and hardware prototyping workspace.",
                floors = 2,
                walkingTimeFromHostelMinutes = 6,
                popularVenuesInside = "Robotics Lab, 3D Print Studio, Electronics Bay"
            ),
            CampusLocationEntity(
                id = "COURTYARD",
                name = "Archer-Cornfield Courtyard & Cafeteria",
                shortCode = "CAFE",
                category = "Cafeteria & Food",
                mapX = 50f,
                mapY = 60f,
                description = "The central social and dining hub overlooking the picturesque Eastern Region valleys.",
                floors = 1,
                walkingTimeFromHostelMinutes = 3,
                popularVenuesInside = "Main Dining Terrace, Student Lounge, Juice Bar"
            )
        ),
        sampleSchedules = listOf(
            CourseScheduleEntity(1, "CS 312", "Data Structures & Algorithms", "Dr. David Sampah", 1, "09:00", "10:30", "NMH 203", 3, 0xFF991B1B),
            CourseScheduleEntity(2, "CS 435", "Human-Computer Interaction", "Dr. Nathan Amanquah", 2, "11:00", "12:30", "Fab Lab Innovation Room", 3, 0xFF0F766E),
            CourseScheduleEntity(3, "SO 211", "Leadership Seminar 3", "Dr. Angela Owusu", 3, "13:30", "15:00", "NMH 101 Amphitheatre", 3, 0xFFD97706),
            CourseScheduleEntity(4, "MATH 221", "Discrete Mathematics", "Prof. Stephen Armah", 4, "09:00", "10:30", "Berman Tech Wing", 3, 0xFF1E3A8A)
        ),
        sampleExams = listOf(
            ExamScheduleEntity(1, "CS 312", "Data Structures", "2026-09-10", "09:00", "12:00", "NMH 101 Amphitheatre", "Class of 2027", 3, "Dr. David Sampah", 5, "08:45"),
            ExamScheduleEntity(2, "CS 435", "HCI & UI Systems", "2026-09-15", "14:00", "17:00", "Fab Lab Main Hall", "Class of 2027", 3, "Dr. Nathan Amanquah", 6, "13:45"),
            ExamScheduleEntity(3, "SO 211", "Leadership Final", "2026-09-19", "09:00", "12:00", "Berman Library Pod A", "Class of 2027", 3, "Dr. Angela Owusu", 4, "08:50")
        ),
        studentPortalName = "Ashesi SIS",
        lmsName = "Canvas LMS",
        libraryName = "Berman Library"
    )

    val UCC_PROFILE = InstitutionProfile(
        id = "ucc_capecoast",
        name = "University of Cape Coast",
        shortCode = "UCC",
        motto = "Veritas Nobis Lumen (Truth, Our Guide)",
        city = "Cape Coast",
        region = "Central Region",
        country = "Ghana",
        primaryColorHex = 0xFF1D4ED8, // UCC Royal Blue
        secondaryColorHex = 0xFFBE123C, // Cardinal Red
        accentColorHex = 0xFFEAB308, // Gold
        gradingSystem = GradingSystemType.GPA_4_0,
        gradingMetricName = "GPA (4.0 Scale)",
        honoursThresholds = listOf(
            HonoursThreshold("First Class Honours", 3.60, 4.00, 0xFF10B981, "GPA >= 3.60"),
            HonoursThreshold("Second Class (Upper)", 3.00, 3.59, 0xFF3B82F6, "3.00 - 3.59 GPA"),
            HonoursThreshold("Second Class (Lower)", 2.00, 2.99, 0xFFF59E0B, "2.00 - 2.99 GPA"),
            HonoursThreshold("Third Class", 1.50, 1.99, 0xFFF97316, "1.50 - 1.99 GPA"),
            HonoursThreshold("Pass", 1.00, 1.49, 0xFF6B7280, "1.00 - 1.49 GPA"),
            HonoursThreshold("Fail", 0.00, 0.99, 0xFFEF4444, "GPA < 1.00")
        ),
        portals = listOf(
            InstitutionPortal("ucc_moodle", "UCC Moodle LMS", "Official course repository, e-quizzes, and lecture modules", "https://moodle.ucc.edu.gh", "LMS & Virtual Class", "school"),
            InstitutionPortal("ucc_osis", "UCC OSIS Portal", "Online Student Information System for registration and results", "https://osis.ucc.edu.gh", "Student Records / SIS", "badge"),
            InstitutionPortal("ucc_jonah", "Sam Jonah E-Library", "Research papers, past question bank, and journal databases", "https://library.ucc.edu.gh", "Library & E-Resources", "local_library")
        ),
        campusZones = listOf(
            InstitutionCampusZone("ucc_old", "Old Site (North Campus)", "NORTH", "Auditorium 900, Science Block, Casely Hayford"),
            InstitutionCampusZone("ucc_new", "New Site (South Campus)", "SOUTH", "Sam Jonah Library, FELT, New Examination Center, Valco")
        ),
        defaultLocations = listOf(
            CampusLocationEntity(
                id = "SAM_JONAH",
                name = "Sam Jonah Central Library",
                shortCode = "SJL",
                category = "Library",
                mapX = 52f,
                mapY = 46f,
                description = "UCC flagship 6-storey research library with extensive reference and electronic learning resources.",
                floors = 6,
                walkingTimeFromHostelMinutes = 9,
                popularVenuesInside = "Africana Wing, 2nd Floor General Stacks, E-Learning Hub"
            ),
            CampusLocationEntity(
                id = "AUD_900",
                name = "Auditorium 900 & Lecture Complex",
                shortCode = "AUD900",
                category = "Lecture Hall",
                mapX = 36f,
                mapY = 34f,
                description = "Major 900-seat amphitheatre for cross-faculty university lectures.",
                floors = 2,
                walkingTimeFromHostelMinutes = 11,
                popularVenuesInside = "Main Auditorium 900, LT 1, LT 2"
            ),
            CampusLocationEntity(
                id = "UCC_NEC",
                name = "New Examination Center (NEC)",
                shortCode = "NEC",
                category = "Examination Center",
                mapX = 64f,
                mapY = 38f,
                description = "Dedicated air-conditioned hall constructed specifically for university-wide end-of-semester exams.",
                floors = 3,
                walkingTimeFromHostelMinutes = 14,
                popularVenuesInside = "NEC Hall A, NEC Hall B, NEC Hall C"
            )
        ),
        sampleSchedules = listOf(
            CourseScheduleEntity(1, "INF 311", "Web Technologies & Systems", "Dr. F. Baidoo", 1, "08:30", "10:30", "Auditorium 900", 3, 0xFF1D4ED8),
            CourseScheduleEntity(2, "CSC 321", "Operating Systems Internals", "Prof. C. Mensah", 2, "11:30", "13:30", "FELT Lab 1", 3, 0xFFBE123C),
            CourseScheduleEntity(3, "MAT 301", "Real Analysis for Computing", "Dr. S. Kwofie", 3, "08:30", "10:30", "Science Block LT", 3, 0xFFEAB308)
        ),
        sampleExams = listOf(
            ExamScheduleEntity(1, "INF 311", "Web Technologies", "2026-09-11", "09:00", "12:00", "New Examination Center (NEC)", "Index 30910001 - 30910200", 3, "Dr. F. Baidoo", 14, "08:35"),
            ExamScheduleEntity(2, "CSC 321", "Operating Systems", "2026-09-15", "14:00", "17:00", "Auditorium 900", "Index 30910001 - 30910200", 3, "Prof. C. Mensah", 11, "13:35")
        ),
        studentPortalName = "UCC OSIS",
        lmsName = "UCC Moodle",
        libraryName = "Sam Jonah Library"
    )

    val GIMPA_PROFILE = InstitutionProfile(
        id = "gimpa_greenhill",
        name = "GIMPA (Greenhill)",
        shortCode = "GIMPA",
        motto = "Excellence in Leadership, Management and Administration",
        city = "Greenhill, Accra",
        region = "Greater Accra",
        country = "Ghana",
        primaryColorHex = 0xFF047857, // GIMPA Emerald Green
        secondaryColorHex = 0xFFCA8A04, // Deep Gold
        accentColorHex = 0xFF1E293B, // Slate Navy
        gradingSystem = GradingSystemType.GPA_4_0,
        gradingMetricName = "GPA (4.0 Scale)",
        honoursThresholds = listOf(
            HonoursThreshold("First Class Honours", 3.60, 4.00, 0xFF10B981, "GPA >= 3.60"),
            HonoursThreshold("Second Class (Upper)", 3.00, 3.59, 0xFF3B82F6, "3.00 - 3.59 GPA"),
            HonoursThreshold("Second Class (Lower)", 2.00, 2.99, 0xFFF59E0B, "2.00 - 2.99 GPA"),
            HonoursThreshold("Third Class", 1.50, 1.99, 0xFFF97316, "1.50 - 1.99 GPA"),
            HonoursThreshold("Pass", 1.00, 1.49, 0xFF6B7280, "1.00 - 1.49 GPA"),
            HonoursThreshold("Fail", 0.00, 0.99, 0xFFEF4444, "GPA < 1.00")
        ),
        portals = listOf(
            InstitutionPortal("gimpa_erp", "GIMPA ERP Portal", "Student ERP for course registration, fee receipts & results", "https://erp.gimpa.edu.gh", "Student Records / SIS", "badge"),
            InstitutionPortal("gimpa_moodle", "GIMPA Moodle", "Virtual classes and postgraduate executive assignments", "https://moodle.gimpa.edu.gh", "LMS & Virtual Class", "school"),
            InstitutionPortal("gimpa_lib", "Greenhill Digital Library", "Public administration, governance, and business journals", "https://library.gimpa.edu.gh", "Library & E-Resources", "local_library")
        ),
        campusZones = listOf(
            InstitutionCampusZone("gimpa_main", "Greenhill Quadrangle", "MAIN", "Business School, Law Faculty, Main Library"),
            InstitutionCampusZone("gimpa_exec", "Executive Training Center", "EXEC", "Executive Conference Center, Masters Suites")
        ),
        defaultLocations = listOf(
            CampusLocationEntity(
                id = "GIMPA_LIB",
                name = "Greenhill Central Library",
                shortCode = "GLIB",
                category = "Library",
                mapX = 50f,
                mapY = 45f,
                description = "Modern library with focus on law, public administration, leadership, and management.",
                floors = 3,
                walkingTimeFromHostelMinutes = 6,
                popularVenuesInside = "Executive Reference Room, Law Reserve, E-Lab"
            ),
            CampusLocationEntity(
                id = "GIMPA_BS",
                name = "GIMPA Business School",
                shortCode = "GBS",
                category = "Lecture Hall",
                mapX = 35f,
                mapY = 35f,
                description = "Case-study style lecture rooms with high-speed presentation setups.",
                floors = 3,
                walkingTimeFromHostelMinutes = 8,
                popularVenuesInside = "Amphitheatre 1, Seminar Room 3"
            )
        ),
        sampleSchedules = listOf(
            CourseScheduleEntity(1, "MIS 701", "Enterprise Information Systems", "Dr. K. Antwi", 1, "17:30", "20:30", "GBS Amphitheatre 1", 3, 0xFF047857),
            CourseScheduleEntity(2, "PAD 703", "Public Policy Analysis", "Prof. M. Bempong", 2, "17:30", "20:30", "Executive Room 102", 3, 0xFFCA8A04)
        ),
        sampleExams = listOf(
            ExamScheduleEntity(1, "MIS 701", "Enterprise Systems", "2026-09-12", "18:00", "21:00", "GBS Amphitheatre 1", "MBA Evening Cohort", 3, "Dr. K. Antwi", 8, "17:40")
        ),
        studentPortalName = "GIMPA ERP",
        lmsName = "GIMPA Moodle",
        libraryName = "Greenhill Library"
    )

    val UEW_PROFILE = InstitutionProfile(
        id = "uew_winneba",
        name = "University of Education, Winneba",
        shortCode = "UEW",
        motto = "Education for Service",
        city = "Winneba",
        region = "Central Region",
        country = "Ghana",
        primaryColorHex = 0xFF831843, // UEW Deep Maroon / Wine
        secondaryColorHex = 0xFFF59E0B, // Academic Gold
        accentColorHex = 0xFF1E3A8A, // Deep Blue
        gradingSystem = GradingSystemType.GPA_4_0,
        gradingMetricName = "GPA (4.0 Scale)",
        honoursThresholds = listOf(
            HonoursThreshold("First Class Honours", 3.60, 4.00, 0xFF10B981, "GPA >= 3.60"),
            HonoursThreshold("Second Class (Upper)", 3.00, 3.59, 0xFF3B82F6, "3.00 - 3.59 GPA"),
            HonoursThreshold("Second Class (Lower)", 2.00, 2.99, 0xFFF59E0B, "2.00 - 2.99 GPA"),
            HonoursThreshold("Third Class", 1.50, 1.99, 0xFFF97316, "1.50 - 1.99 GPA"),
            HonoursThreshold("Pass", 1.00, 1.49, 0xFF6B7280, "1.00 - 1.49 GPA"),
            HonoursThreshold("Fail", 0.00, 0.99, 0xFFEF4444, "GPA < 1.00")
        ),
        portals = listOf(
            InstitutionPortal("uew_its", "UEW OSIS / ITS Portal", "Course registration, fee slips and semester examination results", "https://osis.uew.edu.gh", "Student Records / SIS", "badge"),
            InstitutionPortal("uew_lms", "UEW VClass LMS", "Virtual learning environment, module materials & lecture submissions", "https://vclass.uew.edu.gh", "LMS & Virtual Class", "school"),
            InstitutionPortal("uew_lib", "Osagyefo Library", "Institutional repository, educational journals & past papers", "https://library.uew.edu.gh", "Library & E-Resources", "local_library")
        ),
        campusZones = listOf(
            InstitutionCampusZone("uew_north", "North Campus", "NORTH", "Faculty of Science, Admin Block, Simpa Hall"),
            InstitutionCampusZone("uew_south", "South Campus", "SOUTH", "J.N. Aryeetey Auditorium, Ghartey Hall, Central Library"),
            InstitutionCampusZone("uew_central", "Central Campus", "CENTRAL", "Faculty of Educational Studies, Art Complex")
        ),
        defaultLocations = listOf(
            CampusLocationEntity(
                id = "UEW_AUD",
                name = "J.N. Aryeetey Auditorium",
                shortCode = "JNA",
                category = "Lecture Hall",
                mapX = 48f,
                mapY = 40f,
                description = "Flagship multi-purpose auditorium for cross-faculty lectures, matriculation, and conferences.",
                floors = 2,
                walkingTimeFromHostelMinutes = 8,
                popularVenuesInside = "Main Auditorium, Seminar Wing"
            ),
            CampusLocationEntity(
                id = "UEW_LIB",
                name = "Osagyefo Central Library",
                shortCode = "OSL",
                category = "Library",
                mapX = 55f,
                mapY = 48f,
                description = "Comprehensive educational research and reference library with digital computer labs.",
                floors = 3,
                walkingTimeFromHostelMinutes = 7,
                popularVenuesInside = "Research Commons, E-Learning Hub"
            )
        ),
        sampleSchedules = listOf(
            CourseScheduleEntity(1, "ICT 312", "Educational Software Design", "Dr. E. Kwakye", 1, "08:30", "10:30", "J.N. Aryeetey Auditorium", 3, 0xFF831843),
            CourseScheduleEntity(2, "EDC 321", "Curriculum & Instructional Tech", "Prof. S. Arthur", 2, "11:30", "13:30", "Faculty Block LT 2", 3, 0xFFF59E0B)
        ),
        sampleExams = listOf(
            ExamScheduleEntity(1, "ICT 312", "Educational Software", "2026-09-14", "09:00", "12:00", "J.N. Aryeetey Auditorium", "All Level 300 ICT", 3, "Dr. E. Kwakye", 8, "08:40")
        ),
        studentPortalName = "UEW OSIS",
        lmsName = "UEW VClass",
        libraryName = "Osagyefo Library"
    )

    val ATU_PROFILE = InstitutionProfile(
        id = "atu_accra",
        name = "Accra Technical University",
        shortCode = "ATU",
        motto = "Work Conquers All",
        city = "Barnes Road, Accra",
        region = "Greater Accra",
        country = "Ghana",
        primaryColorHex = 0xFF0284C7, // ATU Ocean Blue
        secondaryColorHex = 0xFFE11D48, // Rose Red
        accentColorHex = 0xFFF59E0B, // Amber
        gradingSystem = GradingSystemType.SCALE_5_0,
        gradingMetricName = "GPA (5.0 Scale)",
        honoursThresholds = listOf(
            HonoursThreshold("First Class Honours", 4.50, 5.00, 0xFF10B981, "GPA >= 4.50"),
            HonoursThreshold("Second Class (Upper)", 3.50, 4.49, 0xFF3B82F6, "3.50 - 4.49 GPA"),
            HonoursThreshold("Second Class (Lower)", 2.50, 3.49, 0xFFF59E0B, "2.50 - 3.49 GPA"),
            HonoursThreshold("Pass", 1.50, 2.49, 0xFF6B7280, "1.50 - 2.49 GPA"),
            HonoursThreshold("Fail", 0.00, 1.49, 0xFFEF4444, "GPA < 1.50")
        ),
        portals = listOf(
            InstitutionPortal("atu_portal", "ATU Student Portal", "Admissions, semester course registration & grades", "https://portal.atu.edu.gh", "Student Records / SIS", "badge"),
            InstitutionPortal("atu_lms", "ATU E-Learning", "Online lecture notes, engineering labs and continuous assessments", "https://elearning.atu.edu.gh", "LMS & Virtual Class", "school")
        ),
        campusZones = listOf(
            InstitutionCampusZone("atu_main", "Barnes Road Campus", "MAIN", "Engineering Block, Applied Sciences, New Admin"),
            InstitutionCampusZone("atu_kinbu", "Kinbu Annex", "KINBU", "Fashion & Design Studios, Built Environment")
        ),
        defaultLocations = listOf(
            CampusLocationEntity(
                id = "ATU_ENG",
                name = "Engineering & Applied Sciences Complex",
                shortCode = "ENG",
                category = "Laboratory",
                mapX = 50f,
                mapY = 45f,
                description = "Modern technical laboratories, computer networks hub, and mechanical workshops.",
                floors = 4,
                walkingTimeFromHostelMinutes = 5,
                popularVenuesInside = "Network Lab 1, CAD Studio, Main LT"
            )
        ),
        sampleSchedules = listOf(
            CourseScheduleEntity(1, "COM 301", "Mobile App Development", "Ing. R. Quaye", 1, "08:30", "11:30", "Engineering Complex Lab 1", 3, 0xFF0284C7)
        ),
        sampleExams = listOf(
            ExamScheduleEntity(1, "COM 301", "Mobile App Dev", "2026-09-16", "09:00", "12:00", "Engineering Complex Lab 1", "HND & BTech CS", 3, "Ing. R. Quaye", 5, "08:45")
        ),
        studentPortalName = "ATU Portal",
        lmsName = "ATU E-Learning",
        libraryName = "ATU Central Library"
    )

    val PRELOADED_INSTITUTIONS: List<InstitutionProfile> = listOf(
        UG_PROFILE,
        KNUST_PROFILE,
        ASHESI_PROFILE,
        UCC_PROFILE,
        UEW_PROFILE,
        ATU_PROFILE,
        GIMPA_PROFILE
    )

    fun getAll(): List<InstitutionProfile> = PRELOADED_INSTITUTIONS

    fun findById(id: String): InstitutionProfile? {
        return PRELOADED_INSTITUTIONS.find {
            it.id.equals(id, ignoreCase = true) ||
            it.id.startsWith(id, ignoreCase = true) ||
            it.shortCode.equals(id, ignoreCase = true)
        }
    }

    fun getById(id: String): InstitutionProfile {
        return findById(id) ?: UG_PROFILE
    }
}
