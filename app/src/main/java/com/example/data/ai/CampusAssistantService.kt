package com.example.data.ai

import com.example.BuildConfig
import com.example.data.local.entity.CampusAlertEntity
import com.example.data.local.entity.CampusLibraryEntity
import com.example.data.local.entity.CampusLocationEntity
import com.example.data.local.entity.CourseScheduleEntity
import com.example.data.local.entity.ExamScheduleEntity
import com.example.data.repository.GpaSummary
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONArray
import org.json.JSONObject
import java.util.concurrent.TimeUnit

class CampusAssistantService {

    private val client = OkHttpClient.Builder()
        .connectTimeout(30, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .writeTimeout(30, TimeUnit.SECONDS)
        .build()

    suspend fun askAssistant(
        query: String,
        schedules: List<CourseScheduleEntity>,
        exams: List<ExamScheduleEntity>,
        locations: List<CampusLocationEntity>,
        alerts: List<CampusAlertEntity>,
        gpaSummary: GpaSummary,
        libraries: List<CampusLibraryEntity> = emptyList()
    ): String = withContext(Dispatchers.IO) {
        val apiKey = try {
            BuildConfig.GEMINI_API_KEY
        } catch (e: Exception) {
            ""
        }

        // If a valid key is provided, try Gemini API; otherwise use our comprehensive intelligent campus reasoning engine
        if (apiKey.isNotBlank() && apiKey != "MY_GEMINI_API_KEY") {
            try {
                val contextPrompt = buildSystemContext(schedules, exams, locations, alerts, gpaSummary, libraries)
                val fullPrompt = "$contextPrompt\n\nStudent Query: $query\nAnswer clearly, politely, with actionable times, venue codes, and recommendations:"
                val aiResponse = callGeminiRest(apiKey, fullPrompt)
                if (aiResponse.isNotBlank()) {
                    return@withContext aiResponse
                }
            } catch (e: Exception) {
                // Fallback to local intelligent rule engine
            }
        }

        // Local Smart Campus Knowledge & Reasoning Engine
        return@withContext generateSmartLocalResponse(query, schedules, exams, locations, alerts, gpaSummary, libraries)
    }

    private fun callGeminiRest(apiKey: String, promptText: String): String {
        val url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash:generateContent?key=$apiKey"
        val root = JSONObject()
        val contents = JSONArray()
        val contentObj = JSONObject()
        val parts = JSONArray()
        val partObj = JSONObject()
        partObj.put("text", promptText)
        parts.put(partObj)
        contentObj.put("parts", parts)
        contents.put(contentObj)
        root.put("contents", contents)

        val body = root.toString().toRequestBody("application/json".toMediaType())
        val request = Request.Builder()
            .url(url)
            .post(body)
            .build()

        client.newCall(request).execute().use { response ->
            if (!response.isSuccessful) return ""
            val jsonStr = response.body?.string() ?: return ""
            val json = JSONObject(jsonStr)
            val candidates = json.optJSONArray("candidates") ?: return ""
            if (candidates.length() > 0) {
                val first = candidates.getJSONObject(0)
                val content = first.optJSONObject("content") ?: return ""
                val p = content.optJSONArray("parts") ?: return ""
                if (p.length() > 0) {
                    return p.getJSONObject(0).optString("text", "")
                }
            }
        }
        return ""
    }

    private fun buildSystemContext(
        schedules: List<CourseScheduleEntity>,
        exams: List<ExamScheduleEntity>,
        locations: List<CampusLocationEntity>,
        alerts: List<CampusAlertEntity>,
        gpaSummary: GpaSummary,
        libraries: List<CampusLibraryEntity>
    ): String {
        val schedSummary = schedules.joinToString("; ") { "${it.courseCode} on Day ${it.dayOfWeek} at ${it.startTime}-${it.endTime} in ${it.venue}" }
        val examSummary = exams.joinToString("; ") { "${it.courseCode} on ${it.examDate} at ${it.startTime} in ${it.venue} (Leave by ${it.suggestedLeaveTime})" }
        val locSummary = locations.joinToString("; ") { "${it.name} (${it.shortCode}): ${it.category}, ${it.walkingTimeFromHostelMinutes} min walk" }
        val alertSummary = alerts.joinToString("; ") { "[${it.category}] ${it.title}: ${it.message}" }
        val libSummary = libraries.joinToString("; ") { "${it.name}: ${it.availableSeats}/${it.totalCapacity} seats free, Hours: ${it.openingHoursWeekdays}" }

        return """
            You are NextGen Campus Companion AI Assistant, an expert academic planner and campus guide for university students.
            Current Student Data:
            - Cumulative GPA: ${gpaSummary.cumulativeGpa} (${gpaSummary.classification})
            - Total Credits: ${gpaSummary.totalCreditHours}
            - Course Timetable: $schedSummary
            - Examination Timetable: $examSummary
            - Campus Buildings & Locations: $locSummary
            - Campus Libraries & Live Seat Status: $libSummary
            - Active Campus Alerts: $alertSummary
        """.trimIndent()
    }

    private fun generateSmartLocalResponse(
        query: String,
        schedules: List<CourseScheduleEntity>,
        exams: List<ExamScheduleEntity>,
        locations: List<CampusLocationEntity>,
        alerts: List<CampusAlertEntity>,
        gpaSummary: GpaSummary,
        libraries: List<CampusLibraryEntity>
    ): String {
        val q = query.lowercase().trim()

        // 1. Library & Desk Availability query
        if (q.contains("library") || q.contains("seat") || q.contains("desk") || q.contains("study spot") || q.contains("balme") || q.contains("ugbs lib")) {
            val totalAvail = libraries.sumOf { it.availableSeats }
            val sb = StringBuilder()
            sb.append("📚 **Campus Libraries & Live Desk Availability**:\n")
            sb.append("There are currently **$totalAvail vacant study desks** across campus.\n\n")
            libraries.take(3).forEach { lib ->
                sb.append("• **${lib.name}** (${lib.campusZone}): **${lib.availableSeats} of ${lib.totalCapacity}** seats free\n")
                sb.append("  🕒 Hours: ${lib.openingHoursWeekdays} | 🤫 Noise: ${lib.currentNoiseLevel}\n")
            }
            sb.append("\n💡 *Tip: Open the 'Campus Libraries & Seats' tab in Resources to view interactive floor-by-floor maps and reserve desks.*")
            return sb.toString()
        }

        // 2. Leave time / Exam query
        if (q.contains("exam") || q.contains("when should i leave") || q.contains("leave") || q.contains("countdown") || q.contains("venue")) {
            val nearestExam = exams.firstOrNull()
            if (nearestExam != null) {
                return "🎓 **Upcoming Examination Alert**:\n" +
                        "• **Course:** ${nearestExam.courseCode} - ${nearestExam.courseTitle}\n" +
                        "• **Date & Time:** ${nearestExam.examDate} at ${nearestExam.startTime} (${nearestExam.endTime})\n" +
                        "• **Venue:** ${nearestExam.venue}\n" +
                        "• **Seating Range:** ${nearestExam.seatRange}\n" +
                        "• **Walking ETA:** ~${nearestExam.walkingTimeMinutes} minutes from hostel.\n\n" +
                        "⏰ **Recommended Departure:** Leave by **${nearestExam.suggestedLeaveTime}** to allow buffer time for seat verification and ID check."
            }
        }

        // 3. Class / Timetable query
        if (q.contains("class") || q.contains("schedule") || q.contains("today") || q.contains("timetable") || q.contains("lecture")) {
            val moved = schedules.filter { it.isCancelledOrMoved }
            val sb = StringBuilder()
            sb.append("📋 **Academic Schedule Overview**:\n")
            if (moved.isNotEmpty()) {
                sb.append("⚠️ **Notice:** ${moved.size} class has a venue update:\n")
                moved.forEach {
                    sb.append("• ${it.courseCode}: ${it.changeNote ?: "Moved to ${it.venue}"}\n")
                }
                sb.append("\n")
            }
            sb.append("Your registered courses this semester include:\n")
            schedules.take(4).forEach {
                sb.append("• **${it.courseCode}** (${it.courseTitle}): ${it.startTime}-${it.endTime} @ ${it.venue} with ${it.lecturer}\n")
            }
            return sb.toString()
        }

        // 4. Navigation / Building search
        val matchedLoc = locations.find { q.contains(it.shortCode.lowercase()) || q.contains(it.name.lowercase()) }
        if (matchedLoc != null) {
            return "📍 **Location Details: ${matchedLoc.name} (${matchedLoc.shortCode})**\n" +
                    "• **Category:** ${matchedLoc.category}\n" +
                    "• **Walking Time:** Approx. ${matchedLoc.walkingTimeFromHostelMinutes} minutes from student residential halls.\n" +
                    "• **Facilities:** ${if (matchedLoc.hasAirConditioning) "Air Conditioned ❄️" else "Standard Ventilation"}, " +
                    "${if (matchedLoc.hasPowerSockets) "Power Outlets Available 🔌" else "No Sockets"}, " +
                    "${if (matchedLoc.wheelchairAccessible) "Wheelchair Ramp ♿" else ""}\n" +
                    "• **Popular Rooms:** ${matchedLoc.popularVenuesInside}\n" +
                    "• **Guide:** ${matchedLoc.description}"
        }

        // 5. CGPA / Grade query
        if (q.contains("gpa") || q.contains("cgpa") || q.contains("cwa") || q.contains("grade") || q.contains("first class") || q.contains("calculate")) {
            val targetGap = (3.60 - gpaSummary.cumulativeGpa).coerceAtLeast(0.0)
            return "📊 **Academic Performance Analytics**:\n" +
                    "• **Current Cumulative GPA:** ${gpaSummary.cumulativeGpa} / 4.00\n" +
                    "• **Classification:** ${gpaSummary.classification}\n" +
                    "• **Completed Credits:** ${gpaSummary.totalCreditHours} credit hours\n\n" +
                    if (gpaSummary.cumulativeGpa >= 3.60) {
                        "🌟 You are maintaining **First Class Honours**! Continue scoring A's and B+'s across your upcoming 3-credit courses to solidify your degree standing."
                    } else {
                        "🎯 **First Class Target:** You need to maintain an average semester GPA of **3.70+** over your remaining credit hours to close the ${String.format("%.2f", targetGap)} gap toward First Class Honours."
                    }
        }

        // 6. Registration & Student Portals (MIS Web / Sakai / OSIS / AIM)
        if (q.contains("registration") || q.contains("register") || q.contains("sakai") || q.contains("mis web") || q.contains("osis") || q.contains("portal") || q.contains("aim")) {
            return "🌐 **Campus Portal & Course Registration Guide**:\n" +
                    "• **Course Registration:** Log into your institution's student portal (MIS Web for UG, OSIS for UCC/UEW, AIM for KNUST) using your Student ID and 5-digit PIN.\n" +
                    "• **Sakai / Moodle LMS:** Access course slides, submit assignments, and take continuous assessment quizzes.\n" +
                    "• **Deadlines:** Ensure you register courses before the end of the add/drop window (Week 3 of the semester) to avoid late registration penalties.\n" +
                    "• **Tip:** You can launch your portal directly from the **Student Portals Gateway** in this app!"
        }

        // 7. Campus Shuttle & Trotro queries
        if (q.contains("shuttle") || q.contains("bus") || q.contains("trotro") || q.contains("fare") || q.contains("diaspora") || q.contains("ayeduase")) {
            return "🚌 **Campus Shuttle & Transit Assistance**:\n" +
                    "• **Live Shuttles:** Dedicated campus shuttles run every 8-12 minutes connecting residential halls (Diaspora, Pent, Brunei, Casford) to central lecture auditoriums.\n" +
                    "• **Standard Fare:** ~GH₵ 3.50 - GH₵ 5.00 per trip.\n" +
                    "• **Night Shuttle Service:** Operates 08:00 PM - 11:30 PM for safe student transit from Balme / Sam Jonah Library to all halls.\n" +
                    "• Check the **Shuttle & Trotro Tracker** in the Student Hub for live bus plates, driver contacts, and arrival ETAs!"
        }

        // 8. Mobile Money (MoMo) & Dues / Fees
        if (q.contains("momo") || q.contains("dues") || q.contains("fee") || q.contains("pay") || q.contains("money") || q.contains("bursary")) {
            return "💳 **Campus Dues & MoMo Payment Portal**:\n" +
                    "• You can pay departmental dues (COMPSSA, CoSS, ITA), Hall dues, and transcript fees seamlessly using **MTN Mobile Money**, **Telecel Cash**, or **AT Money**.\n" +
                    "• Once paid in the app, you receive an instant verifiable digital receipt with a unique transaction reference.\n" +
                    "• **Bursary / Accounts Office:** For official bank slip clearance or fee payment plan inquiries, visit the Cash Office at the Registry (Weekdays 8:30 AM - 4:30 PM)."
        }

        // 9. Wi-Fi & Internet Login (eduroam / campus wifi)
        if (q.contains("wifi") || q.contains("wi-fi") || q.contains("internet") || q.contains("eduroam") || q.contains("connect")) {
            return "📶 **Campus Wi-Fi Connectivity Guide**:\n" +
                    "1. Connect to **eduroam** or your university network (e.g. `UG-WiFi`, `KNUST-WiFi`).\n" +
                    "2. **Identity / Username:** Enter your full student email (e.g. `student@st.ug.edu.gh` or `student@st.knust.edu.gh`).\n" +
                    "3. **Password:** Your university student portal PIN or Active Directory password.\n" +
                    "4. **EAP Method:** Set to `PEAP` and Phase 2 Authentication to `MSCHAPV2`."
        }

        // 10. Food & Cafeterias (Bush Canteen, Night Market, Commercial Area)
        if (q.contains("food") || q.contains("eat") || q.contains("canteen") || q.contains("hungry") || q.contains("bush canteen") || q.contains("night market") || q.contains("waakye")) {
            return "🍽️ **Campus Dining & Food Spots**:\n" +
                    "• **Bush Canteen / Night Market (UG):** Hot waakye, jollof rice, fried plantain (kelewele), pastries, and fresh juices.\n" +
                    "• **Commercial Area (KNUST):** Fast food outlets, banking square, and grocery bakeries.\n" +
                    "• **Old Site Cafeteria (UCC):** Affordable student lunch meals and snack bars.\n" +
                    "• **Open Hours:** Standard food joints operate 07:00 AM - 10:30 PM daily."
        }

        // 11. Motivation & Stress Relief ("Chale, Akwaaba")
        if (q.contains("stress") || q.contains("tired") || q.contains("help") || q.contains("scared") || q.contains("advice") || q.contains("motivation")) {
            return "🇬🇭 **Akwaaba & Words of Encouragement, Chale!**\n" +
                    "University life can be demanding with packed lecture timetables, assignments, and exams, but you are more than capable.\n" +
                    "• Break your study sessions into 25-minute focused blocks (Pomodoro technique).\n" +
                    "• Take short walks to the botanical gardens or campus green squares to reset.\n" +
                    "• Need a quiet spot? Check Balme Library or Sam Jonah reading carrels.\n" +
                    "You've got this—one lecture and one revision session at a time! 🚀"
        }

        // 12. General campus assistant answer
        return "🇬🇭 **CampusMate GH Smart Assistant**:\n" +
                "Akwaaba! I am your all-in-one Ghanaian university companion. Ask me anything:\n" +
                "1. *\"Where are vacant study desks right now?\"*\n" +
                "2. *\"When is my next exam and when should I leave?\"*\n" +
                "3. *\"How do I register courses on MIS Web / OSIS?\"*\n" +
                "4. *\"Check campus shuttle routes & fares in GH₵\"*\n" +
                "5. *\"How do I pay departmental dues with MoMo?\"*\n" +
                "6. *\"Connect to eduroam campus Wi-Fi\"*\n" +
                "7. *\"Calculate my First Class GPA/CWA cutoff\"*"
    }
}

