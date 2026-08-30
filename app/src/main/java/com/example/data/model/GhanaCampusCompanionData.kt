package com.example.data.model

object GhanaCampusCompanionData {

    fun getShuttlesForInstitution(instId: String): List<CampusShuttleRoute> {
        return when {
            instId.contains("knust", ignoreCase = true) -> listOf(
                CampusShuttleRoute(
                    id = "knust_sh_1",
                    institutionId = instId,
                    routeName = "Ayeduase Gate - Tech Junction - Commercial Area",
                    routeCode = "KN-01",
                    fromStop = "Ayeduase Gate",
                    toStop = "Commercial Area & Great Hall",
                    viaStops = listOf("Brunei Complex", "Hall 7", "Faculty of Engineering", "Main Library"),
                    fareCedis = 4.00,
                    nextArrivalMinutes = 3,
                    busNumberPlate = "AS-3810-24",
                    driverName = "Kofi Boateng",
                    driverPhone = "024 112 3456",
                    totalSeats = 32,
                    seatsAvailable = 6,
                    status = "Arriving in 3m"
                ),
                CampusShuttleRoute(
                    id = "knust_sh_2",
                    institutionId = instId,
                    routeName = "Kotei Line - Gaza - College of Science",
                    routeCode = "KN-02",
                    fromStop = "Kotei / Gaza Hostel Hub",
                    toStop = "College of Science (CoS)",
                    viaStops = listOf("Africa Hall", "Unity Hall (Conti)", "SMS Complex"),
                    fareCedis = 4.50,
                    nextArrivalMinutes = 8,
                    busNumberPlate = "AS-7219-23",
                    driverName = "Uncle Osei",
                    driverPhone = "020 987 6543",
                    totalSeats = 28,
                    seatsAvailable = 12,
                    status = "On Route"
                ),
                CampusShuttleRoute(
                    id = "knust_sh_3",
                    institutionId = instId,
                    routeName = "Night Campus Express (Katanga - Tech Hospital)",
                    routeCode = "KN-NIGHT",
                    fromStop = "University Hall (Katanga)",
                    toStop = "Tech Hospital & Boadi Gate",
                    viaStops = listOf("Queens Hall", "Central Library", "Agric Faculty"),
                    fareCedis = 5.00,
                    nextArrivalMinutes = 14,
                    busNumberPlate = "AS-1029-22",
                    driverName = "Yaw Antwi",
                    driverPhone = "055 334 1122",
                    totalSeats = 32,
                    seatsAvailable = 19,
                    status = "On Time"
                )
            )
            instId.contains("ucc", ignoreCase = true) -> listOf(
                CampusShuttleRoute(
                    id = "ucc_sh_1",
                    institutionId = instId,
                    routeName = "Science Block - FELT - Auditorium 900",
                    routeCode = "UCC-01",
                    fromStop = "Old Site (North Campus)",
                    toStop = "New Examination Center (NEC)",
                    viaStops = listOf("Science Quad", "Casely Hayford", "Sam Jonah Library", "Valco Hall"),
                    fareCedis = 3.50,
                    nextArrivalMinutes = 4,
                    busNumberPlate = "CR-1902-23",
                    driverName = "Master Ekow",
                    driverPhone = "024 330 1199",
                    totalSeats = 30,
                    seatsAvailable = 5,
                    status = "Arriving in 4m"
                ),
                CampusShuttleRoute(
                    id = "ucc_sh_2",
                    institutionId = instId,
                    routeName = "Kwesimintsim - New Site Express",
                    routeCode = "UCC-02",
                    fromStop = "Superannuation Complex",
                    toStop = "Medical School Block",
                    viaStops = listOf("SRC Hostel", "KNH", "Atlantic Hall"),
                    fareCedis = 4.00,
                    nextArrivalMinutes = 11,
                    busNumberPlate = "CR-4401-24",
                    driverName = "Uncle Francis",
                    driverPhone = "027 881 2233",
                    totalSeats = 32,
                    seatsAvailable = 14,
                    status = "On Route"
                )
            )
            instId.contains("uew", ignoreCase = true) -> listOf(
                CampusShuttleRoute(
                    id = "uew_sh_1",
                    institutionId = instId,
                    routeName = "North Campus - South Campus Shuttle",
                    routeCode = "UEW-01",
                    fromStop = "North Campus (Faculty Block)",
                    toStop = "South Campus (Auditorium)",
                    viaStops = listOf("Simpa Hall", "Ghartey Hall", "Library Junction"),
                    fareCedis = 3.50,
                    nextArrivalMinutes = 5,
                    busNumberPlate = "CR-8821-23",
                    driverName = "Kwesi Mensah",
                    driverPhone = "024 551 2200",
                    totalSeats = 30,
                    seatsAvailable = 9,
                    status = "Departing Soon"
                )
            )
            else -> listOf(
                // UG Legon Default
                CampusShuttleRoute(
                    id = "ug_sh_1",
                    institutionId = instId,
                    routeName = "Diaspora Express (Pentagon - TF - Evandy - Balme)",
                    routeCode = "UG-01",
                    fromStop = "Diaspora Hall Hub (Pent / TF)",
                    toStop = "Central Campus & Balme Library",
                    viaStops = listOf("Bani Hostel", "Jean Nelson Aka Hall", "JQB Complex", "Great Hall"),
                    fareCedis = 4.00,
                    nextArrivalMinutes = 2,
                    busNumberPlate = "GW-4912-24",
                    driverName = "Uncle Kwame",
                    driverPhone = "024 991 8822",
                    totalSeats = 36,
                    seatsAvailable = 7,
                    status = "Arriving in 2m"
                ),
                CampusShuttleRoute(
                    id = "ug_sh_2",
                    institutionId = instId,
                    routeName = "Main Gate - Legon Hall - Bush Canteen Line",
                    routeCode = "UG-02",
                    fromStop = "Main University Gate",
                    toStop = "Bush Canteen & Night Market",
                    viaStops = listOf("Commonwealth Hall", "Volta Hall", "Akuafo Hall", "UGBS Graduate"),
                    fareCedis = 3.50,
                    nextArrivalMinutes = 7,
                    busNumberPlate = "GE-2091-23",
                    driverName = "Kojo Darko",
                    driverPhone = "020 441 5566",
                    totalSeats = 32,
                    seatsAvailable = 15,
                    status = "On Route"
                ),
                CampusShuttleRoute(
                    id = "ug_sh_3",
                    institutionId = instId,
                    routeName = "Night Campus Shuttle (Safe Ride)",
                    routeCode = "UG-NIGHT",
                    fromStop = "Balme Library Reading Rooms",
                    toStop = "All Hostels (Diaspora & Traditional)",
                    viaStops = listOf("Sarbah Hall", "Mensah Sarbah Field", "TF Hostel Gate", "Pentagon Block C"),
                    fareCedis = 5.00,
                    nextArrivalMinutes = 12,
                    busNumberPlate = "GS-7721-22",
                    driverName = "Emmanuel Asare",
                    driverPhone = "054 112 9900",
                    totalSeats = 36,
                    seatsAvailable = 22,
                    status = "On Time"
                )
            )
        }
    }

