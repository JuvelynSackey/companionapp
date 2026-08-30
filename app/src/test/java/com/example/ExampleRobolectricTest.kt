package com.example

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import com.example.data.export.IcsCalendarExporter
import com.example.data.export.ScheduleExportOptions
import com.example.data.local.entity.CourseAssessmentEntity
import com.example.data.local.entity.CourseScheduleEntity
import com.example.data.local.entity.ExamScheduleEntity
import com.example.data.local.entity.GpaCourseEntity
import com.example.data.repository.CampusRepository
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [36])
class ExampleRobolectricTest {

  @Test
  fun `read string from context`() {
    val context = ApplicationProvider.getApplicationContext<Context>()
    val appName = context.getString(R.string.app_name)
    assertEquals("Campus Companion", appName)
  }

  @Test
  fun `test course weighted assessment calculation`() {
    val course = GpaCourseEntity(
      id = 1L,
      semesterName = "Year 3 - Semester 2",
      courseCode = "CSCD 302",
      courseTitle = "Software Engineering",
      creditHours = 3,
      grade = "A",
      gradePoint = 4.0,
      targetGrade = "A",
      isWeightedFromAssessments = true
    )

    val assessments = listOf(
      CourseAssessmentEntity(
        id = 101L,
        courseId = 1L,
        title = "Midterm Exam",
        category = "Exam",
        scoreAchieved = 27.0,
        maxScore = 30.0, // 90% -> 22.5% contribution
        weightPercentage = 25.0
      ),
      CourseAssessmentEntity(
        id = 102L,
        courseId = 1L,
        title = "Project Sprint 1",
        category = "Project",
        scoreAchieved = 19.0,
        maxScore = 20.0, // 95% -> 19.0% contribution
        weightPercentage = 20.0
      ),
      CourseAssessmentEntity(
        id = 103L,
        courseId = 1L,
        title = "Lab Practicals",
        category = "Lab",
        scoreAchieved = 14.0,
        maxScore = 15.0, // 93.3% -> 14.0% contribution
        weightPercentage = 15.0
      )
    )

    val summary = CampusRepository.calculateCourseWeightedSummary(course, assessments)
    assertEquals(60.0, summary.totalWeightAssigned, 0.01)
    assertEquals(40.0, summary.remainingWeight, 0.01)
    assertEquals(55.5, summary.currentWeightedScore, 0.1) // 22.5 + 19.0 + 14.0 = 55.5%
    assertEquals("A", summary.letterGrade)
    assertEquals(4.0, summary.gradePoint, 0.01)

    // For target A (threshold 80.0%), needed on remaining 40% is (80.0 - 55.5) / 40 * 100 = 61.25%
    assertNotNull(summary.scoreNeededOnRemainingForTarget)
    assertEquals(61.3, summary.scoreNeededOnRemainingForTarget ?: 0.0, 0.2)
  }

  @Test
  fun `test ics calendar export generation`() {
    val sampleSchedules = listOf(
      CourseScheduleEntity(
        id = 1L,
        courseCode = "CSCD 302",
        courseTitle = "Software Engineering",
        lecturer = "Dr. Mensah",
        dayOfWeek = 1, // Monday
        startTime = "08:30",
        endTime = "10:30",
        venue = "KAB 1",
        creditHours = 3
      ),
      CourseScheduleEntity(
        id = 2L,
        courseCode = "MATH 354",
        courseTitle = "Discrete Structures",
        lecturer = "Prof. Osei",
        dayOfWeek = 2, // Tuesday
        startTime = "11:30",
        endTime = "13:30",
        venue = "Math Dept Rm 12",
        creditHours = 3
      )
    )

    val sampleExams = listOf(
      ExamScheduleEntity(
        id = 10L,
        courseCode = "CSCD 302",
        courseTitle = "Software Engineering",
        examDate = "2026-08-25",
        startTime = "09:00",
        endTime = "12:00",
        venue = "Great Hall",
        seatRange = "GH-A-42 to GH-A-120",
        walkingTimeMinutes = 15
      )
    )

    val icsString = IcsCalendarExporter.generateIcsContent(
      schedules = sampleSchedules,
      exams = sampleExams,
      options = ScheduleExportOptions(
        includeWeeklyClasses = true,
        includeExams = true,
        includeAlarms = true,
        alarmMinutesBefore = 15
      )
    )

    assertTrue(icsString.startsWith("BEGIN:VCALENDAR"))
    assertTrue(icsString.trimEnd().endsWith("END:VCALENDAR"))
    assertTrue(icsString.contains("VERSION:2.0"))
    assertTrue(icsString.contains("SUMMARY:CSCD 302: Software Engineering"))
    assertTrue(icsString.contains("LOCATION:KAB 1"))
    assertTrue(icsString.contains("RRULE:FREQ=WEEKLY"))
    assertTrue(icsString.contains("BEGIN:VALARM"))
    assertTrue(icsString.contains("TRIGGER:-PT15M"))
    assertTrue(icsString.contains("EXAM: CSCD 302 - Software Engineering"))
    assertTrue(icsString.contains("Great Hall (GH-A-42 to GH-A-120)"))
  }

