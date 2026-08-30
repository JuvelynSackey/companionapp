package com.example.data.repository

import android.util.Log
import com.example.data.local.entity.AcademicScheduleEventEntity
import com.example.data.local.entity.CourseScheduleEntity
import com.example.data.model.CampusDueItem
import com.example.data.model.MoMoPaymentReceipt
import com.example.data.model.StudentProfile
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.ListenerRegistration
import com.google.firebase.firestore.SetOptions
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.tasks.await

/**
 * Interface defining Cloud Firestore operations for real-time synchronization
 * of student profiles, schedules (courses & academic events), and campus dues.
 */
interface IFirestoreRepository {
    // Student Profiles
    fun getStudentProfileFlow(userId: String): Flow<StudentProfile?>
    suspend fun getStudentProfile(userId: String): Result<StudentProfile?>
    suspend fun saveStudentProfile(userId: String, profile: StudentProfile): Result<Unit>

    // Course Schedules
    fun getCourseSchedulesFlow(userId: String): Flow<List<CourseScheduleEntity>>
    suspend fun syncCourseSchedules(userId: String, schedules: List<CourseScheduleEntity>): Result<Unit>
    suspend fun addOrUpdateCourseSchedule(userId: String, schedule: CourseScheduleEntity): Result<Unit>
    suspend fun deleteCourseSchedule(userId: String, scheduleId: String): Result<Unit>

    // Academic Schedule Events (Exams, Assignments, Study Sessions)
    fun getAcademicEventsFlow(userId: String): Flow<List<AcademicScheduleEventEntity>>
    suspend fun syncAcademicEvents(userId: String, events: List<AcademicScheduleEventEntity>): Result<Unit>
    suspend fun addOrUpdateAcademicEvent(userId: String, event: AcademicScheduleEventEntity): Result<Unit>
    suspend fun deleteAcademicEvent(userId: String, eventId: String): Result<Unit>

    // Campus Dues & MoMo Payments
    fun getCampusDuesFlow(userId: String): Flow<List<CampusDueItem>>
    suspend fun syncCampusDues(userId: String, dues: List<CampusDueItem>): Result<Unit>
    suspend fun markDueAsPaid(userId: String, dueId: String, receipt: MoMoPaymentReceipt): Result<Unit>
    suspend fun recordMoMoReceipt(userId: String, receipt: MoMoPaymentReceipt): Result<Unit>
    fun getMoMoReceiptsFlow(userId: String): Flow<List<MoMoPaymentReceipt>>
}

/**
 * Data repository implementation using Firebase Firestore for real-time cloud synchronisation.
 */
