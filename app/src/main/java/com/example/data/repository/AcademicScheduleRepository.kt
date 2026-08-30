package com.example.data.repository

import android.content.Context
import com.example.data.local.AppDatabase
import com.example.data.local.dao.AcademicScheduleEventDao
import com.example.data.local.entity.AcademicEventType
import com.example.data.local.entity.AcademicScheduleEventEntity
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.withContext
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

/**
 * Repository interface defining abstractions for academic schedule management.
 */
interface IAcademicScheduleRepository {
    val allEvents: Flow<List<AcademicScheduleEventEntity>>
    val upcomingExams: Flow<List<AcademicScheduleEventEntity>>
    val todayEvents: Flow<List<AcademicScheduleEventEntity>>
    val studySessions: Flow<List<AcademicScheduleEventEntity>>
    val weeklyClasses: Flow<List<AcademicScheduleEventEntity>>

    fun getEventsByType(type: AcademicEventType): Flow<List<AcademicScheduleEventEntity>>
    fun getEventsByType(typeString: String): Flow<List<AcademicScheduleEventEntity>>
    fun getRecurringEventsForDay(dayOfWeek: Int): Flow<List<AcademicScheduleEventEntity>>
    fun getEventsForDate(dateIso: String): Flow<List<AcademicScheduleEventEntity>>
    fun getEventsForCourse(courseCode: String): Flow<List<AcademicScheduleEventEntity>>
    fun searchEvents(query: String): Flow<List<AcademicScheduleEventEntity>>
    fun getEventById(id: Long): Flow<AcademicScheduleEventEntity?>

    suspend fun insertEvent(event: AcademicScheduleEventEntity): Long
    suspend fun insertEvents(events: List<AcademicScheduleEventEntity>): List<Long>
    suspend fun updateEvent(event: AcademicScheduleEventEntity)
    suspend fun deleteEvent(event: AcademicScheduleEventEntity)
    suspend fun deleteEventById(id: Long)
    suspend fun setEventCompleted(id: Long, completed: Boolean)
    suspend fun toggleAlarm(id: Long, enabled: Boolean)
    suspend fun updateVenueAndNotes(id: Long, newVenue: String, notes: String)
    suspend fun getAllEventsSnapshot(): List<AcademicScheduleEventEntity>
    suspend fun getEventsByTypeSnapshot(eventType: String): List<AcademicScheduleEventEntity>
}

/**
 * Repository implementation for managing and abstracting access to [AcademicScheduleEventDao]
 * backed by the local Room [AppDatabase].
 */