  @Test
  fun `test campus library database and live seat operations`() {
    val context = ApplicationProvider.getApplicationContext<Context>()
    val db = androidx.room.Room.inMemoryDatabaseBuilder(
      context,
      com.example.data.local.AppDatabase::class.java
    ).allowMainThreadQueries().build()
    val libraryDao = db.campusLibraryDao()

    kotlinx.coroutines.runBlocking {
      val testLibrary = com.example.data.local.entity.CampusLibraryEntity(
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
        description = "The premier academic research repository."
      )
      val ugbsLibrary = com.example.data.local.entity.CampusLibraryEntity(
        id = "ugbs_library",
        name = "UGBS Graduate Business Library",
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
        description = "Business & Economics specialist collection."
      )

      libraryDao.insertLibrary(testLibrary)
      libraryDao.insertLibrary(ugbsLibrary)

      val floor = com.example.data.local.entity.LibraryFloorEntity(
        id = 1L,
        libraryId = "balme_main",
        floorNumber = 0,
        floorName = "Ground Floor (Africana & Thesis)",
        totalFloorSeats = 450,
        availableFloorSeats = 120,
        noisePolicy = "Deep Silence Only",
        sectionsDescription = "Africana Wing, Digital Thesis Hub, Reference Stacks",
        interactiveMapZones = "Africana Wing (Free: 60); Thesis Hub (Free: 60)"
      )
      libraryDao.insertFloors(listOf(floor))

      // 1. Verify libraries exist
      val libraries = libraryDao.getAllLibrariesSnapshot()
      assertEquals(2, libraries.size)

      val balme = libraries.find { it.id == "balme_main" }
      assertNotNull("Balme Library should exist", balme)
      assertEquals("Balme Main Library", balme?.name)
      assertEquals(1200, balme?.totalCapacity)

      // 2. Search query test
      val searchResults = libraryDao.searchLibrariesSnapshot("Business")
      assertTrue("UGBS Library should match 'Business'", searchResults.any { it.name.contains("UGBS") })

      // 3. Floor maps query test
      val balmeFloors = libraryDao.getFloorsForLibrarySnapshot("balme_main")
      assertEquals(1, balmeFloors.size)

      val groundFloor = balmeFloors.find { it.floorNumber == 0 }
      assertNotNull(groundFloor)
      assertTrue("Ground floor has Africana Wing", groundFloor?.interactiveMapZones?.contains("Africana") == true)

      // 4. Update available seats test (Check-in simulation)
      libraryDao.updateLibraryAvailableSeats("balme_main", 340)
      val updatedBalme = libraryDao.getAllLibrariesSnapshot().find { it.id == "balme_main" }
      assertEquals(340, updatedBalme?.availableSeats)

      db.close()
    }
  }