class FirestoreRepository(
    private val firestore: FirebaseFirestore = FirebaseFirestore.getInstance()
) : IFirestoreRepository {

    companion object {
        private const val TAG = "FirestoreRepository"
        private const val COLLECTION_USERS = "users"
        private const val COLLECTION_PROFILES = "profiles"
        private const val COLLECTION_SCHEDULES = "schedules"
        private const val COLLECTION_ACADEMIC_EVENTS = "academic_events"
        private const val COLLECTION_DUES = "dues"
        private const val COLLECTION_RECEIPTS = "receipts"
    }

    // =====================================================================
    // STUDENT PROFILE REAL-TIME SYNC
    // =====================================================================

    override fun getStudentProfileFlow(userId: String): Flow<StudentProfile?> = callbackFlow {
        val docRef = firestore.collection(COLLECTION_USERS)
            .document(userId)
            .collection(COLLECTION_PROFILES)
            .document("main_profile")

        val registration: ListenerRegistration = docRef.addSnapshotListener { snapshot, error ->
            if (error != null) {
                Log.w(TAG, "Listen failed for student profile: ${error.message}")
                trySend(null)
                return@addSnapshotListener
            }

            if (snapshot != null && snapshot.exists()) {
                try {
                    val profile = snapshot.toObject(StudentProfileDto::class.java)?.toDomainModel()
                    trySend(profile)
                } catch (e: Exception) {
                    Log.e(TAG, "Error deserializing StudentProfile: ${e.message}", e)
                    trySend(null)
                }
            } else {
                trySend(null)
            }
        }

        awaitClose { registration.remove() }
    }

    override suspend fun getStudentProfile(userId: String): Result<StudentProfile?> {
        return try {
            val snapshot = firestore.collection(COLLECTION_USERS)
                .document(userId)
                .collection(COLLECTION_PROFILES)
                .document("main_profile")
                .get()
                .await()

            if (snapshot.exists()) {
                val profile = snapshot.toObject(StudentProfileDto::class.java)?.toDomainModel()
                Result.success(profile)
            } else {
                Result.success(null)
            }
        } catch (e: Exception) {
            Log.e(TAG, "getStudentProfile failed: ${e.localizedMessage}", e)
            Result.failure(e)
        }
    }

    override suspend fun saveStudentProfile(userId: String, profile: StudentProfile): Result<Unit> {
        return try {
            val dto = StudentProfileDto.fromDomainModel(profile)
            firestore.collection(COLLECTION_USERS)
                .document(userId)
                .collection(COLLECTION_PROFILES)
                .document("main_profile")
                .set(dto, SetOptions.merge())
                .await()
            Result.success(Unit)
        } catch (e: Exception) {
            Log.e(TAG, "saveStudentProfile failed: ${e.localizedMessage}", e)
            Result.failure(e)
        }
    }

    // =====================================================================
    // COURSE SCHEDULES REAL-TIME SYNC
    // =====================================================================

    override fun getCourseSchedulesFlow(userId: String): Flow<List<CourseScheduleEntity>> = callbackFlow {
        val collectionRef = firestore.collection(COLLECTION_USERS)
            .document(userId)
            .collection(COLLECTION_SCHEDULES)

        val registration: ListenerRegistration = collectionRef.addSnapshotListener { snapshot, error ->
            if (error != null) {
                Log.w(TAG, "Listen failed for course schedules: ${error.message}")
                trySend(emptyList())
                return@addSnapshotListener
            }

            if (snapshot != null) {
                val list = snapshot.documents.mapNotNull { doc ->
                    try {
                        doc.toObject(CourseScheduleDto::class.java)?.toEntity()
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed parsing schedule doc ${doc.id}: ${e.message}")
                        null
                    }
                }
                trySend(list)
            } else {
                trySend(emptyList())
            }
        }

        awaitClose { registration.remove() }
    }

    override suspend fun syncCourseSchedules(userId: String, schedules: List<CourseScheduleEntity>): Result<Unit> {
        return try {
            val batch = firestore.batch()
            val collectionRef = firestore.collection(COLLECTION_USERS)
                .document(userId)
                .collection(COLLECTION_SCHEDULES)

            for (item in schedules) {
                val docId = if (item.id != 0L) item.id.toString() else item.courseCode.replace(" ", "_")
                val docRef = collectionRef.document(docId)
                val dto = CourseScheduleDto.fromEntity(item)
                batch.set(docRef, dto, SetOptions.merge())
            }

            batch.commit().await()
            Result.success(Unit)
        } catch (e: Exception) {
            Log.e(TAG, "syncCourseSchedules failed: ${e.localizedMessage}", e)
            Result.failure(e)
        }
    }

    override suspend fun addOrUpdateCourseSchedule(userId: String, schedule: CourseScheduleEntity): Result<Unit> {
        return try {
            val docId = if (schedule.id != 0L) schedule.id.toString() else schedule.courseCode.replace(" ", "_")
            val docRef = firestore.collection(COLLECTION_USERS)
                .document(userId)
                .collection(COLLECTION_SCHEDULES)
                .document(docId)

            val dto = CourseScheduleDto.fromEntity(schedule)
            docRef.set(dto, SetOptions.merge()).await()
            Result.success(Unit)
        } catch (e: Exception) {
            Log.e(TAG, "addOrUpdateCourseSchedule failed: ${e.localizedMessage}", e)
            Result.failure(e)
        }
    }

    override suspend fun deleteCourseSchedule(userId: String, scheduleId: String): Result<Unit> {
        return try {
            firestore.collection(COLLECTION_USERS)
                .document(userId)
                .collection(COLLECTION_SCHEDULES)
                .document(scheduleId)
                .delete()
                .await()
            Result.success(Unit)
        } catch (e: Exception) {
            Log.e(TAG, "deleteCourseSchedule failed: ${e.localizedMessage}", e)
            Result.failure(e)
        }
    }

    // =====================================================================
    // ACADEMIC SCHEDULE EVENTS (Exams, Assignments, Study Sessions)
    // =====================================================================

    override fun getAcademicEventsFlow(userId: String): Flow<List<AcademicScheduleEventEntity>> = callbackFlow {
        val collectionRef = firestore.collection(COLLECTION_USERS)
            .document(userId)
            .collection(COLLECTION_ACADEMIC_EVENTS)

        val registration: ListenerRegistration = collectionRef.addSnapshotListener { snapshot, error ->
            if (error != null) {
                Log.w(TAG, "Listen failed for academic events: ${error.message}")
                trySend(emptyList())
                return@addSnapshotListener
            }

            if (snapshot != null) {
                val list = snapshot.documents.mapNotNull { doc ->
                    try {
                        doc.toObject(AcademicScheduleEventDto::class.java)?.toEntity()
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed parsing event doc ${doc.id}: ${e.message}")
                        null
                    }
                }
                trySend(list)
            } else {
                trySend(emptyList())
            }
        }

        awaitClose { registration.remove() }
    }

    override suspend fun syncAcademicEvents(userId: String, events: List<AcademicScheduleEventEntity>): Result<Unit> {
        return try {
            val batch = firestore.batch()
            val collectionRef = firestore.collection(COLLECTION_USERS)
                .document(userId)
                .collection(COLLECTION_ACADEMIC_EVENTS)

            for (event in events) {
                val docId = if (event.id != 0L) event.id.toString() else "event_${event.title.replace(" ", "_")}_${event.createdAt}"
                val docRef = collectionRef.document(docId)
                val dto = AcademicScheduleEventDto.fromEntity(event)
                batch.set(docRef, dto, SetOptions.merge())
            }

            batch.commit().await()
            Result.success(Unit)
        } catch (e: Exception) {
            Log.e(TAG, "syncAcademicEvents failed: ${e.localizedMessage}", e)
            Result.failure(e)
        }
    }

    override suspend fun addOrUpdateAcademicEvent(userId: String, event: AcademicScheduleEventEntity): Result<Unit> {
        return try {
            val docId = if (event.id != 0L) event.id.toString() else "event_${event.title.replace(" ", "_")}_${event.createdAt}"
            val docRef = firestore.collection(COLLECTION_USERS)
                .document(userId)
                .collection(COLLECTION_ACADEMIC_EVENTS)
                .document(docId)

            val dto = AcademicScheduleEventDto.fromEntity(event)
            docRef.set(dto, SetOptions.merge()).await()
            Result.success(Unit)
        } catch (e: Exception) {
            Log.e(TAG, "addOrUpdateAcademicEvent failed: ${e.localizedMessage}", e)
            Result.failure(e)
        }
    }

    override suspend fun deleteAcademicEvent(userId: String, eventId: String): Result<Unit> {
        return try {
            firestore.collection(COLLECTION_USERS)
                .document(userId)
                .collection(COLLECTION_ACADEMIC_EVENTS)
                .document(eventId)
                .delete()
                .await()
            Result.success(Unit)
        } catch (e: Exception) {
            Log.e(TAG, "deleteAcademicEvent failed: ${e.localizedMessage}", e)
            Result.failure(e)
        }
    }

    // =====================================================================
    // CAMPUS DUES & MOMO PAYMENT SYNC
    // =====================================================================

    override fun getCampusDuesFlow(userId: String): Flow<List<CampusDueItem>> = callbackFlow {
        val collectionRef = firestore.collection(COLLECTION_USERS)
            .document(userId)
            .collection(COLLECTION_DUES)

        val registration: ListenerRegistration = collectionRef.addSnapshotListener { snapshot, error ->
            if (error != null) {
                Log.w(TAG, "Listen failed for dues: ${error.message}")
                trySend(emptyList())
                return@addSnapshotListener
            }

            if (snapshot != null) {
                val list = snapshot.documents.mapNotNull { doc ->
                    try {
                        doc.toObject(CampusDueItemDto::class.java)?.toDomainModel()
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed parsing due doc ${doc.id}: ${e.message}")
                        null
                    }
                }
                trySend(list)
            } else {
                trySend(emptyList())
            }
        }

        awaitClose { registration.remove() }
    }

    override suspend fun syncCampusDues(userId: String, dues: List<CampusDueItem>): Result<Unit> {
        return try {
            val batch = firestore.batch()
            val collectionRef = firestore.collection(COLLECTION_USERS)
                .document(userId)
                .collection(COLLECTION_DUES)

            for (due in dues) {
                val docRef = collectionRef.document(due.id)
                val dto = CampusDueItemDto.fromDomainModel(due)
                batch.set(docRef, dto, SetOptions.merge())
            }

            batch.commit().await()
            Result.success(Unit)
        } catch (e: Exception) {
            Log.e(TAG, "syncCampusDues failed: ${e.localizedMessage}", e)
            Result.failure(e)
        }
    }

    override suspend fun markDueAsPaid(userId: String, dueId: String, receipt: MoMoPaymentReceipt): Result<Unit> {
        return try {
            val dueRef = firestore.collection(COLLECTION_USERS)
                .document(userId)
                .collection(COLLECTION_DUES)
                .document(dueId)

            val receiptRef = firestore.collection(COLLECTION_USERS)
                .document(userId)
                .collection(COLLECTION_RECEIPTS)
                .document(receipt.transactionRef)

            firestore.runBatch { batch ->
                batch.update(dueRef, mapOf(
                    "isPaid" to true,
                    "paymentReference" to receipt.transactionRef
                ))
                batch.set(receiptRef, MoMoPaymentReceiptDto.fromDomainModel(receipt))
            }.await()

            Result.success(Unit)
        } catch (e: Exception) {
            Log.e(TAG, "markDueAsPaid failed: ${e.localizedMessage}", e)
            Result.failure(e)
        }
    }

    override suspend fun recordMoMoReceipt(userId: String, receipt: MoMoPaymentReceipt): Result<Unit> {
        return try {
            firestore.collection(COLLECTION_USERS)
                .document(userId)
                .collection(COLLECTION_RECEIPTS)
                .document(receipt.transactionRef)
                .set(MoMoPaymentReceiptDto.fromDomainModel(receipt), SetOptions.merge())
                .await()
            Result.success(Unit)
        } catch (e: Exception) {
            Log.e(TAG, "recordMoMoReceipt failed: ${e.localizedMessage}", e)
            Result.failure(e)
        }
    }

    override fun getMoMoReceiptsFlow(userId: String): Flow<List<MoMoPaymentReceipt>> = callbackFlow {
        val collectionRef = firestore.collection(COLLECTION_USERS)
            .document(userId)
            .collection(COLLECTION_RECEIPTS)

        val registration: ListenerRegistration = collectionRef.addSnapshotListener { snapshot, error ->
            if (error != null) {
                Log.w(TAG, "Listen failed for receipts: ${error.message}")
                trySend(emptyList())
                return@addSnapshotListener
            }

            if (snapshot != null) {
                val list = snapshot.documents.mapNotNull { doc ->
                    try {
                        doc.toObject(MoMoPaymentReceiptDto::class.java)?.toDomainModel()
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed parsing receipt doc ${doc.id}: ${e.message}")
                        null
                    }
                }
                trySend(list)
            } else {
                trySend(emptyList())
            }
        }

        awaitClose { registration.remove() }
    }
}

