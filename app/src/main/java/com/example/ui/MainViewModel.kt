package com.example.ui

import android.app.Application
import android.content.Context
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.util.Log
import android.widget.Toast
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.example.data.auth.AuthResultState
import com.example.data.auth.FirebaseAuthManager
import com.google.firebase.auth.FirebaseUser
import com.example.data.repository.FirestoreRepository
import com.example.data.ai.CampusAssistantService
import com.example.data.local.AppDatabase
import com.example.data.local.entity.CampusAlertEntity
import com.example.data.local.entity.CampusLibraryEntity
import com.example.data.local.entity.CampusLocationEntity
import com.example.data.local.entity.CourseAssessmentEntity
import com.example.data.local.entity.CourseScheduleEntity
import com.example.data.local.entity.ExamScheduleEntity
import com.example.data.local.entity.GpaCourseEntity
import com.example.data.local.entity.LibraryFloorEntity
import com.example.data.local.entity.StudyResourceEntity
import com.example.data.alarm.SmartAlarmCalculation
import com.example.data.alarm.SmartAlarmManager
import com.example.data.remote.CampusWeatherSummary
import com.example.data.remote.WeatherApiClient
import com.example.data.repository.CampusRepository
import com.example.data.repository.CourseWeightedGradeSummary
import com.example.data.model.CampusDueItem
import com.example.data.model.CampusEvent
import com.example.data.model.CampusShuttleRoute
import com.example.data.model.GhanaCampusCompanionData
import com.example.data.model.LostAndFoundItem
import com.example.data.model.MoMoPaymentReceipt
import com.example.data.model.StudentProfile
import com.example.data.repository.ExamCountdownInfo
import com.example.data.repository.ExamCountdownUtils
import com.example.data.repository.GpaSummary
import com.example.data.repository.LibraryWithFloors
import com.example.data.repository.NavigationRoute
import com.example.data.repository.SeatOccupancyLevel
import com.example.data.worker.CampusAlertSyncWorker
import com.example.data.worker.ClassReminderScheduler
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

enum class UserRole {
    STUDENT,
    CLASS_REPRESENTATIVE,
    ADMINISTRATOR
}

enum class NavigationTab {
    DASHBOARD,
    TIMETABLE,
    EXAMS,
    MAP_NAV,
    STUDENT_HUB,
    ALERTS,
    ANALYTICS,
    RESOURCES,
    LIBRARIES,
    AI_ASSISTANT,
    SIGN_IN
}

data class ChatMessage(
    val id: String = java.util.UUID.randomUUID().toString(),
    val isUser: Boolean,
    val text: String,
    val timestamp: Long = System.currentTimeMillis()
)

data class SmartAlarmSettings(
    val isEnabled: Boolean = true,
    val prepMinutes: Int = 45,
    val transitMinutes: Int = 20,
    val weatherAdjustmentEnabled: Boolean = true
)

class MainViewModel(application: Application) : AndroidViewModel(application) {

    private val db = AppDatabase.getDatabase(application)
    val repository = CampusRepository(db)
    val preferencesRepository = com.example.data.preferences.InstitutionPreferencesRepository(application)
    private val assistantService = CampusAssistantService()
    val authManager = FirebaseAuthManager()
    val firestoreRepository = FirestoreRepository()

    // Cloud Sync State
    private val _isCloudSyncing = MutableStateFlow(false)
    val isCloudSyncing: StateFlow<Boolean> = _isCloudSyncing.asStateFlow()