  @Test
  fun `test academic schedule events DAO and queries for classes exams and study sessions`() {
    val context = ApplicationProvider.getApplicationContext<Context>()
    val db = androidx.room.Room.inMemoryDatabaseBuilder(
      context,
      com.example.data.local.AppDatabase::class.java
    ).allowMainThreadQueries().build()
    val eventDao = db.academicScheduleEventDao()

    kotlinx.coroutines.runBlocking {
      // 1. Insert class event
      val classEvent = com.example.data.local.entity.AcademicScheduleEventEntity(
        title = "Software Engineering Principles Lecture",
        courseCode = "CSCD 302",
        eventType = "CLASS",
        dayOfWeek = 1,
        startTime = "08:30",
        endTime = "10:30",
        venue = "KAB 1",
        campusLocationCode = "KAB",
        instructorOrLead = "Dr. K. Mensah",
        isRecurring = true
      )
      val classId = eventDao.insertEvent(classEvent)
      assertTrue("Generated class event id should be positive", classId > 0)

      // 2. Insert exam event
      val examEvent = com.example.data.local.entity.AcademicScheduleEventEntity(
        title = "Calculus Exam",
        courseCode = "MATH 223",
        eventType = "EXAM",
        eventDate = "2026-08-25",
        startTime = "14:00",
        endTime = "17:00",
        venue = "Great Hall",
        campusLocationCode = "GH",
        priority = "HIGH"
      )
      val examId = eventDao.insertEvent(examEvent)
      assertTrue("Generated exam event id should be positive", examId > 0)

      // 3. Insert study session event
      val studyEvent = com.example.data.local.entity.AcademicScheduleEventEntity(
        title = "OS Kernel Revision",
        courseCode = "CSCD 311",
        eventType = "STUDY_SESSION",
        eventDate = "2026-08-20",
        startTime = "16:00",
        endTime = "18:30",
        venue = "Balme Library Study Pod",
        campusLocationCode = "BLM",
        notes = "Chapter 4 semaphores"
      )
      val studyId = eventDao.insertEvent(studyEvent)
      assertTrue("Generated study event id should be positive", studyId > 0)

      // 4. Verify all events count
      val allEvents = eventDao.getAllEventsSnapshot()
      assertEquals(3, allEvents.size)

      // 5. Query by type
      val exams = eventDao.getEventsByTypeSnapshot("EXAM")
      assertEquals(1, exams.size)
      assertEquals("Calculus Exam", exams.first().title)

      val studySessions = eventDao.getEventsByTypeSnapshot("STUDY_SESSION")
      assertEquals(1, studySessions.size)
      assertEquals("OS Kernel Revision", studySessions.first().title)

      // 6. Test update & completion toggle
      eventDao.setEventCompleted(studyId, true)
      val updatedEvents = eventDao.getAllEventsSnapshot()
      val completedStudy = updatedEvents.find { it.id == studyId }
      assertTrue("Study session should be marked as completed", completedStudy?.isCompleted == true)

      // 7. Test delete
      eventDao.deleteEventById(classId)
      val remaining = eventDao.getAllEventsSnapshot()
      assertEquals(2, remaining.size)

      db.close()
    }
  }

  @Test
  fun `test AcademicScheduleRepository abstraction layer`() {
    val context = ApplicationProvider.getApplicationContext<Context>()
    val db = androidx.room.Room.inMemoryDatabaseBuilder(
      context,
      com.example.data.local.AppDatabase::class.java
    ).allowMainThreadQueries().build()

    val repository = com.example.data.repository.AcademicScheduleRepository(db.academicScheduleEventDao())

    kotlinx.coroutines.runBlocking {
      val event = com.example.data.local.entity.AcademicScheduleEventEntity(
        title = "AI & Machine Learning Seminar",
        courseCode = "CSCD 415",
        eventType = "CLASS",
        dayOfWeek = 2,
        startTime = "10:30",
        endTime = "12:30",
        venue = "JQB Room 22",
        campusLocationCode = "JQB"
      )

      val id = repository.insertEvent(event)
      assertTrue("Event id should be valid", id > 0)

      val snapshot = repository.getAllEventsSnapshot()
      assertEquals(1, snapshot.size)
      assertEquals("CSCD 415", snapshot[0].courseCode)

      repository.setEventCompleted(id, true)
      repository.toggleAlarm(id, false)
      val updated = repository.getAllEventsSnapshot().first()
      assertTrue("Event should be completed", updated.isCompleted)
      assertFalse("Alarm should be disabled", updated.isAlarmEnabled)

      repository.deleteEventById(id)
      assertTrue("Repository should be empty after deletion", repository.getAllEventsSnapshot().isEmpty())

      db.close()
    }
  }