// =====================================================================
// FIRESTORE DTOs (Data Transfer Objects with no-arg constructors)
// =====================================================================

data class StudentProfileDto(
    var id: String = "",
    var name: String = "",
    var studentId: String = "",
    var email: String = "",
    var phone: String = "",
    var institutionId: String = "",
    var program: String = "",
    var level: String = "",
    var hallOfResidence: String = "",
    var roomNumber: String = "",
    var academicYear: String = "",
    var semester: String = "",
    var momoNumber: String = "",
    var momoProvider: String = "",
    var studentCardBarcode: String = "",
    var campusPoints: Int = 0
) {
    fun toDomainModel(): StudentProfile = StudentProfile(
        id = id,
        name = name,
        studentId = studentId,
        email = email,
        phone = phone,
        institutionId = institutionId,
        program = program,
        level = level,
        hallOfResidence = hallOfResidence,
        roomNumber = roomNumber,
        academicYear = academicYear,
        semester = semester,
        momoNumber = momoNumber,
        momoProvider = momoProvider,
        studentCardBarcode = studentCardBarcode,
        campusPoints = campusPoints
    )

    companion object {
        fun fromDomainModel(model: StudentProfile): StudentProfileDto = StudentProfileDto(
            id = model.id,
            name = model.name,
            studentId = model.studentId,
            email = model.email,
            phone = model.phone,
            institutionId = model.institutionId,
            program = model.program,
            level = model.level,
            hallOfResidence = model.hallOfResidence,
            roomNumber = model.roomNumber,
            academicYear = model.academicYear,
            semester = model.semester,
            momoNumber = model.momoNumber,
            momoProvider = model.momoProvider,
            studentCardBarcode = model.studentCardBarcode,
            campusPoints = model.campusPoints
        )
    }
}