class AcademicScheduleRepository(
    private val dao: AcademicScheduleEventDao
) : IAcademicScheduleRepository {

    override val allEvents: Flow<List<AcademicScheduleEventEntity>> =
        dao.getAllEvents().flowOn(Dispatchers.IO)

    override val upcomingExams: Flow<List<AcademicScheduleEventEntity>> =
        dao.getEventsByType(AcademicEventType.EXAM.name)
            .map { list ->
                val todayStr = getTodayIsoDate()
                list.filter { event ->
                    event.eventDate == null || event.eventDate >= todayStr
                }.sortedBy { it.eventDate ?: "" }
            }
            .flowOn(Dispatchers.IO)

    override val todayEvents: Flow<List<AcademicScheduleEventEntity>> =
        dao.getAllEvents()
            .map { list ->
                val currentDayOfWeek = getCurrentDayOfWeek() // 1 = Monday .. 7 = Sunday
                val todayStr = getTodayIsoDate()
                list.filter { event ->
                    (event.isRecurring && event.dayOfWeek == currentDayOfWeek) ||
                            (event.eventDate != null && event.eventDate == todayStr)
                }.sortedBy { it.startTime }
            }
            .flowOn(Dispatchers.IO)

    override val studySessions: Flow<List<AcademicScheduleEventEntity>> =
        dao.getEventsByType(AcademicEventType.STUDY_SESSION.name)
            .flowOn(Dispatchers.IO)

    override val weeklyClasses: Flow<List<AcademicScheduleEventEntity>> =
        dao.getEventsByType(AcademicEventType.CLASS.name)
            .flowOn(Dispatchers.IO)

    override fun getEventsByType(type: AcademicEventType): Flow<List<AcademicScheduleEventEntity>> =
        dao.getEventsByType(type.name).flowOn(Dispatchers.IO)

    override fun getEventsByType(typeString: String): Flow<List<AcademicScheduleEventEntity>> =
        dao.getEventsByType(typeString).flowOn(Dispatchers.IO)

    override fun getRecurringEventsForDay(dayOfWeek: Int): Flow<List<AcademicScheduleEventEntity>> =
        dao.getRecurringEventsForDay(dayOfWeek).flowOn(Dispatchers.IO)

    override fun getEventsForDate(dateIso: String): Flow<List<AcademicScheduleEventEntity>> =
        dao.getEventsForDate(dateIso).flowOn(Dispatchers.IO)

    override fun getEventsForCourse(courseCode: String): Flow<List<AcademicScheduleEventEntity>> =
        dao.getEventsForCourse(courseCode).flowOn(Dispatchers.IO)

    override fun searchEvents(query: String): Flow<List<AcademicScheduleEventEntity>> =
        dao.searchEvents(query.trim()).flowOn(Dispatchers.IO)

    override fun getEventById(id: Long): Flow<AcademicScheduleEventEntity?> =
        dao.getEventById(id).flowOn(Dispatchers.IO)

    override suspend fun insertEvent(event: AcademicScheduleEventEntity): Long =
        withContext(Dispatchers.IO) {
            dao.insertEvent(event)
        }

    override suspend fun insertEvents(events: List<AcademicScheduleEventEntity>): List<Long> =
        withContext(Dispatchers.IO) {
            dao.insertEvents(events)
        }

    override suspend fun updateEvent(event: AcademicScheduleEventEntity) =
        withContext(Dispatchers.IO) {
            dao.updateEvent(event)
        }

    override suspend fun deleteEvent(event: AcademicScheduleEventEntity) =
        withContext(Dispatchers.IO) {
            dao.deleteEvent(event)
        }

    override suspend fun deleteEventById(id: Long) =
        withContext(Dispatchers.IO) {
            dao.deleteEventById(id)
        }

    override suspend fun setEventCompleted(id: Long, completed: Boolean) =
        withContext(Dispatchers.IO) {
            dao.setEventCompleted(id, completed)
        }

    override suspend fun toggleAlarm(id: Long, enabled: Boolean) =
        withContext(Dispatchers.IO) {
            dao.toggleAlarm(id, enabled)
        }

    override suspend fun updateVenueAndNotes(id: Long, newVenue: String, notes: String) =
        withContext(Dispatchers.IO) {
            dao.updateVenueAndNotes(id, newVenue, notes)
        }

    override suspend fun getAllEventsSnapshot(): List<AcademicScheduleEventEntity> =
        withContext(Dispatchers.IO) {
            dao.getAllEventsSnapshot()
        }

    override suspend fun getEventsByTypeSnapshot(eventType: String): List<AcademicScheduleEventEntity> =
        withContext(Dispatchers.IO) {
            dao.getEventsByTypeSnapshot(eventType)
        }

    companion object {
        @Volatile
        private var INSTANCE: AcademicScheduleRepository? = null

        fun getInstance(context: Context): AcademicScheduleRepository {
            return INSTANCE ?: synchronized(this) {
                val db = AppDatabase.getDatabase(context)
                val instance = AcademicScheduleRepository(db.academicScheduleEventDao())
                INSTANCE = instance
                instance
            }
        }

        fun getInstance(dao: AcademicScheduleEventDao): AcademicScheduleRepository {
            return INSTANCE ?: synchronized(this) {
                val instance = AcademicScheduleRepository(dao)
                INSTANCE = instance
                instance
            }
        }

        private fun getTodayIsoDate(): String {
            val sdf = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())
            return sdf.format(Date())
        }

        private fun getCurrentDayOfWeek(): Int {
            val cal = Calendar.getInstance()
            return when (cal.get(Calendar.DAY_OF_WEEK)) {
                Calendar.MONDAY -> 1
                Calendar.TUESDAY -> 2
                Calendar.WEDNESDAY -> 3
                Calendar.THURSDAY -> 4
                Calendar.FRIDAY -> 5
                Calendar.SATURDAY -> 6
                Calendar.SUNDAY -> 7
                else -> 1
            }
        }
    }
}