  @Test
  fun `test AcademicScheduleViewModel state flow and filtering`() {
    val application = ApplicationProvider.getApplicationContext<android.app.Application>()
    val db = androidx.room.Room.inMemoryDatabaseBuilder(
      application,
      com.example.data.local.AppDatabase::class.java
    ).allowMainThreadQueries().build()

    val repository = com.example.data.repository.AcademicScheduleRepository(db.academicScheduleEventDao())
    val viewModel = com.example.ui.AcademicScheduleViewModel(application, repository)

    kotlinx.coroutines.runBlocking {
      // Add a test lecture
      viewModel.createQuickEvent(
        title = "Compiler Design Lecture",
        courseCode = "CSCD 422",
        eventType = com.example.data.local.entity.AcademicEventType.CLASS,
        startTime = "07:30",
        endTime = "09:30",
        venue = "KAB 2",
        dayOfWeek = 1
      )

      // Add a test exam
      viewModel.createQuickEvent(
        title = "Computer Networks Final Exam",
        courseCode = "CSCD 316",
        eventType = com.example.data.local.entity.AcademicEventType.EXAM,
        startTime = "14:00",
        endTime = "17:00",
        venue = "Great Hall",
        eventDate = "2026-09-01"
      )

      // Test View Mode toggle & selection
      assertEquals(com.example.ui.ScheduleViewMode.LIST, viewModel.viewMode.value)
      viewModel.setViewMode(com.example.ui.ScheduleViewMode.DAY_CALENDAR)
      assertEquals(com.example.ui.ScheduleViewMode.DAY_CALENDAR, viewModel.viewMode.value)
      viewModel.toggleViewMode()
      assertEquals(com.example.ui.ScheduleViewMode.LIST, viewModel.viewMode.value)

      // Test Search query filter
      viewModel.setSearchQuery("Compiler")
      assertEquals("Compiler", viewModel.searchQuery.value)

      // Test Filter type
      viewModel.setFilterType(com.example.data.local.entity.AcademicEventType.EXAM)
      assertEquals(com.example.data.local.entity.AcademicEventType.EXAM, viewModel.selectedFilterType.value)

      viewModel.clearFilters()
      assertEquals("", viewModel.searchQuery.value)
      assertEquals(null, viewModel.selectedFilterType.value)

      db.close()
    }
  }

  @Test
  fun `test ClassReminderScheduler 15-minute delay calculations`() {
    // Test date-specific delay calculation
    val futureDate = "2028-10-15"
    val startTime = "10:30"
    val delayMillis = com.example.data.worker.ClassReminderScheduler.calculateDelayForSpecificDate(
      dateIso = futureDate,
      startTime = startTime,
      minutesBefore = 15
    )
    assertTrue("Delay for future date should be positive", delayMillis > 0)

    // Test recurring day-of-week calculation returns positive delay
    val recurringDelay = com.example.data.worker.ClassReminderScheduler.calculateDelayForNextDayOccurrence(
      dayOfWeek = 1, // Monday
      startTime = "08:30",
      minutesBefore = 15
    )
    assertTrue("Recurring delay should be non-negative", recurringDelay >= 0)

    // Test past date returns -1
    val pastDelay = com.example.data.worker.ClassReminderScheduler.calculateDelayForSpecificDate(
      dateIso = "2020-01-01",
      startTime = "08:00",
      minutesBefore = 15
    )
    assertEquals(-1L, pastDelay)
  }