data class CourseScheduleDto(
    var id: Long = 0L,
    var courseCode: String = "",
    var courseTitle: String = "",
    var lecturer: String = "",
    var dayOfWeek: Int = 1,
    var startTime: String = "",
    var endTime: String = "",
    var venue: String = "",
    var creditHours: Int = 3,
    var colorHex: Long = 0xFF1E3A8A,
    var isCancelledOrMoved: Boolean = false,
    var changeNote: String? = null,
    var reminderMinutesBefore: Int = 15,
    var isAlarmEnabled: Boolean = true
) {
    fun toEntity(): CourseScheduleEntity = CourseScheduleEntity(
        id = id,
        courseCode = courseCode,
        courseTitle = courseTitle,
        lecturer = lecturer,
        dayOfWeek = dayOfWeek,
        startTime = startTime,
        endTime = endTime,
        venue = venue,
        creditHours = creditHours,
        colorHex = colorHex,
        isCancelledOrMoved = isCancelledOrMoved,
        changeNote = changeNote,
        reminderMinutesBefore = reminderMinutesBefore,
        isAlarmEnabled = isAlarmEnabled
    )

    companion object {
        fun fromEntity(entity: CourseScheduleEntity): CourseScheduleDto = CourseScheduleDto(
            id = entity.id,
            courseCode = entity.courseCode,
            courseTitle = entity.courseTitle,
            lecturer = entity.lecturer,
            dayOfWeek = entity.dayOfWeek,
            startTime = entity.startTime,
            endTime = entity.endTime,
            venue = entity.venue,
            creditHours = entity.creditHours,
            colorHex = entity.colorHex,
            isCancelledOrMoved = entity.isCancelledOrMoved,
            changeNote = entity.changeNote,
            reminderMinutesBefore = entity.reminderMinutesBefore,
            isAlarmEnabled = entity.isAlarmEnabled
        )
    }
}

