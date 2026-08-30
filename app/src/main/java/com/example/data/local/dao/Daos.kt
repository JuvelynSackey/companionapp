package com.example.data.local.dao

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
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

@Dao
interface CourseScheduleDao {
    @Query("SELECT * FROM course_schedules ORDER BY dayOfWeek ASC, startTime ASC")
    fun getAllSchedules(): Flow<List<CourseScheduleEntity>>

    @Query("SELECT * FROM course_schedules WHERE dayOfWeek = :day ORDER BY startTime ASC")
    fun getSchedulesForDay(day: Int): Flow<List<CourseScheduleEntity>>

    @Query("SELECT * FROM course_schedules WHERE id = :id")
    suspend fun getScheduleById(id: Long): CourseScheduleEntity?

    @Query("SELECT * FROM course_schedules ORDER BY dayOfWeek ASC, startTime ASC")
    suspend fun getAllSchedulesSnapshot(): List<CourseScheduleEntity>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertSchedule(schedule: CourseScheduleEntity): Long

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertSchedules(schedules: List<CourseScheduleEntity>)

    @Update
    suspend fun updateSchedule(schedule: CourseScheduleEntity)

    @Delete
    suspend fun deleteSchedule(schedule: CourseScheduleEntity)

    @Query("UPDATE course_schedules SET venue = :newVenue, isCancelledOrMoved = 1, changeNote = :note WHERE id = :id")
    suspend fun updateVenue(id: Long, newVenue: String, note: String)

    @Query("UPDATE course_schedules SET isAlarmEnabled = :enabled WHERE id = :id")
    suspend fun toggleAlarm(id: Long, enabled: Boolean)

    @Query("DELETE FROM course_schedules")
    suspend fun deleteAllSchedules()
}

@Dao
interface ExamScheduleDao {
    @Query("SELECT * FROM exam_schedules ORDER BY examDate ASC, startTime ASC")
    fun getAllExams(): Flow<List<ExamScheduleEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertExam(exam: ExamScheduleEntity): Long

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertExams(exams: List<ExamScheduleEntity>)

    @Update
    suspend fun updateExam(exam: ExamScheduleEntity)

    @Delete
    suspend fun deleteExam(exam: ExamScheduleEntity)

    @Query("UPDATE exam_schedules SET isAlarmSet = :enabled WHERE id = :id")
    suspend fun toggleExamAlarm(id: Long, enabled: Boolean)

    @Query("DELETE FROM exam_schedules")
    suspend fun deleteAllExams()
}

@Dao
interface CampusLocationDao {
    @Query("SELECT * FROM campus_locations ORDER BY name ASC")
    fun getAllLocations(): Flow<List<CampusLocationEntity>>

    @Query("SELECT * FROM campus_locations WHERE category = :category ORDER BY name ASC")
    fun getLocationsByCategory(category: String): Flow<List<CampusLocationEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertLocation(location: CampusLocationEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertLocations(locations: List<CampusLocationEntity>)

    @Update
    suspend fun updateLocation(location: CampusLocationEntity)

    @Delete
    suspend fun deleteLocation(location: CampusLocationEntity)

    @Query("DELETE FROM campus_locations")
    suspend fun deleteAllLocations()
}

@Dao
interface CampusAlertDao {
    @Query("SELECT * FROM campus_alerts ORDER BY isPinned DESC, timestamp DESC")
    fun getAllAlerts(): Flow<List<CampusAlertEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAlert(alert: CampusAlertEntity): Long

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAlerts(alerts: List<CampusAlertEntity>)

    @Query("UPDATE campus_alerts SET isRead = 1 WHERE id = :id")
    suspend fun markAsRead(id: Long)

    @Delete
    suspend fun deleteAlert(alert: CampusAlertEntity)
}

@Dao
interface GpaCourseDao {
    @Query("SELECT * FROM gpa_courses ORDER BY semesterName ASC, courseCode ASC")
    fun getAllGpaCourses(): Flow<List<GpaCourseEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertCourse(course: GpaCourseEntity): Long

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertCourses(courses: List<GpaCourseEntity>)