  @Test
  fun `test ClassReminderScheduler scheduling and cancellation on WorkManager`() {
    val context = ApplicationProvider.getApplicationContext<Context>()

    // Initialize WorkManager in test context if not already initialized
    try {
      val config = androidx.work.Configuration.Builder()
        .setMinimumLoggingLevel(android.util.Log.DEBUG)
        .build()
      androidx.work.WorkManager.initialize(context, config)
    } catch (_: Exception) {}

    // Initialize notification channel
    com.example.data.worker.ClassReminderNotificationHelper.createNotificationChannel(context)

    val sampleEvent = com.example.data.local.entity.AcademicScheduleEventEntity(
      id = 999L,
      title = "Operating Systems Lab",
      courseCode = "CSCD 304",
      eventType = "CLASS",
      dayOfWeek = 2,
      startTime = "14:00",
      endTime = "16:00",
      venue = "Lab 3",
      instructorOrLead = "Dr. Mensah",
      reminderMinutesBefore = 15,
      isAlarmEnabled = true
    )

    // Schedule reminder
    com.example.data.worker.ClassReminderScheduler.scheduleClassReminder(context, sampleEvent)

    // Cancel reminder
    com.example.data.worker.ClassReminderScheduler.cancelClassReminder(context, sampleEvent.id)
  }

  @Test
  fun `test ExamCountdownUtils calculates correct days remaining and formats display`() {
    val futureExam = ExamScheduleEntity(
      id = 1L,
      courseCode = "CSCD 302",
      courseTitle = "Software Engineering",
      examDate = "2099-12-31",
      startTime = "09:00",
      endTime = "12:00",
      venue = "KAB 1",
      seatRange = "Index 10920001 - 10920100"
    )

    val info = com.example.data.repository.ExamCountdownUtils.getCountdownInfo(futureExam)
    assertTrue("Future exam should have days remaining > 0", info.daysRemaining > 0)
    assertFalse(info.isPast)
    assertTrue(info.formattedDaysRemaining.contains("days"))

    val pastExam = ExamScheduleEntity(
      id = 2L,
      courseCode = "CSCD 301",
      courseTitle = "Algorithms",
      examDate = "2020-01-01",
      startTime = "09:00",
      endTime = "12:00",
      venue = "Great Hall",
      seatRange = "Index 10920001 - 10920100"
    )
    val pastInfo = com.example.data.repository.ExamCountdownUtils.getCountdownInfo(pastExam)
    assertTrue("Past exam should be marked past", pastInfo.isPast)
    assertTrue(pastInfo.formattedDaysRemaining.contains("ago"))
  }

  @Test
  fun `test ExamCountdownUtils sorted upcoming exams order`() {
    val examFarFuture = ExamScheduleEntity(
      id = 1L,
      courseCode = "CSCD 304",
      courseTitle = "Operating Systems",
      examDate = "2099-10-15",
      startTime = "09:00",
      endTime = "12:00",
      venue = "KAB 1",
      seatRange = "Index 10920001 - 10920100"
    )

    val examNearFuture = ExamScheduleEntity(
      id = 2L,
      courseCode = "CSCD 302",
      courseTitle = "Software Engineering",
      examDate = "2099-05-10",
      startTime = "09:00",
      endTime = "12:00",
      venue = "Great Hall",
      seatRange = "Index 10920001 - 10920100"
    )

    val sorted = com.example.data.repository.ExamCountdownUtils.getSortedUpcomingExams(listOf(examFarFuture, examNearFuture))
    assertEquals(2, sorted.size)
    assertEquals("CSCD 302", sorted[0].exam.courseCode)
    assertEquals("CSCD 304", sorted[1].exam.courseCode)

    val nextUpcoming = com.example.data.repository.ExamCountdownUtils.findNextUpcomingExam(listOf(examFarFuture, examNearFuture))
    assertNotNull(nextUpcoming)
    assertEquals("CSCD 302", nextUpcoming?.exam?.courseCode)
  }

  @Test
  fun `test multi-tenant institution registry preloaded profiles`() {
    val institutions = com.example.data.model.InstitutionRegistry.PRELOADED_INSTITUTIONS
    assertTrue("Should have at least 5 registered institutions", institutions.size >= 5)

    val ug = com.example.data.model.InstitutionRegistry.findById("ug")
    assertNotNull(ug)
    assertEquals("University of Ghana", ug?.name)
    assertEquals(com.example.data.model.GradingSystemType.GPA_4_0, ug?.gradingSystem)

    val knust = com.example.data.model.InstitutionRegistry.findById("knust")
    assertNotNull(knust)
    assertEquals("Kwame Nkrumah Univ. of Science & Tech", knust?.name)
    assertEquals(com.example.data.model.GradingSystemType.KNUST_CWA, knust?.gradingSystem)
  }

