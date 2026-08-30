package com.example.ui

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.example.data.local.entity.AcademicEventType
import com.example.data.local.entity.AcademicScheduleEventEntity
import com.example.data.repository.AcademicScheduleRepository
import com.example.data.repository.IAcademicScheduleRepository
import com.example.data.worker.ClassReminderScheduler
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

/**
 * View mode for displaying academic schedules: standard list vs day-by-day calendar timeline.
 */
enum class ScheduleViewMode {
    LIST,
    DAY_CALENDAR
}

/**
 * UI state representing the current academic schedule, filters, search results, active selection, and view mode.
 */
data class AcademicScheduleUiState(
    val isLoading: Boolean = true,
    val viewMode: ScheduleViewMode = ScheduleViewMode.LIST,
    val allEvents: List<AcademicScheduleEventEntity> = emptyList(),
    val filteredEvents: List<AcademicScheduleEventEntity> = emptyList(),
    val todayEvents: List<AcademicScheduleEventEntity> = emptyList(),
    val upcomingExams: List<AcademicScheduleEventEntity> = emptyList(),
    val studySessions: List<AcademicScheduleEventEntity> = emptyList(),
    val weeklyClasses: List<AcademicScheduleEventEntity> = emptyList(),
    val selectedFilterType: AcademicEventType? = null,
    val selectedDayOfWeek: Int? = null, // 1 = Monday .. 7 = Sunday
    val searchQuery: String = "",
    val selectedEvent: AcademicScheduleEventEntity? = null,
    val userMessage: String? = null,
    val totalEventCount: Int = 0,
    val completedEventCount: Int = 0,
    val pendingEventCount: Int = 0
)

/**
 * ViewModel that uses [IAcademicScheduleRepository] to manage and expose academic schedule state
 * (classes, exams, study sessions, labs) as a reactive [StateFlow] for Jetpack Compose UI,
 * with automated WorkManager background scheduling for 15-minute advance class reminders.
 */