    @Update
    suspend fun updateCourse(course: GpaCourseEntity)

    @Delete
    suspend fun deleteCourse(course: GpaCourseEntity)
}

@Dao
interface CourseAssessmentDao {
    @Query("SELECT * FROM course_assessments ORDER BY date DESC, id DESC")
    fun getAllAssessments(): Flow<List<CourseAssessmentEntity>>

    @Query("SELECT * FROM course_assessments WHERE courseId = :courseId ORDER BY date ASC, id ASC")
    fun getAssessmentsForCourse(courseId: Long): Flow<List<CourseAssessmentEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAssessment(assessment: CourseAssessmentEntity): Long

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAssessments(assessments: List<CourseAssessmentEntity>)

    @Update
    suspend fun updateAssessment(assessment: CourseAssessmentEntity)

    @Delete
    suspend fun deleteAssessment(assessment: CourseAssessmentEntity)

    @Query("DELETE FROM course_assessments WHERE courseId = :courseId")
    suspend fun deleteAssessmentsForCourse(courseId: Long)
}

@Dao
interface StudyResourceDao {
    @Query("SELECT * FROM study_resources ORDER BY isBookmarked DESC, year DESC")
    fun getAllResources(): Flow<List<StudyResourceEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertResource(resource: StudyResourceEntity): Long

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertResources(resources: List<StudyResourceEntity>)

    @Query("UPDATE study_resources SET isBookmarked = :bookmarked WHERE id = :id")
    suspend fun toggleBookmark(id: Long, bookmarked: Boolean)

    @Query("UPDATE study_resources SET downloadCount = downloadCount + 1 WHERE id = :id")
    suspend fun incrementDownload(id: Long)

    @Delete
    suspend fun deleteResource(resource: StudyResourceEntity)
}

@Dao
interface CampusLibraryDao {
    @Query("SELECT * FROM campus_libraries ORDER BY name ASC")
    fun getAllLibraries(): Flow<List<CampusLibraryEntity>>

    @Query("SELECT * FROM campus_libraries WHERE id = :id")
    fun getLibraryById(id: String): Flow<CampusLibraryEntity?>

    @Query("SELECT * FROM library_floors WHERE libraryId = :libraryId ORDER BY floorNumber ASC")
    fun getFloorsForLibrary(libraryId: String): Flow<List<LibraryFloorEntity>>

    @Query("SELECT * FROM library_floors ORDER BY libraryId ASC, floorNumber ASC")
    fun getAllFloors(): Flow<List<LibraryFloorEntity>>

    @Query("SELECT * FROM campus_libraries WHERE name LIKE '%' || :query || '%' OR campusZone LIKE '%' || :query || '%' OR description LIKE '%' || :query || '%'")
    fun searchLibraries(query: String): Flow<List<CampusLibraryEntity>>

    @Query("SELECT * FROM campus_libraries ORDER BY name ASC")
    suspend fun getAllLibrariesSnapshot(): List<CampusLibraryEntity>

    @Query("SELECT * FROM campus_libraries WHERE name LIKE '%' || :query || '%' OR campusZone LIKE '%' || :query || '%' OR description LIKE '%' || :query || '%'")
    suspend fun searchLibrariesSnapshot(query: String): List<CampusLibraryEntity>