    fun getDuesForInstitution(instId: String): List<CampusDueItem> {
        return when {
            instId.contains("knust", ignoreCase = true) -> listOf(
                CampusDueItem("kn_due_1", instId, "KNUST Computer Science Society (CoSS) Dues", "Department Dues", 60.00, false, "2026-09-30", null, "Semester association dues for hackathons, lab kits & study packs."),
                CampusDueItem("kn_due_2", instId, "University Hall (Katanga) JCR Dues", "Hall Dues", 85.00, false, "2026-10-15", null, "Hall week, sanitation levy & Wi-Fi maintenance."),
                CampusDueItem("kn_due_3", instId, "KNUST SRC Development Levy", "SRC Levy", 40.00, true, "2026-08-15", "MM-KN-90214", "Official university student representative council development fund."),
                CampusDueItem("kn_due_4", instId, "Official Academic Transcript Request", "Transcript/Admin", 120.00, false, "2026-11-30", null, "Certified digital & stamped transcript from Academic Affairs.")
            )
            instId.contains("ucc", ignoreCase = true) -> listOf(
                CampusDueItem("ucc_due_1", instId, "UCC Information Tech Association (ITA) Dues", "Department Dues", 50.00, false, "2026-09-28", null, "Faculty handbook, annual seminar & technical workshop dues."),
                CampusDueItem("ucc_due_2", instId, "Casely Hayford Hall Dues", "Hall Dues", 75.00, false, "2026-10-10", null, "Hall week celebrations, power levy and hostel maintenance."),
                CampusDueItem("ucc_due_3", instId, "UCC SRC Welfare & Health Levy", "SRC Levy", 35.00, true, "2026-08-20", "MM-UCC-11842", "Student emergency health insurance and welfare support.")
            )
            else -> listOf(
                CampusDueItem("ug_due_1", instId, "COMPSSA (Computer Science Association) Dues", "Department Dues", 50.00, false, "2026-09-30", null, "Includes annual departmental shirt, hackathon access & project server cloud hosting."),
                CampusDueItem("ug_due_2", instId, "Commonwealth Hall (Vandals) JCR Dues", "Hall Dues", 80.00, false, "2026-10-15", null, "Annual Vandal hall week, sports fund and common room amenities."),
                CampusDueItem("ug_due_3", instId, "UG SRC Development & Technology Fund", "SRC Levy", 45.00, true, "2026-08-10", "MM-UG-88319", "Campus Wi-Fi expansion, shuttle subsidies, and student legal aid fund."),
                CampusDueItem("ug_due_4", instId, "Official Certified Transcript Application", "Transcript/Admin", 100.00, false, "2026-11-20", null, "Academic Affairs certified statement of results & transcript envelope."),
                CampusDueItem("ug_due_5", instId, "Mid-Semester Assessment Resit Fee", "Exam Resit", 70.00, false, "2026-10-05", null, "Registration fee for supplementary paper or deferred practical assessment.")
            )
        }
    }

