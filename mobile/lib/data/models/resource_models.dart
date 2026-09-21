/// Local static fixture models — the backend has no library/resource tables.
/// Loosely ported from CampusLibraryEntity / StudyResourceEntity in
/// app/src/main/java/com/example/data/local/entity/Entities.kt.
enum SeatOccupancyLevel { low, moderate, high, full }

class LibraryInfo {
  const LibraryInfo({
    required this.id,
    required this.name,
    required this.campusZone,
    required this.totalCapacity,
    required this.availableSeats,
    required this.openingHoursWeekdays,
    required this.openingHoursWeekends,
    required this.isOpenNow,
    required this.description,
  });

  final String id;
  final String name;
  final String campusZone;
  final int totalCapacity;
  final int availableSeats;
  final String openingHoursWeekdays;
  final String openingHoursWeekends;
  final bool isOpenNow;
  final String description;

  SeatOccupancyLevel get occupancyLevel {
    if (availableSeats <= 0) return SeatOccupancyLevel.full;
    final ratio = availableSeats / totalCapacity;
    if (ratio > 0.5) return SeatOccupancyLevel.low;
    if (ratio > 0.2) return SeatOccupancyLevel.moderate;
    return SeatOccupancyLevel.high;
  }
}

class PastPaper {
  const PastPaper({
    required this.id,
    required this.courseCode,
    required this.courseTitle,
    required this.title,
    required this.year,
    required this.fileType,
    required this.summaryText,
  });

  final String id;
  final String courseCode;
  final String courseTitle;
  final String title;
  final String year;
  final String fileType;
  final String summaryText;
}

class CalendarEntry {
  const CalendarEntry({required this.title, required this.dateRange, required this.description});

  final String title;
  final String dateRange;
  final String description;
}

class HandbookSection {
  const HandbookSection({required this.title, required this.summary});

  final String title;
  final String summary;
}

/// Transcripts and proof-of-registration are official documents used with
/// third parties (employers, embassies, other institutions) — this app
/// deliberately never generates anything that looks like one. Requesting
/// one here only logs a request record with a reference number; the actual
/// certified copy still has to be collected from Academic Affairs, the same
/// way the "Official Certified Transcript Application" due in Student Hub
/// only covers the admin fee, not the document itself.
enum DocumentType { transcript, proofOfRegistration }

extension DocumentTypeInfo on DocumentType {
  String get label => switch (this) {
        DocumentType.transcript => 'Official Transcript',
        DocumentType.proofOfRegistration => 'Proof of Registration',
      };

  String get description => switch (this) {
        DocumentType.transcript => 'Certified statement of results, issued by Academic Affairs.',
        DocumentType.proofOfRegistration => 'Confirmation letter of current-semester enrollment.',
      };
}

class DocumentRequest {
  const DocumentRequest({
    required this.type,
    required this.referenceNumber,
    required this.requestedAt,
  });

  factory DocumentRequest.fromJson(Map<String, dynamic> json) => DocumentRequest(
        type: DocumentType.values.byName(json['type'] as String),
        referenceNumber: json['referenceNumber'] as String,
        requestedAt: DateTime.parse(json['requestedAt'] as String),
      );

  final DocumentType type;
  final String referenceNumber;
  final DateTime requestedAt;

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'referenceNumber': referenceNumber,
        'requestedAt': requestedAt.toIso8601String(),
      };
}

class ResourceFixtures {
  ResourceFixtures._();

  /// Sample/indicative dates only — always confirm the real ones on the
  /// institution's own portal before relying on them for a deadline.
  static const academicCalendar = [
    CalendarEntry(
      title: 'Semester Registration',
      dateRange: 'Aug 25 – Sep 5, 2026',
      description: 'Online course registration and fee payment window for the new semester.',
    ),
    CalendarEntry(
      title: 'Lectures Begin',
      dateRange: 'Sep 8, 2026',
      description: 'First day of teaching for the semester.',
    ),
    CalendarEntry(
      title: 'Mid-Semester Examinations',
      dateRange: 'Oct 20 – Oct 24, 2026',
      description: 'Continuous assessment / mid-semester quizzes across all faculties.',
    ),
    CalendarEntry(
      title: 'Lectures End',
      dateRange: 'Dec 5, 2026',
      description: 'Last day of teaching before revision week.',
    ),
    CalendarEntry(
      title: 'End-of-Semester Examinations',
      dateRange: 'Dec 15 – Dec 23, 2026',
      description: 'Final examinations for all levels.',
    ),
    CalendarEntry(
      title: 'Semester Break',
      dateRange: 'Dec 24, 2026 – Jan 11, 2027',
      description: 'Inter-semester vacation.',
    ),
  ];