    // Firebase Auth State
    val firebaseUser: StateFlow<FirebaseUser?> = authManager.authStateFlow
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), authManager.currentUser)

    private val _authUiState = MutableStateFlow<AuthResultState>(AuthResultState.Idle)
    val authUiState: StateFlow<AuthResultState> = _authUiState.asStateFlow()

    // Onboarding State (persisted in DataStore)
    private val _isOnboardingCompleted = MutableStateFlow<Boolean?>(null) // null = loading
    val isOnboardingCompleted: StateFlow<Boolean?> = _isOnboardingCompleted.asStateFlow()

    private val _isSavingInstitution = MutableStateFlow(false)
    val isSavingInstitution: StateFlow<Boolean> = _isSavingInstitution.asStateFlow()

    private val _isFetchingInstitutions = MutableStateFlow(false)
    val isFetchingInstitutions: StateFlow<Boolean> = _isFetchingInstitutions.asStateFlow()

    // Current Navigation & Role State
    private val _currentRole = MutableStateFlow(UserRole.STUDENT)
    val currentRole: StateFlow<UserRole> = _currentRole.asStateFlow()

    // Multi-Tenant Institution Management
    private val _allInstitutions = MutableStateFlow<List<com.example.data.model.InstitutionProfile>>(
        com.example.data.model.InstitutionRegistry.PRELOADED_INSTITUTIONS
    )
    val allInstitutions: StateFlow<List<com.example.data.model.InstitutionProfile>> = _allInstitutions.asStateFlow()

    private val _currentInstitution = MutableStateFlow<com.example.data.model.InstitutionProfile>(
        com.example.data.model.InstitutionRegistry.UG_PROFILE
    )
    val currentInstitution: StateFlow<com.example.data.model.InstitutionProfile> = _currentInstitution.asStateFlow()

    private val _selectedTab = MutableStateFlow(NavigationTab.DASHBOARD)
    val selectedTab: StateFlow<NavigationTab> = _selectedTab.asStateFlow()

    // Timetables & Active Day
    private val _selectedDay = MutableStateFlow(1) // Monday = 1
    val selectedDay: StateFlow<Int> = _selectedDay.asStateFlow()

    val allSchedules: StateFlow<List<CourseScheduleEntity>> = repository.allSchedules
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val allExams: StateFlow<List<ExamScheduleEntity>> = repository.allExams
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val nextExamCountdown: StateFlow<ExamCountdownInfo?> = repository.allExams
        .map { exams -> ExamCountdownUtils.findNextUpcomingExam(exams) }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), null)

    val allLocations: StateFlow<List<CampusLocationEntity>> = repository.allLocations
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val allAlerts: StateFlow<List<CampusAlertEntity>> = repository.allAlerts
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val allGpaCourses: StateFlow<List<GpaCourseEntity>> = repository.allGpaCourses
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val allAssessments: StateFlow<List<CourseAssessmentEntity>> = repository.allAssessments
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val courseWeightedSummaries: StateFlow<List<CourseWeightedGradeSummary>> = repository.courseWeightedSummaries
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    private val _selectedCourseForAssessment = MutableStateFlow<GpaCourseEntity?>(null)
    val selectedCourseForAssessment: StateFlow<GpaCourseEntity?> = _selectedCourseForAssessment.asStateFlow()

    val gpaSummary: StateFlow<GpaSummary> = repository.gpaSummary
        .stateIn(
            viewModelScope,
            SharingStarted.WhileSubscribed(5000),
            GpaSummary(0.0, 0, "No Grades Recorded", emptyList())
        )

    val academicMetricResult: StateFlow<com.example.data.repository.AcademicMetricResult> = combine(
        allGpaCourses,
        currentInstitution
    ) { courses, institution ->
        com.example.data.repository.GradingEngine.calculateAcademicMetric(courses, institution)
    }.stateIn(
        viewModelScope,
        SharingStarted.WhileSubscribed(5000),
        com.example.data.repository.AcademicMetricResult(
            0.0,
            "0.00",
            "No Data",
            0xFF6B7280,
            0,
            false,
            "Cumulative GPA",
            "No data recorded"
        )
    )

    val allResources: StateFlow<List<StudyResourceEntity>> = repository.allResources
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    // Campus Libraries & Real-Time Seat Status
    val allLibraries: StateFlow<List<CampusLibraryEntity>> = repository.allLibraries
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val allLibraryFloors: StateFlow<List<LibraryFloorEntity>> = repository.allLibraryFloors
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val librariesWithFloors: StateFlow<List<LibraryWithFloors>> = repository.librariesWithFloors
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    private val _selectedLibraryForDetails = MutableStateFlow<LibraryWithFloors?>(null)
    val selectedLibraryForDetails: StateFlow<LibraryWithFloors?> = _selectedLibraryForDetails.asStateFlow()

    private val _librarySearchQuery = MutableStateFlow("")
    val librarySearchQuery: StateFlow<String> = _librarySearchQuery.asStateFlow()

    private val _libraryFilterChip = MutableStateFlow("All")
    val libraryFilterChip: StateFlow<String> = _libraryFilterChip.asStateFlow()

    // Campus Weather State (Fetched via Open-Meteo REST API)
    private val _currentWeather = MutableStateFlow(CampusWeatherSummary())
    val currentWeather: StateFlow<CampusWeatherSummary> = _currentWeather.asStateFlow()

    // Smart Alarm Preference States
    private val _isSmartAlarmEnabled = MutableStateFlow(true)
    val isSmartAlarmEnabled: StateFlow<Boolean> = _isSmartAlarmEnabled.asStateFlow()

    private val _smartAlarmPrepMinutes = MutableStateFlow(45)
    val smartAlarmPrepMinutes: StateFlow<Int> = _smartAlarmPrepMinutes.asStateFlow()

    private val _smartAlarmTransitMinutes = MutableStateFlow(20)
    val smartAlarmTransitMinutes: StateFlow<Int> = _smartAlarmTransitMinutes.asStateFlow()

    private val _smartAlarmWeatherAdjustmentEnabled = MutableStateFlow(true)
    val smartAlarmWeatherAdjustmentEnabled: StateFlow<Boolean> = _smartAlarmWeatherAdjustmentEnabled.asStateFlow()

    // Reactive Smart Alarm Calculation (Combines schedules, selected day, weather, and settings)
    private val smartAlarmSettingsFlow: kotlinx.coroutines.flow.Flow<SmartAlarmSettings> = combine(
        _isSmartAlarmEnabled,
        _smartAlarmPrepMinutes,
        _smartAlarmTransitMinutes,
        _smartAlarmWeatherAdjustmentEnabled
    ) { enabled: Boolean, prep: Int, transit: Int, weatherAdj: Boolean ->
        SmartAlarmSettings(
            isEnabled = enabled,
            prepMinutes = prep,
            transitMinutes = transit,
            weatherAdjustmentEnabled = weatherAdj
        )
    }

    val smartAlarmCalculation: StateFlow<SmartAlarmCalculation> = combine(
        allSchedules,
        _selectedDay,
        _currentWeather,
        smartAlarmSettingsFlow
    ) { schedules, day, weather, settings ->
        val schedulesForDay = schedules.filter { it.dayOfWeek == day }
        SmartAlarmManager.calculateSmartAlarm(
            schedulesForDay = schedulesForDay,
            weather = weather,
            basePrepMinutes = settings.prepMinutes,
            baseTransitMinutes = settings.transitMinutes,
            weatherAdjustmentEnabled = settings.weatherAdjustmentEnabled,
            isAlarmEnabled = settings.isEnabled,
            targetDay = day
        )
    }.stateIn(
        viewModelScope,
        SharingStarted.WhileSubscribed(5000),
        SmartAlarmCalculation()
    )

    init {
        // Schedule periodic background announcement worker
        CampusAlertSyncWorker.schedulePeriodicSync(application)
        // Fetch real-time campus weather data via API
        refreshCampusWeather()

        // Observe and load persisted institution preference and onboarding state from DataStore
        viewModelScope.launch {
            preferencesRepository.isOnboardingCompleted.collect { isCompleted ->
                _isOnboardingCompleted.value = isCompleted
            }
        }

        viewModelScope.launch {
            preferencesRepository.selectedInstitutionId.collect { savedId ->
                if (!savedId.isNullOrBlank()) {
                    val profile = _allInstitutions.value.find { it.id == savedId }
                        ?: com.example.data.model.InstitutionRegistry.findById(savedId)
                    if (profile != null) {
                        _currentInstitution.value = profile
                    }
                }
            }
        }

        // Keep WorkManager 15-minute advance lecture reminders synchronized
        viewModelScope.launch {
            repository.allSchedules.collect { schedules ->
                ClassReminderScheduler.syncCourseSchedules(application, schedules)
            }
        }
    }

    // Map & Route State
    private val _selectedStartLocation = MutableStateFlow<CampusLocationEntity?>(null)
    val selectedStartLocation: StateFlow<CampusLocationEntity?> = _selectedStartLocation.asStateFlow()

    private val _selectedDestLocation = MutableStateFlow<CampusLocationEntity?>(null)
    val selectedDestLocation: StateFlow<CampusLocationEntity?> = _selectedDestLocation.asStateFlow()

    private val _activeRoute = MutableStateFlow<NavigationRoute?>(null)
    val activeRoute: StateFlow<NavigationRoute?> = _activeRoute.asStateFlow()

    private val _selectedCategoryFilter = MutableStateFlow("All")
    val selectedCategoryFilter: StateFlow<String> = _selectedCategoryFilter.asStateFlow()

    // AI Assistant State
    private val _chatMessages = MutableStateFlow<List<ChatMessage>>(
        listOf(
            ChatMessage(
                isUser = false,
                text = "🇬🇭 **Akwaaba!** I am your **CampusMate GH Smart Assistant**.\n\nAsk me anything about your class schedules, exam countdowns, campus shuttles, mobile money dues, study desks, or Ghanaian university life!"
            )
        )
    )
    val chatMessages: StateFlow<List<ChatMessage>> = _chatMessages.asStateFlow()

    private val _isAssistantTyping = MutableStateFlow(false)
    val isAssistantTyping: StateFlow<Boolean> = _isAssistantTyping.asStateFlow()

    // Smart Campus Companion: Student Profile, Transit, MoMo, Lost & Found, Events
    private val _studentProfile = MutableStateFlow(StudentProfile())
    val studentProfile: StateFlow<StudentProfile> = _studentProfile.asStateFlow()

    private val _shuttleRoutes = MutableStateFlow<List<CampusShuttleRoute>>(
        GhanaCampusCompanionData.getShuttlesForInstitution("ug_legon")
    )
    val shuttleRoutes: StateFlow<List<CampusShuttleRoute>> = _shuttleRoutes.asStateFlow()

    private val _campusDues = MutableStateFlow<List<CampusDueItem>>(
        GhanaCampusCompanionData.getDuesForInstitution("ug_legon")
    )
    val campusDues: StateFlow<List<CampusDueItem>> = _campusDues.asStateFlow()

    private val _lostAndFoundItems = MutableStateFlow<List<LostAndFoundItem>>(
        GhanaCampusCompanionData.getLostAndFoundForInstitution("ug_legon")
    )
    val lostAndFoundItems: StateFlow<List<LostAndFoundItem>> = _lostAndFoundItems.asStateFlow()

    private val _campusEvents = MutableStateFlow<List<CampusEvent>>(
        GhanaCampusCompanionData.getEventsForInstitution("ug_legon")
    )
    val campusEvents: StateFlow<List<CampusEvent>> = _campusEvents.asStateFlow()

    private val _paymentReceipts = MutableStateFlow<List<MoMoPaymentReceipt>>(emptyList())
    val paymentReceipts: StateFlow<List<MoMoPaymentReceipt>> = _paymentReceipts.asStateFlow()

    private val _isProcessingPayment = MutableStateFlow(false)
    val isProcessingPayment: StateFlow<Boolean> = _isProcessingPayment.asStateFlow()

    private val _lastPaymentReceipt = MutableStateFlow<MoMoPaymentReceipt?>(null)
    val lastPaymentReceipt: StateFlow<MoMoPaymentReceipt?> = _lastPaymentReceipt.asStateFlow()

    private val _activeAlarmTrigger = MutableStateFlow<String?>(null)
    val activeAlarmTrigger: StateFlow<String?> = _activeAlarmTrigger.asStateFlow()

    fun setRole(role: UserRole) {
        _currentRole.value = role
        val roleName = when (role) {
            UserRole.STUDENT -> "Student Mode"
            UserRole.CLASS_REPRESENTATIVE -> "Class Rep Mode"
            UserRole.ADMINISTRATOR -> "Administrator Mode"
        }
        Toast.makeText(getApplication(), "Switched to $roleName", Toast.LENGTH_SHORT).show()
    }

    fun setSelectedTab(tab: NavigationTab) {
        _selectedTab.value = tab
    }

    fun setSelectedDay(day: Int) {
        _selectedDay.value = day
    }

    fun setCategoryFilter(category: String) {
        _selectedCategoryFilter.value = category
    }

    // Schedule actions
    fun toggleScheduleAlarm(schedule: CourseScheduleEntity) {
        viewModelScope.launch {
            repository.toggleScheduleAlarm(schedule.id, !schedule.isAlarmEnabled)
            val state = if (!schedule.isAlarmEnabled) "enabled" else "disabled"
            Toast.makeText(getApplication(), "Reminder $state for ${schedule.courseCode}", Toast.LENGTH_SHORT).show()
        }
    }

    fun updateCourseVenue(id: Long, newVenue: String, note: String) {
        viewModelScope.launch {
            repository.updateVenue(id, newVenue, note)
            // Also post an alert automatically for classmates
            val sched = allSchedules.value.find { it.id == id }
            val courseName = sched?.courseCode ?: "Class"
            repository.insertAlert(
                CampusAlertEntity(
                    title = "⚡ Relocation: $courseName moved to $newVenue",
                    message = note.ifBlank { "Venue updated to $newVenue by Class Representative." },
                    category = "VENUE_CHANGE",
                    author = if (_currentRole.value == UserRole.CLASS_REPRESENTATIVE) "Class Representative" else "Academic Affairs",
                    isPinned = true,
                    courseCode = sched?.courseCode
                )
            )
            Toast.makeText(getApplication(), "Venue updated and alert broadcasted to classmates!", Toast.LENGTH_LONG).show()
        }
    }

    fun addCourseSchedule(
        code: String,
        title: String,
        lecturer: String,
        day: Int,
        start: String,
        end: String,
        venue: String,
        credits: Int
    ) {
        viewModelScope.launch {
            val schedule = CourseScheduleEntity(
                courseCode = code.trim().uppercase(),
                courseTitle = title.trim(),
                lecturer = lecturer.trim(),
                dayOfWeek = day,
                startTime = start.trim(),
                endTime = end.trim(),
                venue = venue.trim(),
                creditHours = credits,
                colorHex = 0xFF0284C7
            )
            val newId = repository.insertSchedule(schedule)
            ClassReminderScheduler.scheduleCourseScheduleReminder(getApplication(), schedule.copy(id = newId))
            Toast.makeText(getApplication(), "Course schedule added (15m reminder active)", Toast.LENGTH_SHORT).show()
        }
    }

    fun deleteSchedule(schedule: CourseScheduleEntity) {
        viewModelScope.launch {
            repository.deleteSchedule(schedule)
            ClassReminderScheduler.cancelCourseScheduleReminder(getApplication(), schedule.id)
            Toast.makeText(getApplication(), "Schedule removed", Toast.LENGTH_SHORT).show()
        }
    }

    // Exam actions
    fun toggleExamAlarm(exam: ExamScheduleEntity) {
        viewModelScope.launch {
            repository.toggleExamAlarm(exam.id, !exam.isAlarmSet)
            val state = if (!exam.isAlarmSet) "enabled" else "disabled"
            Toast.makeText(getApplication(), "Exam departure alert $state for ${exam.courseCode}", Toast.LENGTH_SHORT).show()
        }
    }

    fun addExamSchedule(
        code: String,
        title: String,
        date: String,
        start: String,
        end: String,
        venue: String,
        seatRange: String,
        walkingMinutes: Int,
        rules: String
    ) {
        viewModelScope.launch {
            val suggestedLeave = repository.calculateSuggestedLeaveTime(start, walkingMinutes)
            repository.insertExam(
                ExamScheduleEntity(
                    courseCode = code.trim().uppercase(),
                    courseTitle = title.trim(),
                    examDate = date.trim(),
                    startTime = start.trim(),
                    endTime = end.trim(),
                    venue = venue.trim(),
                    seatRange = seatRange.trim(),
                    walkingTimeMinutes = walkingMinutes,
                    suggestedLeaveTime = suggestedLeave,
                    rules = rules.trim()
                )
            )
            Toast.makeText(getApplication(), "Exam timetable entry added", Toast.LENGTH_SHORT).show()
        }
    }

    fun deleteExam(exam: ExamScheduleEntity) {
        viewModelScope.launch {
            repository.deleteExam(exam)
            Toast.makeText(getApplication(), "Exam '${exam.courseCode}' removed from timetable", Toast.LENGTH_SHORT).show()
        }
    }

    fun deleteExamById(id: Long) {
        viewModelScope.launch {
            val target = allExams.value.find { it.id == id }
            if (target != null) {
                repository.deleteExam(target)
                Toast.makeText(getApplication(), "Exam '${target.courseCode}' deleted", Toast.LENGTH_SHORT).show()
            }
        }
    }

    // Map & Route selection
    enum class WalkingPace(val label: String, val speedMpm: Double, val iconEmoji: String) {
        RELAXED("Relaxed (65 m/min)", 65.0, "🚶"),
        STANDARD("Standard (80 m/min)", 80.0, "🚶‍♂️"),
        BRISK("Brisk / Rush (105 m/min)", 105.0, "🏃‍♂️")
    }

    private val _selectedWalkingPace = MutableStateFlow(WalkingPace.STANDARD)
    val selectedWalkingPace: StateFlow<WalkingPace> = _selectedWalkingPace.asStateFlow()

    fun setWalkingPace(pace: WalkingPace) {
        _selectedWalkingPace.value = pace
        updateComputedRoute()
    }

    fun selectStartLocation(location: CampusLocationEntity?) {
        _selectedStartLocation.value = location
        updateComputedRoute()
    }

    fun selectDestLocation(location: CampusLocationEntity?) {
        _selectedDestLocation.value = location
        updateComputedRoute()
    }

    fun swapStartAndDestination() {
        val currentStart = _selectedStartLocation.value
        val currentDest = _selectedDestLocation.value
        _selectedStartLocation.value = currentDest
        _selectedDestLocation.value = currentStart
        updateComputedRoute()
        Toast.makeText(getApplication(), "Swapped route direction ⇄", Toast.LENGTH_SHORT).show()
    }

    fun clearActiveRoute() {
        _selectedStartLocation.value = null
        _selectedDestLocation.value = null
        _activeRoute.value = null
    }

    fun addCustomPinnedLocation(
        name: String,
        shortCode: String,
        category: String,
        mapX: Float,
        mapY: Float,
        description: String,
        popularVenues: String = "Pinned Landmark Point"
    ) {
        viewModelScope.launch {
            val customId = "pin_${System.currentTimeMillis()}"
            val newLocation = CampusLocationEntity(
                id = customId,
                name = name.trim(),
                shortCode = shortCode.trim().ifBlank { "PIN" },
                category = category,
                mapX = mapX.coerceIn(5f, 95f),
                mapY = mapY.coerceIn(5f, 95f),
                description = description.ifBlank { "Custom user-pinned campus landmark point." },
                floors = 1,
                hasAirConditioning = false,
                hasPowerSockets = false,
                wheelchairAccessible = true,
                walkingTimeFromHostelMinutes = 5,
                popularVenuesInside = popularVenues
            )
            repository.insertLocation(newLocation)
            // Auto-select as destination or start
            if (_selectedDestLocation.value == null) {
                _selectedDestLocation.value = newLocation
            }
            updateComputedRoute()
            Toast.makeText(getApplication(), "📍 Pinned '$name' on Campus Map!", Toast.LENGTH_SHORT).show()
        }
    }

    fun deleteCampusLocation(location: CampusLocationEntity) {
        viewModelScope.launch {
            repository.deleteLocation(location)
            if (_selectedStartLocation.value?.id == location.id) _selectedStartLocation.value = null
            if (_selectedDestLocation.value?.id == location.id) _selectedDestLocation.value = null
            updateComputedRoute()
            Toast.makeText(getApplication(), "Removed '${location.name}' from map", Toast.LENGTH_SHORT).show()
        }
    }

    fun planRouteTo(destination: CampusLocationEntity) {
        // Default start: Pentagon Hall or first hostel
        val start = _selectedStartLocation.value
            ?: allLocations.value.firstOrNull { it.category.contains("Hostel") }
            ?: allLocations.value.firstOrNull { it.id != destination.id }

        _selectedStartLocation.value = start
        _selectedDestLocation.value = destination
        updateComputedRoute()
        _selectedTab.value = NavigationTab.MAP_NAV
    }

    private fun updateComputedRoute() {
        val start = _selectedStartLocation.value
        val dest = _selectedDestLocation.value
        if (start != null && dest != null && start.id != dest.id) {
            val baseRoute = repository.calculateRoute(start, dest)
            val customSpeed = _selectedWalkingPace.value.speedMpm
            val adjustedMinutes = ((baseRoute.distanceMeters / customSpeed).toInt()).coerceAtLeast(1)
            _activeRoute.value = baseRoute.copy(estimatedWalkingMinutes = adjustedMinutes)
        } else {
            _activeRoute.value = null
        }
    }

    // Alerts & Broadcast
    fun broadcastAlert(title: String, message: String, category: String, courseCode: String?) {
        viewModelScope.launch {
            val author = when (_currentRole.value) {
                UserRole.CLASS_REPRESENTATIVE -> "Class Representative (Verified)"
                UserRole.ADMINISTRATOR -> "Academic Affairs Admin"
                UserRole.STUDENT -> "Student Notice"
            }
            // Trigger background worker to process and broadcast push notification
            CampusAlertSyncWorker.triggerImmediateAlertSync(
                context = getApplication(),
                title = title.trim(),
                message = message.trim(),
                category = category,
                author = author,
                courseCode = courseCode?.trim()?.takeIf { it.isNotBlank() }
            )
            Toast.makeText(getApplication(), "Alert broadcasted via background worker to all students!", Toast.LENGTH_SHORT).show()
        }
    }

    fun triggerBackgroundWorkerAlertCheck() {
        CampusAlertSyncWorker.triggerImmediateAlertSync(
            context = getApplication()
        )
        Toast.makeText(getApplication(), "Background sync worker enqueued. Checking campus announcements...", Toast.LENGTH_SHORT).show()
    }

    fun markAlertAsRead(id: Long) {
        viewModelScope.launch {
            repository.markAlertAsRead(id)
        }
    }

    // GPA & Course Grade Tracker
    fun selectCourseForAssessment(course: GpaCourseEntity?) {
        _selectedCourseForAssessment.value = course
    }

    fun addGpaCourse(
        semName: String,
        code: String,
        title: String,
        credits: Int,
        grade: String = "A",
        targetGrade: String = "A",
        isWeighted: Boolean = true
    ) {
        viewModelScope.launch {
            val point = when (grade.uppercase()) {
                "A" -> 4.0
                "B+" -> 3.5
                "B" -> 3.0
                "C+" -> 2.5
                "C" -> 2.0
                "D+" -> 1.5
                "D" -> 1.0
                else -> 0.0
            }
            val newId = repository.insertGpaCourse(
                GpaCourseEntity(
                    semesterName = semName.trim(),
                    courseCode = code.uppercase().trim(),
                    courseTitle = title.trim(),
                    creditHours = credits,
                    grade = grade.uppercase(),
                    gradePoint = point,
                    targetGrade = targetGrade.uppercase(),
                    isWeightedFromAssessments = isWeighted
                )
            )
            Toast.makeText(getApplication(), "Course $code added to GPA Tracker", Toast.LENGTH_SHORT).show()
        }
    }

    fun updateCourseTargetGrade(course: GpaCourseEntity, newTarget: String) {
        viewModelScope.launch {
            repository.updateGpaCourse(course.copy(targetGrade = newTarget.uppercase()))
            if (_selectedCourseForAssessment.value?.id == course.id) {
                _selectedCourseForAssessment.value = course.copy(targetGrade = newTarget.uppercase())
            }
            Toast.makeText(getApplication(), "Target updated to ${newTarget.uppercase()} for ${course.courseCode}", Toast.LENGTH_SHORT).show()
        }
    }

    fun deleteGpaCourse(course: GpaCourseEntity) {
        viewModelScope.launch {
            if (_selectedCourseForAssessment.value?.id == course.id) {
                _selectedCourseForAssessment.value = null
            }
            repository.deleteGpaCourse(course)
            Toast.makeText(getApplication(), "Course ${course.courseCode} removed", Toast.LENGTH_SHORT).show()
        }
    }

    fun addCourseAssessment(
        courseId: Long,
        title: String,
        category: String,
        scoreAchieved: Double,
        maxScore: Double,
        weightPercentage: Double,
        date: String = "",
        notes: String = ""
    ) {
        viewModelScope.launch {
            repository.insertAssessment(
                CourseAssessmentEntity(
                    courseId = courseId,
                    title = title.trim(),
                    category = category.trim(),
                    scoreAchieved = scoreAchieved,
                    maxScore = if (maxScore > 0) maxScore else 100.0,
                    weightPercentage = weightPercentage,
                    date = date.trim(),
                    notes = notes.trim()
                )
            )
            Toast.makeText(getApplication(), "Assessment score '$title' saved!", Toast.LENGTH_SHORT).show()
        }
    }

    fun updateCourseAssessment(assessment: CourseAssessmentEntity) {
        viewModelScope.launch {
            repository.updateAssessment(assessment)
            Toast.makeText(getApplication(), "Assessment score updated", Toast.LENGTH_SHORT).show()
        }
    }

    fun deleteCourseAssessment(assessment: CourseAssessmentEntity) {
        viewModelScope.launch {
            repository.deleteAssessment(assessment)
            Toast.makeText(getApplication(), "Assessment score removed", Toast.LENGTH_SHORT).show()
        }
    }

    // Study Resources
    fun toggleBookmark(resource: StudyResourceEntity) {
        viewModelScope.launch {
            repository.toggleBookmark(resource.id, !resource.isBookmarked)
        }
    }

    fun downloadResource(resource: StudyResourceEntity) {
        viewModelScope.launch {
            repository.incrementDownload(resource.id)
            Toast.makeText(getApplication(), "Opening ${resource.title} (${resource.fileSize})...", Toast.LENGTH_SHORT).show()
        }
    }

    // Campus Libraries Directory Actions
    fun setLibrarySearchQuery(query: String) {
        _librarySearchQuery.value = query
    }

    fun setLibraryFilterChip(chip: String) {
        _libraryFilterChip.value = chip
    }

    fun selectLibraryForDetails(libraryWithFloors: LibraryWithFloors?) {
        _selectedLibraryForDetails.value = libraryWithFloors
    }

    fun refreshLibraryLiveOccupancy() {
        viewModelScope.launch {
            val libs = allLibraries.value
            val floors = allLibraryFloors.value
            if (libs.isNotEmpty()) {
                // Apply a slight realistic variance to simulate live occupancy updates
                val random = java.util.Random()
                libs.forEach { lib ->
                    val variance = random.nextInt(9) - 4 // -4 to +4
                    val updatedSeats = (lib.availableSeats + variance).coerceIn(5, lib.totalCapacity - 10)
                    repository.updateLibrarySeatCount(lib.id, updatedSeats)
                }

                floors.forEach { floor ->
                    val floorVariance = random.nextInt(7) - 3 // -3 to +3
                    val updatedFloorSeats = (floor.availableFloorSeats + floorVariance).coerceIn(2, floor.totalFloorSeats - 5)
                    repository.updateFloorSeatCount(floor.id, updatedFloorSeats)
                }
            }
            Toast.makeText(getApplication(), "⚡ Live library seat counters synced via campus IoT sensors", Toast.LENGTH_SHORT).show()
        }
    }

    fun checkInToLibraryFloor(floor: LibraryFloorEntity, library: CampusLibraryEntity) {
        viewModelScope.launch {
            if (floor.availableFloorSeats > 0 && library.availableSeats > 0) {
                repository.updateFloorSeatCount(floor.id, floor.availableFloorSeats - 1)
                repository.updateLibrarySeatCount(library.id, library.availableSeats - 1)
                Toast.makeText(getApplication(), "✅ Checked into ${floor.floorName}. 1 desk reserved!", Toast.LENGTH_SHORT).show()
            } else {
                Toast.makeText(getApplication(), "No vacant desks on this floor!", Toast.LENGTH_SHORT).show()
            }
        }
    }

    fun releaseSeatOnLibraryFloor(floor: LibraryFloorEntity, library: CampusLibraryEntity) {
        viewModelScope.launch {
            repository.updateFloorSeatCount(floor.id, (floor.availableFloorSeats + 1).coerceAtMost(floor.totalFloorSeats))
            repository.updateLibrarySeatCount(library.id, (library.availableSeats + 1).coerceAtMost(library.totalCapacity))
            Toast.makeText(getApplication(), "Desk released on ${floor.floorName}. Thank you!", Toast.LENGTH_SHORT).show()
        }
    }

    fun navigateToLibraryBuilding(library: CampusLibraryEntity) {
        _selectedTab.value = NavigationTab.MAP_NAV
        Toast.makeText(getApplication(), "Pinpointed ${library.name} on Campus Map", Toast.LENGTH_SHORT).show()
    }

    // AI Campus Assistant
    fun sendChatMessage(query: String) {
        val q = query.trim()
        if (q.isBlank()) return

        val userMsg = ChatMessage(isUser = true, text = q)
        _chatMessages.value = _chatMessages.value + userMsg
        _isAssistantTyping.value = true

        viewModelScope.launch {
            val responseText = assistantService.askAssistant(
                query = q,
                schedules = allSchedules.value,
                exams = allExams.value,
                locations = allLocations.value,
                alerts = allAlerts.value,
                gpaSummary = gpaSummary.value,
                libraries = allLibraries.value
            )
            _chatMessages.value = _chatMessages.value + ChatMessage(isUser = false, text = responseText)
            _isAssistantTyping.value = false
        }
    }

    // Smart Alarm Management & Weather Sync
    fun refreshCampusWeather() {
        viewModelScope.launch {
            val weather = WeatherApiClient.fetchCampusWeather()
            _currentWeather.value = weather
        }
    }

    fun toggleSmartAlarmEnabled(enabled: Boolean) {
        _isSmartAlarmEnabled.value = enabled
        val status = if (enabled) "Smart Alarm Enabled (Auto-calculating wakeup)" else "Smart Alarm Disabled"
        Toast.makeText(getApplication(), status, Toast.LENGTH_SHORT).show()
    }

    fun updateSmartAlarmSettings(
        prepMinutes: Int,
        transitMinutes: Int,
        weatherAdjustmentEnabled: Boolean
    ) {
        _smartAlarmPrepMinutes.value = prepMinutes
        _smartAlarmTransitMinutes.value = transitMinutes
        _smartAlarmWeatherAdjustmentEnabled.value = weatherAdjustmentEnabled
        Toast.makeText(getApplication(), "Smart Alarm parameters updated!", Toast.LENGTH_SHORT).show()
    }

    fun calculateAlarmForSpecificDay(day: Int): SmartAlarmCalculation {
        val schedulesForDay = allSchedules.value.filter { it.dayOfWeek == day }
        return SmartAlarmManager.calculateSmartAlarm(
            schedulesForDay = schedulesForDay,
            weather = _currentWeather.value,
            basePrepMinutes = _smartAlarmPrepMinutes.value,
            baseTransitMinutes = _smartAlarmTransitMinutes.value,
            weatherAdjustmentEnabled = _smartAlarmWeatherAdjustmentEnabled.value,
            isAlarmEnabled = _isSmartAlarmEnabled.value,
            targetDay = day
        )
    }

    // Smart Leave-Time Alarm Simulation
    fun triggerSimulatedAlarm(title: String, venue: String, leaveTime: String) {
        _activeAlarmTrigger.value = "⏰ Departure Alarm: Time to leave for $title at $venue! Suggested departure was $leaveTime."
        vibratePhone()
    }

    fun dismissAlarm() {
        _activeAlarmTrigger.value = null
    }

    // Multi-Institution Tenant Operations
    fun completeOnboarding(institution: com.example.data.model.InstitutionProfile, importSampleData: Boolean = true) {
        _currentInstitution.value = institution
        _isSavingInstitution.value = true
        _shuttleRoutes.value = GhanaCampusCompanionData.getShuttlesForInstitution(institution.id)
        _campusDues.value = GhanaCampusCompanionData.getDuesForInstitution(institution.id)
        _lostAndFoundItems.value = GhanaCampusCompanionData.getLostAndFoundForInstitution(institution.id)
        _campusEvents.value = GhanaCampusCompanionData.getEventsForInstitution(institution.id)
        _studentProfile.value = _studentProfile.value.copy(
            institutionId = institution.id,
            email = "student@st.${institution.shortCode.lowercase()}.edu.gh"
        )
        viewModelScope.launch {
            try {
                preferencesRepository.saveSelectedInstitution(
                    institutionId = institution.id,
                    completedOnboarding = true,
                    importSampleData = importSampleData
                )
                repository.switchInstitutionData(
                    profile = institution,
                    replaceSchedules = importSampleData,
                    clearOldDataFirst = true
                )
                _isOnboardingCompleted.value = true
                Toast.makeText(
                    getApplication(),
                    "Akwaaba! Welcome to CampusCompanion for ${institution.shortCode}!",
                    Toast.LENGTH_SHORT
                ).show()
            } finally {
                _isSavingInstitution.value = false
            }
        }
    }

    fun resetOnboarding() {
        _isOnboardingCompleted.value = false
        viewModelScope.launch {
            preferencesRepository.resetOnboarding()
            Toast.makeText(getApplication(), "Returned to University Selection", Toast.LENGTH_SHORT).show()
        }
    }

    fun switchInstitution(institution: com.example.data.model.InstitutionProfile, importSampleData: Boolean = false) {
        _currentInstitution.value = institution
        _shuttleRoutes.value = GhanaCampusCompanionData.getShuttlesForInstitution(institution.id)
        _campusDues.value = GhanaCampusCompanionData.getDuesForInstitution(institution.id)
        _lostAndFoundItems.value = GhanaCampusCompanionData.getLostAndFoundForInstitution(institution.id)
        _campusEvents.value = GhanaCampusCompanionData.getEventsForInstitution(institution.id)
        _studentProfile.value = _studentProfile.value.copy(
            institutionId = institution.id,
            email = "student@st.${institution.shortCode.lowercase()}.edu.gh"
        )
        viewModelScope.launch {
            preferencesRepository.saveSelectedInstitution(
                institutionId = institution.id,
                completedOnboarding = true,
                importSampleData = importSampleData
            )
            repository.switchInstitutionData(institution, replaceSchedules = importSampleData)
            Toast.makeText(
                getApplication(),
                "Switched campus context to ${institution.shortCode} - ${institution.name}",
                Toast.LENGTH_SHORT
            ).show()
        }
    }

    // Student Profile & Companion Features Operations
    fun updateStudentProfile(profile: StudentProfile) {
        _studentProfile.value = profile
        Toast.makeText(getApplication(), "Student profile updated!", Toast.LENGTH_SHORT).show()
    }

    fun refreshShuttles() {
        _shuttleRoutes.value = GhanaCampusCompanionData.getShuttlesForInstitution(_currentInstitution.value.id)
        Toast.makeText(getApplication(), "Shuttle live locations refreshed", Toast.LENGTH_SHORT).show()
    }

    fun payCampusDue(
        dueId: String,
        momoNumber: String,
        provider: String
    ) {
        viewModelScope.launch {
            _isProcessingPayment.value = true
            kotlinx.coroutines.delay(1000)
            val targetDue = _campusDues.value.find { it.id == dueId }
            val itemTitle = targetDue?.title ?: "Campus Due Payment"
            val amount = targetDue?.amountCedis ?: 50.00
            val ref = "MM-${_currentInstitution.value.shortCode.uppercase()}-${(10000..99999).random()}"

            val receipt = MoMoPaymentReceipt(
                transactionRef = ref,
                itemTitle = itemTitle,
                amountCedis = amount,
                payerName = _studentProfile.value.name,
                studentId = _studentProfile.value.studentId,
                momoNumber = momoNumber,
                provider = provider
            )

            _campusDues.value = _campusDues.value.map {
                if (it.id == dueId) it.copy(isPaid = true, paymentReference = ref) else it
            }
            _paymentReceipts.value = listOf(receipt) + _paymentReceipts.value
            _lastPaymentReceipt.value = receipt
            _isProcessingPayment.value = false
            Toast.makeText(getApplication(), "Payment of GH₵ ${String.format("%.2f", amount)} approved via $provider!", Toast.LENGTH_LONG).show()
        }
    }

    fun clearLastReceipt() {
        _lastPaymentReceipt.value = null
    }

    fun reportLostAndFoundItem(item: LostAndFoundItem) {
        _lostAndFoundItems.value = listOf(item) + _lostAndFoundItems.value
        Toast.makeText(getApplication(), "Lost & Found notice published to campus!", Toast.LENGTH_SHORT).show()
    }

    fun markLostAndFoundItemClaimed(itemId: String) {
        _lostAndFoundItems.value = _lostAndFoundItems.value.map {
            if (it.id == itemId) it.copy(status = "CLAIMED") else it
        }
        Toast.makeText(getApplication(), "Item marked as resolved / claimed!", Toast.LENGTH_SHORT).show()
    }

    // Firebase Authentication Operations
    fun signInWithEmail(email: String, password: String, onSuccess: (() -> Unit)? = null) {
        if (email.isBlank() || password.isBlank()) {
            _authUiState.value = AuthResultState.Error("Please enter both email and password")
            return
        }
        viewModelScope.launch {
            _authUiState.value = AuthResultState.Loading
            val result = authManager.signInWithEmail(email, password)
            result.fold(
                onSuccess = { user ->
                    _authUiState.value = AuthResultState.Success(user, "Welcome back, ${user.displayName ?: user.email}!")
                    // Sync student profile if applicable
                    _studentProfile.value = _studentProfile.value.copy(
                        name = user.displayName ?: _studentProfile.value.name,
                        email = user.email ?: _studentProfile.value.email
                    )
                    Toast.makeText(getApplication(), "Signed in as ${user.email}", Toast.LENGTH_SHORT).show()
                    onSuccess?.invoke()
                },
                onFailure = { err ->
                    _authUiState.value = AuthResultState.Error(err.localizedMessage ?: "Sign-in failed. Please check credentials.")
                }
            )
        }
    }

    fun signUpWithEmail(
        email: String,
        password: String,
        displayName: String,
        onSuccess: (() -> Unit)? = null
    ) {
        if (email.isBlank() || password.isBlank() || displayName.isBlank()) {
            _authUiState.value = AuthResultState.Error("Please fill in all fields")
            return
        }
        if (password.length < 6) {
            _authUiState.value = AuthResultState.Error("Password must be at least 6 characters")
            return
        }
        viewModelScope.launch {
            _authUiState.value = AuthResultState.Loading
            val result = authManager.signUpWithEmail(email, password, displayName)
            result.fold(
                onSuccess = { user ->
                    _authUiState.value = AuthResultState.Success(user, "Account created successfully!")
                    _studentProfile.value = _studentProfile.value.copy(
                        name = displayName,
                        email = user.email ?: email
                    )
                    Toast.makeText(getApplication(), "Account created for ${user.email}", Toast.LENGTH_SHORT).show()
                    onSuccess?.invoke()
                },
                onFailure = { err ->
                    _authUiState.value = AuthResultState.Error(err.localizedMessage ?: "Account creation failed.")
                }
            )
        }
    }

    fun signInWithGoogle(context: Context, serverClientId: String? = null, onSuccess: (() -> Unit)? = null) {
        viewModelScope.launch {
            _authUiState.value = AuthResultState.Loading
            val result = authManager.signInWithGoogle(context, serverClientId)
            result.fold(
                onSuccess = { user ->
                    _authUiState.value = AuthResultState.Success(user, "Signed in with Google!")
                    _studentProfile.value = _studentProfile.value.copy(
                        name = user.displayName ?: _studentProfile.value.name,
                        email = user.email ?: _studentProfile.value.email
                    )
                    Toast.makeText(getApplication(), "Signed in as ${user.displayName ?: user.email}", Toast.LENGTH_SHORT).show()
                    onSuccess?.invoke()
                },
                onFailure = { err ->
                    _authUiState.value = AuthResultState.Error(err.localizedMessage ?: "Google Sign-In failed.")
                }
            )
        }
    }

    fun sendPasswordReset(email: String) {
        if (email.isBlank()) {
            _authUiState.value = AuthResultState.Error("Please enter your email to reset password")
            return
        }
        viewModelScope.launch {
            _authUiState.value = AuthResultState.Loading
            val result = authManager.sendPasswordResetEmail(email)
            result.fold(
                onSuccess = {
                    _authUiState.value = AuthResultState.Idle
                    Toast.makeText(getApplication(), "Password reset link sent to $email", Toast.LENGTH_LONG).show()
                },
                onFailure = { err ->
                    _authUiState.value = AuthResultState.Error(err.localizedMessage ?: "Could not send reset email.")
                }
            )
        }
    }

    fun signOutUser() {
        authManager.signOut()
        _authUiState.value = AuthResultState.Idle
        Toast.makeText(getApplication(), "Signed out successfully", Toast.LENGTH_SHORT).show()
    }

    fun resetAuthUiState() {
        _authUiState.value = AuthResultState.Idle
    }

    /**
     * Synchronize local Student Profile, Course Schedules, and Dues to Firebase Firestore.
     */
    fun syncAllToFirestore(onComplete: ((Boolean) -> Unit)? = null) {
        val user = firebaseUser.value
        if (user == null) {
            Toast.makeText(getApplication(), "Please sign in to sync with Firestore Cloud", Toast.LENGTH_SHORT).show()
            onComplete?.invoke(false)
            return
        }

        viewModelScope.launch {
            _isCloudSyncing.value = true
            try {
                // 1. Sync Profile
                firestoreRepository.saveStudentProfile(user.uid, _studentProfile.value)

                // 2. Sync Course Schedules
                val schedules = allSchedules.value
                if (schedules.isNotEmpty()) {
                    firestoreRepository.syncCourseSchedules(user.uid, schedules)
                }

                // 3. Sync Campus Dues
                val dues = _campusDues.value
                if (dues.isNotEmpty()) {
                    firestoreRepository.syncCampusDues(user.uid, dues)
                }

                Toast.makeText(getApplication(), "Cloud sync completed with Firestore!", Toast.LENGTH_SHORT).show()
                onComplete?.invoke(true)
            } catch (e: Exception) {
                Log.e("MainViewModel", "syncAllToFirestore error: ${e.message}", e)
                Toast.makeText(getApplication(), "Sync failed: ${e.localizedMessage}", Toast.LENGTH_SHORT).show()
                onComplete?.invoke(false)
            } finally {
                _isCloudSyncing.value = false
            }
        }
    }

    /**
     * Pull data from Firebase Firestore and update local state in real-time.
     */
    fun syncAllFromFirestore() {
        val user = firebaseUser.value ?: return
        viewModelScope.launch {
            _isCloudSyncing.value = true
            try {
                // 1. Pull Profile
                val profileResult = firestoreRepository.getStudentProfile(user.uid)
                profileResult.getOrNull()?.let { remoteProfile ->
                    _studentProfile.value = remoteProfile
                }

                Toast.makeText(getApplication(), "Synced latest data from Firestore Cloud", Toast.LENGTH_SHORT).show()
            } catch (e: Exception) {
                Log.e("MainViewModel", "syncAllFromFirestore error: ${e.message}", e)
            } finally {
                _isCloudSyncing.value = false
            }
        }
    }

    fun toggleEventRsvp(eventId: String) {
        _campusEvents.value = _campusEvents.value.map {
            if (it.id == eventId) {
                val newRsvp = !it.isRsvpd
                val newCount = if (newRsvp) it.attendeeCount + 1 else (it.attendeeCount - 1).coerceAtLeast(0)
                it.copy(isRsvpd = newRsvp, attendeeCount = newCount)
            } else it
        }
    }

    fun registerCustomInstitution(
        name: String,
        shortCode: String,
        city: String,
        region: String,
        motto: String,
        gradingSystem: com.example.data.model.GradingSystemType,
        portalName: String,
        portalUrl: String,
        primaryColorHex: Long = 0xFF1E3A8A
    ) {
        val newId = "custom_${System.currentTimeMillis()}"
        val newProfile = com.example.data.model.InstitutionProfile(
            id = newId,
            name = name,
            shortCode = shortCode.uppercase(),
            motto = motto.ifBlank { "Excellence and Knowledge" },
            city = city,
            region = region,
            primaryColorHex = primaryColorHex,
            secondaryColorHex = 0xFFD97706,
            accentColorHex = 0xFF0284C7,
            gradingSystem = gradingSystem,
            gradingMetricName = if (gradingSystem == com.example.data.model.GradingSystemType.KNUST_CWA) "CWA (%)" else "GPA (4.0 Scale)",
            honoursThresholds = if (gradingSystem == com.example.data.model.GradingSystemType.KNUST_CWA) {
                com.example.data.model.InstitutionRegistry.KNUST_PROFILE.honoursThresholds
            } else {
                com.example.data.model.InstitutionRegistry.UG_PROFILE.honoursThresholds
            },
            portals = listOf(
                com.example.data.model.InstitutionPortal(
                    id = "${newId}_portal",
                    name = portalName.ifBlank { "$shortCode Student Portal" },
                    description = "Official university student portal & web services",
                    url = portalUrl.ifBlank { "https://${shortCode.lowercase()}.edu.gh" },
                    category = "Student Records / SIS"
                )
            ),
            campusZones = listOf(
                com.example.data.model.InstitutionCampusZone("${newId}_main", "Main Campus", "MAIN", "Main academic quadrangle")
            ),
            defaultLocations = listOf(
                CampusLocationEntity(
                    id = "${shortCode}_LIB",
                    name = "$name Central Library",
                    shortCode = "LIB",
                    category = "Library",
                    mapX = 50f,
                    mapY = 45f,
                    description = "Main university library & study commons.",
                    floors = 3
                ),
                CampusLocationEntity(
                    id = "${shortCode}_AUD",
                    name = "$name Main Auditorium",
                    shortCode = "AUD",
                    category = "Lecture Hall",
                    mapX = 40f,
                    mapY = 35f,
                    description = "Multipurpose lecture and examination auditorium.",
                    floors = 2
                )
            ),
            sampleSchedules = emptyList(),
            sampleExams = emptyList(),
            studentPortalName = portalName.ifBlank { "Student Portal" },
            lmsName = "$shortCode LMS",
            libraryName = "$name Library",
            isCustom = true
        )

        _allInstitutions.value = _allInstitutions.value + newProfile
        switchInstitution(newProfile, importSampleData = false)
    }

    fun addCustomPortalToCurrentInstitution(
        name: String,
        url: String,
        category: String,
        description: String = ""
    ) {
        val current = _currentInstitution.value
        val newPortal = com.example.data.model.InstitutionPortal(
            id = "custom_portal_${System.currentTimeMillis()}",
            name = name,
            description = description.ifBlank { "Custom student academic resource link" },
            url = url,
            category = category
        )
        val updatedProfile = current.copy(
            portals = current.portals + newPortal
        )
        _currentInstitution.value = updatedProfile
        // Update in all institutions list too
        _allInstitutions.value = _allInstitutions.value.map {
            if (it.id == updatedProfile.id) updatedProfile else it
        }
        Toast.makeText(getApplication(), "Added $name to ${current.shortCode} portal gateway", Toast.LENGTH_SHORT).show()
    }

    private fun vibratePhone() {
        try {
            val context = getApplication<Application>()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val vibratorManager = context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager
                val vibrator = vibratorManager?.defaultVibrator
                vibrator?.vibrate(VibrationEffect.createOneShot(500, VibrationEffect.DEFAULT_AMPLITUDE))
            } else {
                @Suppress("DEPRECATION")
                val vibrator = context.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    vibrator?.vibrate(VibrationEffect.createOneShot(500, VibrationEffect.DEFAULT_AMPLITUDE))
                } else {
                    @Suppress("DEPRECATION")
                    vibrator?.vibrate(500)
                }
            }
        } catch (e: Exception) {
            // Ignore vibration error
        }
    }
}