class AcademicScheduleViewModel(
    application: Application,
    private val repository: IAcademicScheduleRepository = AcademicScheduleRepository.getInstance(application)
) : AndroidViewModel(application) {

    private val _viewMode = MutableStateFlow(ScheduleViewMode.LIST)
    val viewMode: StateFlow<ScheduleViewMode> = _viewMode.asStateFlow()

    private val _searchQuery = MutableStateFlow("")
    val searchQuery: StateFlow<String> = _searchQuery.asStateFlow()

    private val _selectedFilterType = MutableStateFlow<AcademicEventType?>(null)
    val selectedFilterType: StateFlow<AcademicEventType?> = _selectedFilterType.asStateFlow()

    private val _selectedDayOfWeek = MutableStateFlow<Int?>(null)
    val selectedDayOfWeek: StateFlow<Int?> = _selectedDayOfWeek.asStateFlow()

    private val _selectedEvent = MutableStateFlow<AcademicScheduleEventEntity?>(null)
    val selectedEvent: StateFlow<AcademicScheduleEventEntity?> = _selectedEvent.asStateFlow()

    private val _userMessage = MutableStateFlow<String?>(null)
    val userMessage: StateFlow<String?> = _userMessage.asStateFlow()

    init {
        // Automatically synchronize WorkManager 15-minute advance reminder tasks
        viewModelScope.launch {
            repository.allEvents.collect { events ->
                ClassReminderScheduler.syncAcademicEvents(getApplication(), events)
            }
        }
    }

    val uiState: StateFlow<AcademicScheduleUiState> = combine(
        repository.allEvents,
        repository.todayEvents,
        repository.upcomingExams,
        repository.studySessions,
        repository.weeklyClasses,
        _viewMode,
        _selectedFilterType,
        _selectedDayOfWeek,
        _searchQuery,
        _selectedEvent,
        _userMessage
    ) { params ->
        @Suppress("UNCHECKED_CAST")
        val allEvents = params[0] as List<AcademicScheduleEventEntity>
        @Suppress("UNCHECKED_CAST")
        val todayEvents = params[1] as List<AcademicScheduleEventEntity>
        @Suppress("UNCHECKED_CAST")
        val upcomingExams = params[2] as List<AcademicScheduleEventEntity>
        @Suppress("UNCHECKED_CAST")
        val studySessions = params[3] as List<AcademicScheduleEventEntity>
        @Suppress("UNCHECKED_CAST")
        val weeklyClasses = params[4] as List<AcademicScheduleEventEntity>
        val currentViewMode = params[5] as ScheduleViewMode
        val filterType = params[6] as? AcademicEventType
        val dayOfWeek = params[7] as? Int
        val query = params[8] as String
        val selectedEvent = params[9] as? AcademicScheduleEventEntity
        val message = params[10] as? String

        // Compute filtered events based on type, day of week, and search query
        val filtered = allEvents.filter { event ->
            val matchesType = filterType == null || event.eventType.equals(filterType.name, ignoreCase = true)
            val matchesDay = dayOfWeek == null || (event.dayOfWeek == dayOfWeek)
            val matchesQuery = query.isBlank() ||
                    event.title.contains(query, ignoreCase = true) ||
                    event.courseCode.contains(query, ignoreCase = true) ||
                    event.venue.contains(query, ignoreCase = true) ||
                    event.notes.contains(query, ignoreCase = true) ||
                    event.instructorOrLead.contains(query, ignoreCase = true)

            matchesType && matchesDay && matchesQuery
        }

        val completedCount = allEvents.count { it.isCompleted }
        val pendingCount = allEvents.size - completedCount

        AcademicScheduleUiState(
            isLoading = false,
            viewMode = currentViewMode,
            allEvents = allEvents,
            filteredEvents = filtered,
            todayEvents = todayEvents,
            upcomingExams = upcomingExams,
            studySessions = studySessions,
            weeklyClasses = weeklyClasses,
            selectedFilterType = filterType,
            selectedDayOfWeek = dayOfWeek,
            searchQuery = query,
            selectedEvent = selectedEvent,
            userMessage = message,
            totalEventCount = allEvents.size,
            completedEventCount = completedCount,
            pendingEventCount = pendingCount
        )
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5000),
        initialValue = AcademicScheduleUiState(isLoading = true)
    )

    fun setViewMode(mode: ScheduleViewMode) {
        _viewMode.value = mode
    }

    fun toggleViewMode() {
        _viewMode.value = if (_viewMode.value == ScheduleViewMode.LIST) {
            ScheduleViewMode.DAY_CALENDAR
        } else {
            ScheduleViewMode.LIST
        }
    }

    fun setSearchQuery(query: String) {
        _searchQuery.value = query
    }

    fun setFilterType(type: AcademicEventType?) {
        _selectedFilterType.value = type
    }

    fun setDayOfWeekFilter(day: Int?) {
        _selectedDayOfWeek.value = day
    }

    fun clearFilters() {
        _selectedFilterType.value = null
        _selectedDayOfWeek.value = null
        _searchQuery.value = ""
    }

    fun selectEvent(event: AcademicScheduleEventEntity?) {
        _selectedEvent.value = event
    }

    fun clearUserMessage() {
        _userMessage.value = null
    }

    fun addEvent(event: AcademicScheduleEventEntity) {
        viewModelScope.launch {
            try {
                val id = repository.insertEvent(event)
                val persistedEvent = event.copy(id = id)
                ClassReminderScheduler.scheduleClassReminder(getApplication(), persistedEvent)
                _userMessage.value = "Schedule event '${event.title}' added (15m reminder active)"
            } catch (e: Exception) {
                _userMessage.value = "Failed to add event: ${e.localizedMessage}"
            }
        }
    }

    fun createQuickEvent(
        title: String,
        courseCode: String,
        eventType: AcademicEventType,
        startTime: String,
        endTime: String,
        venue: String,
        dayOfWeek: Int? = null,
        eventDate: String? = null,
        notes: String = "",
        instructorOrLead: String = "",
        colorHex: Long = 0xFF1E3A8A
    ) {
        val newEvent = AcademicScheduleEventEntity(
            title = title,
            courseCode = courseCode,
            eventType = eventType.name,
            dayOfWeek = dayOfWeek,
            eventDate = eventDate,
            startTime = startTime,
            endTime = endTime,
            venue = venue,
            instructorOrLead = instructorOrLead,
            notes = notes,
            colorHex = colorHex,
            isRecurring = dayOfWeek != null && eventDate == null
        )
        addEvent(newEvent)
    }

    fun updateEvent(event: AcademicScheduleEventEntity) {
        viewModelScope.launch {
            try {
                repository.updateEvent(event)
                ClassReminderScheduler.scheduleClassReminder(getApplication(), event)
                _userMessage.value = "Updated '${event.title}'"
                if (_selectedEvent.value?.id == event.id) {
                    _selectedEvent.value = event
                }
            } catch (e: Exception) {
                _userMessage.value = "Failed to update event: ${e.localizedMessage}"
            }
        }
    }

    fun deleteEvent(event: AcademicScheduleEventEntity) {
        viewModelScope.launch {
            try {
                repository.deleteEvent(event)
                ClassReminderScheduler.cancelClassReminder(getApplication(), event.id)
                if (_selectedEvent.value?.id == event.id) {
                    _selectedEvent.value = null
                }
                _userMessage.value = "Deleted '${event.title}'"
            } catch (e: Exception) {
                _userMessage.value = "Failed to delete event: ${e.localizedMessage}"
            }
        }
    }

    fun deleteEventById(id: Long) {
        viewModelScope.launch {
            try {
                repository.deleteEventById(id)
                ClassReminderScheduler.cancelClassReminder(getApplication(), id)
                if (_selectedEvent.value?.id == id) {
                    _selectedEvent.value = null
                }
                _userMessage.value = "Event deleted"
            } catch (e: Exception) {
                _userMessage.value = "Failed to delete event: ${e.localizedMessage}"
            }
        }
    }

    fun toggleEventCompletion(id: Long, completed: Boolean) {
        viewModelScope.launch {
            try {
                repository.setEventCompleted(id, completed)
                if (completed) {
                    ClassReminderScheduler.cancelClassReminder(getApplication(), id)
                }
                _userMessage.value = if (completed) "Marked as completed" else "Marked as pending"
            } catch (e: Exception) {
                _userMessage.value = "Failed to update status: ${e.localizedMessage}"
            }
        }
    }

    fun toggleAlarm(id: Long, enabled: Boolean) {
        viewModelScope.launch {
            try {
                repository.toggleAlarm(id, enabled)
                if (!enabled) {
                    ClassReminderScheduler.cancelClassReminder(getApplication(), id)
                }
                _userMessage.value = if (enabled) "15m class reminder enabled" else "Reminder disabled"
            } catch (e: Exception) {
                _userMessage.value = "Failed to toggle reminder: ${e.localizedMessage}"
            }
        }
    }

    fun updateVenueAndNotes(id: Long, newVenue: String, notes: String) {
        viewModelScope.launch {
            try {
                repository.updateVenueAndNotes(id, newVenue, notes)
                _userMessage.value = "Venue and notes updated"
            } catch (e: Exception) {
                _userMessage.value = "Failed to update: ${e.localizedMessage}"
            }
        }
    }

    /**
     * Factory for creating [AcademicScheduleViewModel] with a custom [IAcademicScheduleRepository].
     */
    companion object {
        fun provideFactory(
            application: Application,
            repository: IAcademicScheduleRepository
        ): ViewModelProvider.Factory = object : ViewModelProvider.Factory {
            @Suppress("UNCHECKED_CAST")
            override fun <T : ViewModel> create(modelClass: Class<T>): T {
                if (modelClass.isAssignableFrom(AcademicScheduleViewModel::class.java)) {
                    return AcademicScheduleViewModel(application, repository) as T
                }
                throw IllegalArgumentException("Unknown ViewModel class: ${modelClass.name}")
            }
        }
    }
}