  static const handbookSections = [
    HandbookSection(
      title: 'Academic Integrity',
      summary:
          'Plagiarism, examination malpractice, and unauthorized collaboration are serious offences handled by '
          'the university\'s disciplinary committee and can result in suspension or dismissal.',
    ),
    HandbookSection(
      title: 'Grading & Classification',
      summary:
          'Cumulative averages determine honours classification at graduation. Check your institution\'s '
          'grading system on the Analytics tab for your specific breakpoints.',
    ),
    HandbookSection(
      title: 'Attendance Policy',
      summary:
          'A minimum attendance threshold (typically 75%) is required to sit end-of-semester examinations in '
          'a course, unless an authorized absence is on file with the department.',
    ),
    HandbookSection(
      title: 'Examination Conduct',
      summary:
          'Valid student ID must be presented at every examination venue. Unauthorized materials or devices '
          'at an exam desk are treated as attempted malpractice.',
    ),
    HandbookSection(
      title: 'Hall & Residence Rules',
      summary:
          'Residents are expected to observe quiet hours, visitor sign-in procedures, and room inspection '
          'schedules set by their Hall\'s Junior Common Room.',
    ),
  ];

  static const libraries = [
    LibraryInfo(
      id: 'main_library',
      name: 'Main Library',
      campusZone: 'Central Campus',
      totalCapacity: 420,
      availableSeats: 168,
      openingHoursWeekdays: '07:30 AM - 10:00 PM',
      openingHoursWeekends: '09:00 AM - 08:00 PM',
      isOpenNow: true,
      description:
          'The premier academic research repository with extensive collections, carrels, and digital archives.',
    ),
    LibraryInfo(
      id: 'science_library',
      name: 'Science & Engineering Library',
      campusZone: 'Science Quadrangle',
      totalCapacity: 180,
      availableSeats: 24,
      openingHoursWeekdays: '08:00 AM - 09:00 PM',
      openingHoursWeekends: '10:00 AM - 06:00 PM',
      isOpenNow: true,
      description: 'Reference collection and quiet study carrels for science and engineering students.',
    ),
    LibraryInfo(
      id: 'law_library',
      name: 'Law Library',
      campusZone: 'Professional Quadrants',
      totalCapacity: 90,
      availableSeats: 0,
      openingHoursWeekdays: '08:00 AM - 11:00 PM',
      openingHoursWeekends: '09:00 AM - 09:00 PM',
      isOpenNow: true,
      description: 'Statutes, law reports, and moot court preparation rooms.',
    ),
  ];

  static const pastPapers = [
    PastPaper(
      id: 'pp1',
      courseCode: 'DCIT 201',
      courseTitle: 'Mathematics',
      title: 'End of Semester Exam',
      year: '2025',
      fileType: 'PDF',
      summaryText: 'Covers calculus, linear algebra fundamentals, and applied statistics.',
    ),
    PastPaper(
      id: 'pp2',
      courseCode: 'DCIT 205',
      courseTitle: 'Computer Science',
      title: 'Mid-Semester Test',
      year: '2025',
      fileType: 'PDF',
      summaryText: 'Data structures, algorithm complexity, and recursion questions.',
    ),
    PastPaper(
      id: 'pp3',
      courseCode: 'DCIT 202',
      courseTitle: 'Physics',
      title: 'End of Semester Exam',
      year: '2024',
      fileType: 'PDF',
      summaryText: 'Mechanics, electromagnetism, and thermodynamics problem sets.',
    ),
  ];
}