  @Test
  fun `test GradingEngine calculates GPA correctly for standard 4_0 scale`() {
    val courses = listOf(
      GpaCourseEntity(id = 1, semesterName = "Sem 1", courseCode = "CSCD 101", courseTitle = "Intro CS", creditHours = 3, grade = "A", gradePoint = 4.0),
      GpaCourseEntity(id = 2, semesterName = "Sem 1", courseCode = "MATH 121", courseTitle = "Algebra", creditHours = 3, grade = "B+", gradePoint = 3.5),
      GpaCourseEntity(id = 3, semesterName = "Sem 1", courseCode = "UGRC 110", courseTitle = "Writing", creditHours = 3, grade = "B", gradePoint = 3.0)
    )
    val ug = com.example.data.model.InstitutionRegistry.UG_PROFILE
    val result = com.example.data.repository.GradingEngine.calculateAcademicMetric(courses, ug)

    assertEquals(9, result.totalCredits)
    assertFalse(result.isCwa)
    // (3*4.0 + 3*3.5 + 3*3.0) / 9 = (12 + 10.5 + 9) / 9 = 31.5 / 9 = 3.50
    assertEquals(3.50, result.scoreValue, 0.01)
    assertEquals("Second Class (Upper)", result.honoursClass)
  }

  @Test
  fun `test GradingEngine calculates CWA percentage correctly for KNUST`() {
    val courses = listOf(
      GpaCourseEntity(id = 1, semesterName = "Sem 1", courseCode = "COE 151", courseTitle = "Programming", creditHours = 3, grade = "A", gradePoint = 4.0), // 85%
      GpaCourseEntity(id = 2, semesterName = "Sem 1", courseCode = "MATH 151", courseTitle = "Calculus", creditHours = 4, grade = "B+", gradePoint = 3.5) // 75%
    )
    val knust = com.example.data.model.InstitutionRegistry.KNUST_PROFILE
    val result = com.example.data.repository.GradingEngine.calculateAcademicMetric(courses, knust)

    assertEquals(7, result.totalCredits)
    assertTrue(result.isCwa)
    // (3*85 + 4*75) / 7 = (255 + 300) / 7 = 555 / 7 = 79.285%
    assertEquals(79.29, result.scoreValue, 0.05)
    assertEquals("First Class Honours", result.honoursClass)
  }

  @Test
  fun `test InstitutionPreferencesRepository save and retrieve DataStore state`() {
    val context = ApplicationProvider.getApplicationContext<Context>()
    val preferencesRepo = com.example.data.preferences.InstitutionPreferencesRepository(context)

    kotlinx.coroutines.runBlocking {
      // Save KNUST institution preference
      preferencesRepo.saveSelectedInstitution(
        institutionId = "knust",
        completedOnboarding = true,
        importSampleData = true
      )

      val savedId = preferencesRepo.selectedInstitutionIdSync()
      val isOnboardingCompleted = preferencesRepo.isOnboardingCompletedSync()

      assertEquals("knust", savedId)
      assertTrue(isOnboardingCompleted)

      // Test reset onboarding
      preferencesRepo.resetOnboarding()
      val resetCompleted = preferencesRepo.isOnboardingCompletedSync()
      assertFalse(resetCompleted)
    }
  }

  @Test
  fun `test MainViewModel completeOnboarding updates state`() {
    val application = ApplicationProvider.getApplicationContext<Application>()
    val viewModel = MainViewModel(application)

    val ugProfile = com.example.data.model.InstitutionRegistry.UG_PROFILE
    viewModel.completeOnboarding(ugProfile, importSampleData = false)

    assertEquals("ug", viewModel.currentInstitution.value.id)
  }
}




