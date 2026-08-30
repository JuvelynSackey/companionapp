package com.example.data.model

data class StudentProfile(
    val id: String = "std_10984521",
    val name: String = "Alex Kwesi Mensah",
    val studentId: String = "10984521",
    val email: String = "akmensah065@st.ug.edu.gh",
    val phone: String = "024 555 0192",
    val institutionId: String = "ug_legon",
    val program: String = "BSc Computer Science",
    val level: String = "Level 300",
    val hallOfResidence: String = "Commonwealth Hall (Vandals)",
    val roomNumber: String = "Room B24",
    val academicYear: String = "2025 / 2026 Academic Year",
    val semester: String = "Second Semester",
    val momoNumber: String = "024 555 0192",
    val momoProvider: String = "MTN Mobile Money",
    val studentCardBarcode: String = "UG-2023-CS-10984521",
    val campusPoints: Int = 420
)

data class CampusShuttleRoute(
    val id: String,
    val institutionId: String,
    val routeName: String,
    val routeCode: String,
    val fromStop: String,
    val toStop: String,
    val viaStops: List<String>,
    val fareCedis: Double,
    val nextArrivalMinutes: Int,
    val busNumberPlate: String,
    val driverName: String,
    val driverPhone: String,
    val totalSeats: Int = 32,
    val seatsAvailable: Int = 8,
    val status: String = "On Time", // "Arriving in 3m", "Departing Soon", "On Route", "High Traffic"
    val operatingHours: String = "06:30 AM - 11:30 PM",
    val frequencyMinutes: Int = 10
)

data class LostAndFoundItem(
    val id: String = java.util.UUID.randomUUID().toString(),
    val institutionId: String,
    val title: String,
    val category: String, // "ID & Cards", "Calculators & Electronics", "Bags & Wallets", "Keys", "Books & Notes"
    val status: String, // "LOST", "FOUND", "CLAIMED"
    val campusLocation: String,
    val dateReported: String,
    val reporterName: String,
    val contactPhone: String,
    val description: String,
    val claimInstructions: String = "Please present student ID card or verify serial number/contents to claim.",
    val rewardCedis: Double? = null
)

data class CampusDueItem(
    val id: String,
    val institutionId: String,
    val title: String,
    val category: String, // "Department Dues", "Hall Dues", "SRC Levy", "Transcript/Admin", "Exam Resit"
    val amountCedis: Double,
    val isPaid: Boolean = false,
    val dueDate: String,
    val paymentReference: String? = null,
    val description: String
)

data class MoMoPaymentReceipt(
    val transactionRef: String,
    val itemTitle: String,
    val amountCedis: Double,
    val payerName: String,
    val studentId: String,
    val momoNumber: String,
    val provider: String,
    val timestamp: Long = System.currentTimeMillis(),
    val status: String = "SUCCESSFUL"
)

data class CampusEvent(
    val id: String,
    val institutionId: String,
    val title: String,
    val category: String, // "Hall Week", "Tech & Innovation", "Career Fair", "Sports", "SRC"
    val eventDate: String,
    val time: String,
    val venue: String,
    val organizer: String,
    val isRsvpd: Boolean = false,
    val attendeeCount: Int = 180,
    val ticketType: String = "Free Entry (Student ID)",
    val description: String
)