data class AcademicScheduleEventDto(
    var id: Long = 0L,
    var title: String = "",
    var courseCode: String = "",
    var eventType: String = "CLASS",
    var dayOfWeek: Int? = null,
    var eventDate: String? = null,
    var startTime: String = "",
    var endTime: String = "",
    var venue: String = "",
    var campusLocationCode: String? = null,
    var instructorOrLead: String = "",
    var notes: String = "",
    var colorHex: Long = 0xFF1E3A8A,
    var reminderMinutesBefore: Int = 15,
    var isAlarmEnabled: Boolean = true,
    var isCompleted: Boolean = false,
    var isRecurring: Boolean = false,
    var priority: String = "NORMAL",
    var createdAt: Long = 0L
) {
    fun toEntity(): AcademicScheduleEventEntity = AcademicScheduleEventEntity(
        id = id,
        title = title,
        courseCode = courseCode,
        eventType = eventType,
        dayOfWeek = dayOfWeek,
        eventDate = eventDate,
        startTime = startTime,
        endTime = endTime,
        venue = venue,
        campusLocationCode = campusLocationCode,
        instructorOrLead = instructorOrLead,
        notes = notes,
        colorHex = colorHex,
        reminderMinutesBefore = reminderMinutesBefore,
        isAlarmEnabled = isAlarmEnabled,
        isCompleted = isCompleted,
        isRecurring = isRecurring,
        priority = priority,
        createdAt = createdAt
    )

    companion object {
        fun fromEntity(entity: AcademicScheduleEventEntity): AcademicScheduleEventDto = AcademicScheduleEventDto(
            id = entity.id,
            title = entity.title,
            courseCode = entity.courseCode,
            eventType = entity.eventType,
            dayOfWeek = entity.dayOfWeek,
            eventDate = entity.eventDate,
            startTime = entity.startTime,
            endTime = entity.endTime,
            venue = entity.venue,
            campusLocationCode = entity.campusLocationCode,
            instructorOrLead = entity.instructorOrLead,
            notes = entity.notes,
            colorHex = entity.colorHex,
            reminderMinutesBefore = entity.reminderMinutesBefore,
            isAlarmEnabled = entity.isAlarmEnabled,
            isCompleted = entity.isCompleted,
            isRecurring = entity.isRecurring,
            priority = entity.priority,
            createdAt = entity.createdAt
        )
    }
}

