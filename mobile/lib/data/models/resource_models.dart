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

class ResourceFixtures {
  ResourceFixtures._();

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