    fun getLostAndFoundForInstitution(instId: String): List<LostAndFoundItem> {
        return listOf(
            LostAndFoundItem(
                id = "lf_1",
                institutionId = instId,
                title = "Casio fx-991EX ClassWiz Calculator",
                category = "Calculators & Electronics",
                status = "FOUND",
                campusLocation = "Balme Library Ground Floor Reference Desk",
                dateReported = "Today, 10:15 AM",
                reporterName = "Librarian Mrs. Mensah",
                contactPhone = "030 250 0150",
                description = "Black scientific calculator left on Desk #14 near the Africana wing. Has a small blue sticker on the back.",
                claimInstructions = "Describe sticker details or show index number to claim at the Library Circulation Desk."
            ),
            LostAndFoundItem(
                id = "lf_2",
                institutionId = instId,
                title = "Student ID Card (Index 10984521)",
                category = "ID & Cards",
                status = "FOUND",
                campusLocation = "Bush Canteen Food Court",
                dateReported = "Yesterday, 04:30 PM",
                reporterName = "Security Officer Dan",
                contactPhone = "024 411 9023",
                description = "University student identity card belonging to Alex Kwesi Mensah. Found at table near the waakye joint.",
                claimInstructions = "Collect from the Bush Canteen Security Post between 8am and 6pm."
            ),
            LostAndFoundItem(
                id = "lf_3",
                institutionId = instId,
                title = "HP Laptop Charger (Type-C 65W)",
                category = "Calculators & Electronics",
                status = "LOST",
                campusLocation = "KAB 1 Lecture Auditorium",
                dateReported = "2 days ago",
                reporterName = "Kwame Asante",
                contactPhone = "055 882 1100",
                description = "Black 65W Type-C adapter with red velcro cable strap. Left after CS 312 lecture on Wednesday.",
                rewardCedis = 30.00
            ),
            LostAndFoundItem(
                id = "lf_4",
                institutionId = instId,
                title = "Set of Room Keys with Everton FC Keychain",
                category = "Keys",
                status = "FOUND",
                campusLocation = "Diaspora Hall Shuttle Bus Stop",
                dateReported = "3 days ago",
                reporterName = "Driver Uncle Kwame",
                contactPhone = "024 991 8822",
                description = "3 silver Yale keys and a blue Everton FC logo rubber keychain found on the rear shuttle seat.",
                claimInstructions = "Call driver Uncle Kwame directly or collect at the Diaspora Transport Office."
            ),
            LostAndFoundItem(
                id = "lf_5",
                institutionId = instId,
                title = "Navy Blue Backpack with Notebooks",
                category = "Bags & Wallets",
                status = "LOST",
                campusLocation = "JQB Lecture Hall 12",
                dateReported = "Aug 20, 2026",
                reporterName = "Abena Serwaa",
                contactPhone = "020 771 4455",
                description = "Puma backpack containing 3 spiral notebooks for DCIT 301 and a yellow pencil case.",
                rewardCedis = 50.00
            )
        )
    }