data class CampusDueItemDto(
    var id: String = "",
    var institutionId: String = "",
    var title: String = "",
    var category: String = "",
    var amountCedis: Double = 0.0,
    var isPaid: Boolean = false,
    var dueDate: String = "",
    var paymentReference: String? = null,
    var description: String = ""
) {
    fun toDomainModel(): CampusDueItem = CampusDueItem(
        id = id,
        institutionId = institutionId,
        title = title,
        category = category,
        amountCedis = amountCedis,
        isPaid = isPaid,
        dueDate = dueDate,
        paymentReference = paymentReference,
        description = description
    )

    companion object {
        fun fromDomainModel(model: CampusDueItem): CampusDueItemDto = CampusDueItemDto(
            id = model.id,
            institutionId = model.institutionId,
            title = model.title,
            category = model.category,
            amountCedis = model.amountCedis,
            isPaid = model.isPaid,
            dueDate = model.dueDate,
            paymentReference = model.paymentReference,
            description = model.description
        )
    }
}

data class MoMoPaymentReceiptDto(
    var transactionRef: String = "",
    var itemTitle: String = "",
    var amountCedis: Double = 0.0,
    var payerName: String = "",
    var studentId: String = "",
    var momoNumber: String = "",
    var provider: String = "",
    var timestamp: Long = 0L,
    var status: String = "SUCCESSFUL"
) {
    fun toDomainModel(): MoMoPaymentReceipt = MoMoPaymentReceipt(
        transactionRef = transactionRef,
        itemTitle = itemTitle,
        amountCedis = amountCedis,
        payerName = payerName,
        studentId = studentId,
        momoNumber = momoNumber,
        provider = provider,
        timestamp = timestamp,
        status = status
    )

    companion object {
        fun fromDomainModel(model: MoMoPaymentReceipt): MoMoPaymentReceiptDto = MoMoPaymentReceiptDto(
            transactionRef = model.transactionRef,
            itemTitle = model.itemTitle,
            amountCedis = model.amountCedis,
            payerName = model.payerName,
            studentId = model.studentId,
            momoNumber = model.momoNumber,
            provider = model.provider,
            timestamp = model.timestamp,
            status = model.status
        )
    }
}