    @Query("SELECT * FROM library_floors WHERE libraryId = :libraryId ORDER BY floorNumber ASC")
    suspend fun getFloorsForLibrarySnapshot(libraryId: String): List<LibraryFloorEntity>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertLibrary(library: CampusLibraryEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertLibraries(libraries: List<CampusLibraryEntity>)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertFloor(floor: LibraryFloorEntity): Long

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertFloors(floors: List<LibraryFloorEntity>)

    @Update
    suspend fun updateLibrary(library: CampusLibraryEntity)

    @Update
    suspend fun updateFloor(floor: LibraryFloorEntity)

    @Query("UPDATE campus_libraries SET availableSeats = :availableSeats WHERE id = :id")
    suspend fun updateLibraryAvailableSeats(id: String, availableSeats: Int)

    @Query("UPDATE library_floors SET availableFloorSeats = :availableSeats WHERE id = :floorId")
    suspend fun updateFloorAvailableSeats(floorId: Long, availableSeats: Int)

    @Delete
    suspend fun deleteLibrary(library: CampusLibraryEntity)
}

@Dao
interface AcademicScheduleEventDao {
    @Query("SELECT * FROM academic_schedule_events ORDER BY eventDate ASC, dayOfWeek ASC, startTime ASC")
    fun getAllEvents(): Flow<List<AcademicScheduleEventEntity>>

    @Query("SELECT * FROM academic_schedule_events WHERE eventType = :eventType ORDER BY eventDate ASC, dayOfWeek ASC, startTime ASC")
    fun getEventsByType(eventType: String): Flow<List<AcademicScheduleEventEntity>>

    @Query("SELECT * FROM academic_schedule_events WHERE dayOfWeek = :dayOfWeek ORDER BY startTime ASC")
    fun getRecurringEventsForDay(dayOfWeek: Int): Flow<List<AcademicScheduleEventEntity>>

    @Query("SELECT * FROM academic_schedule_events WHERE eventDate = :date ORDER BY startTime ASC")
    fun getEventsForDate(date: String): Flow<List<AcademicScheduleEventEntity>>

    @Query("SELECT * FROM academic_schedule_events WHERE courseCode = :courseCode ORDER BY eventDate ASC, startTime ASC")
    fun getEventsForCourse(courseCode: String): Flow<List<AcademicScheduleEventEntity>>

    @Query("SELECT * FROM academic_schedule_events WHERE title LIKE '%' || :query || '%' OR courseCode LIKE '%' || :query || '%' OR venue LIKE '%' || :query || '%' OR notes LIKE '%' || :query || '%'")
    fun searchEvents(query: String): Flow<List<AcademicScheduleEventEntity>>

    @Query("SELECT * FROM academic_schedule_events WHERE id = :id")
    fun getEventById(id: Long): Flow<AcademicScheduleEventEntity?>

    @Query("SELECT * FROM academic_schedule_events WHERE id = :id")
    suspend fun getEventByIdSnapshot(id: Long): AcademicScheduleEventEntity?

    @Query("SELECT * FROM academic_schedule_events ORDER BY eventDate ASC, dayOfWeek ASC, startTime ASC")
    suspend fun getAllEventsSnapshot(): List<AcademicScheduleEventEntity>

    @Query("SELECT * FROM academic_schedule_events WHERE eventType = :eventType")
    suspend fun getEventsByTypeSnapshot(eventType: String): List<AcademicScheduleEventEntity>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertEvent(event: AcademicScheduleEventEntity): Long

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertEvents(events: List<AcademicScheduleEventEntity>): List<Long>

    @Update
    suspend fun updateEvent(event: AcademicScheduleEventEntity)

    @Delete
    suspend fun deleteEvent(event: AcademicScheduleEventEntity)

    @Query("DELETE FROM academic_schedule_events WHERE id = :id")
    suspend fun deleteEventById(id: Long)

    @Query("UPDATE academic_schedule_events SET isCompleted = :isCompleted WHERE id = :id")
    suspend fun setEventCompleted(id: Long, isCompleted: Boolean)

    @Query("UPDATE academic_schedule_events SET isAlarmEnabled = :enabled WHERE id = :id")
    suspend fun toggleAlarm(id: Long, enabled: Boolean)

    @Query("UPDATE academic_schedule_events SET venue = :newVenue, notes = :notes WHERE id = :id")
    suspend fun updateVenueAndNotes(id: Long, newVenue: String, notes: String)
}