    fun getEventsForInstitution(instId: String): List<CampusEvent> {
        return listOf(
            CampusEvent(
                id = "ev_1",
                institutionId = instId,
                title = "Grand Hall Week Durbar & Art Exhibition",
                category = "Hall Week",
                eventDate = "Sept 18, 2026",
                time = "02:00 PM - 09:00 PM",
                venue = "Main Quadrangle & Forecourt",
                organizer = "Hall Junior Common Room (JCR)",
                isRsvpd = true,
                attendeeCount = 520,
                ticketType = "Free Entry (All Students Welcome)",
                description = "The premier annual cultural festival featuring traditional drumming, street food bazaar, live musical acts, and alumni networking."
            ),
            CampusEvent(
                id = "ev_2",
                institutionId = instId,
                title = "Ghana Smart Campus Hackathon & AI Showcase",
                category = "Tech & Innovation",
                eventDate = "Sept 25, 2026",
                time = "09:00 AM - 06:00 PM",
                venue = "Computer Science Complex Lab 1",
                organizer = "Department of Computer Science & GDG Campus",
                isRsvpd = false,
                attendeeCount = 195,
                ticketType = "Free (Registration Required)",
                description = "24-hour sprint building mobile and web solutions for Ghanaian universities. Prizes sponsored by top tech firms in Accra."
            ),
            CampusEvent(
                id = "ev_3",
                institutionId = instId,
                title = "Annual University Career & Internship Fair 2026",
                category = "Career Fair",
                eventDate = "Oct 05, 2026",
                time = "08:30 AM - 04:30 PM",
                venue = "Great Hall / Cedi Conference Centre",
                organizer = "Careers & Counselling Directorate",
                isRsvpd = false,
                attendeeCount = 840,
                ticketType = "Free (CV / Resume Required)",
                description = "Meet 40+ leading employers from banking, fintech, telecom, and government ministries for graduate traineeships and internships."
            ),
            CampusEvent(
                id = "ev_4",
                institutionId = instId,
                title = "Inter-Faculty Football & Basketball Championship",
                category = "Sports",
                eventDate = "Oct 12, 2026",
                time = "03:30 PM - 07:00 PM",
                venue = "University Sports Stadium",
                organizer = "Sports Directorate & SRC",
                isRsvpd = false,
                attendeeCount = 650,
                ticketType = "Free (Student ID)",
                description = "The fiercest campus sporting rivalry. Cheer your faculty team to victory under floodlights!"
            )
        )
    }
}
