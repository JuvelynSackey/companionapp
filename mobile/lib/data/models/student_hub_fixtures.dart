import 'student_hub_models.dart';

/// Ported from GhanaCampusCompanionData.kt's per-institution generators.
/// Institutions without dedicated content (Ashesi, GIMPA, ATU) fall back to
/// the same generic set the Kotlin `else` branch used for UG — matching the
/// source app's own fallback behavior rather than inventing new content.
class StudentHubFixtures {
  StudentHubFixtures._();

  static List<ShuttleRoute> shuttlesFor(String institutionId) {
    if (institutionId.toLowerCase().contains('knust')) return _knustShuttles;
    if (institutionId.toLowerCase().contains('ucc')) return _uccShuttles;
    if (institutionId.toLowerCase().contains('uew')) return _uewShuttles;
    return _ugShuttles;
  }

  static List<CampusDue> duesFor(String institutionId) {
    if (institutionId.toLowerCase().contains('knust')) return _knustDues;
    if (institutionId.toLowerCase().contains('ucc')) return _uccDues;
    return _ugDues;
  }

  /// Same seed list regardless of institution, matching the source app.
  static List<LostFoundItem> lostFoundSeed() => _lostFoundSeed;

  static const _ugShuttles = [
    ShuttleRoute(
      id: 'ug_sh_1',
      routeName: 'Diaspora Express (Pentagon - TF - Evandy - Balme)',
      routeCode: 'UG-01',
      fromStop: 'Diaspora Hall Hub (Pent / TF)',
      toStop: 'Central Campus & Balme Library',
      viaStops: ['Bani Hostel', 'Jean Nelson Aka Hall', 'JQB Complex', 'Great Hall'],
      fareGhs: 4.00,
      nextArrivalMinutes: 2,
      busNumberPlate: 'GW-4912-24',
      driverName: 'Uncle Kwame',
      driverPhone: '024 991 8822',
      totalSeats: 36,
      seatsAvailable: 7,
      status: 'Arriving in 2m',
      operatingHours: '06:30 AM - 11:30 PM',
    ),
    ShuttleRoute(
      id: 'ug_sh_2',
      routeName: 'Main Gate - Legon Hall - Bush Canteen Line',
      routeCode: 'UG-02',
      fromStop: 'Main University Gate',
      toStop: 'Bush Canteen & Night Market',
      viaStops: ['Commonwealth Hall', 'Volta Hall', 'Akuafo Hall', 'UGBS Graduate'],
      fareGhs: 3.50,
      nextArrivalMinutes: 7,
      busNumberPlate: 'GE-2091-23',
      driverName: 'Kojo Darko',
      driverPhone: '020 441 5566',
      totalSeats: 32,
      seatsAvailable: 15,
      status: 'On Route',
      operatingHours: '06:30 AM - 11:30 PM',
    ),
    ShuttleRoute(
      id: 'ug_sh_3',
      routeName: 'Night Campus Shuttle (Safe Ride)',
      routeCode: 'UG-NIGHT',
      fromStop: 'Balme Library Reading Rooms',
      toStop: 'All Hostels (Diaspora & Traditional)',
      viaStops: ['Sarbah Hall', 'Mensah Sarbah Field', 'TF Hostel Gate', 'Pentagon Block C'],
      fareGhs: 5.00,
      nextArrivalMinutes: 12,
      busNumberPlate: 'GS-7721-22',
      driverName: 'Emmanuel Asare',
      driverPhone: '054 112 9900',
      totalSeats: 36,
      seatsAvailable: 22,
      status: 'On Time',
      operatingHours: '06:30 AM - 11:30 PM',
    ),
  ];

  static const _knustShuttles = [
    ShuttleRoute(
      id: 'knust_sh_1',
      routeName: 'Ayeduase Gate - Tech Junction - Commercial Area',
      routeCode: 'KN-01',
      fromStop: 'Ayeduase Gate',
      toStop: 'Commercial Area & Great Hall',
      viaStops: ['Brunei Complex', 'Hall 7', 'Faculty of Engineering', 'Main Library'],
      fareGhs: 4.00,
      nextArrivalMinutes: 3,
      busNumberPlate: 'AS-3810-24',
      driverName: 'Kofi Boateng',
      driverPhone: '024 112 3456',
      totalSeats: 32,
      seatsAvailable: 6,
      status: 'Arriving in 3m',
      operatingHours: '06:30 AM - 11:30 PM',
    ),
    ShuttleRoute(
      id: 'knust_sh_2',
      routeName: 'Kotei Line - Gaza - College of Science',
      routeCode: 'KN-02',
      fromStop: 'Kotei / Gaza Hostel Hub',
      toStop: 'College of Science (CoS)',
      viaStops: ['Africa Hall', 'Unity Hall (Conti)', 'SMS Complex'],
      fareGhs: 4.50,
      nextArrivalMinutes: 8,
      busNumberPlate: 'AS-7219-23',
      driverName: 'Uncle Osei',
      driverPhone: '020 987 6543',
      totalSeats: 28,
      seatsAvailable: 12,
      status: 'On Route',
      operatingHours: '06:30 AM - 11:30 PM',
    ),
    ShuttleRoute(
      id: 'knust_sh_3',
      routeName: 'Night Campus Express (Katanga - Tech Hospital)',
      routeCode: 'KN-NIGHT',
      fromStop: 'University Hall (Katanga)',
      toStop: 'Tech Hospital & Boadi Gate',
      viaStops: ['Queens Hall', 'Central Library', 'Agric Faculty'],
      fareGhs: 5.00,
      nextArrivalMinutes: 14,
      busNumberPlate: 'AS-1029-22',
      driverName: 'Yaw Antwi',
      driverPhone: '055 334 1122',
      totalSeats: 32,
      seatsAvailable: 19,
      status: 'On Time',
      operatingHours: '06:30 AM - 11:30 PM',
    ),
  ];

  static const _uccShuttles = [
    ShuttleRoute(
      id: 'ucc_sh_1',
      routeName: 'Science Block - FELT - Auditorium 900',
      routeCode: 'UCC-01',
      fromStop: 'Old Site (North Campus)',
      toStop: 'New Examination Center (NEC)',
      viaStops: ['Science Quad', 'Casely Hayford', 'Sam Jonah Library', 'Valco Hall'],
      fareGhs: 3.50,
      nextArrivalMinutes: 4,
      busNumberPlate: 'CR-1902-23',
      driverName: 'Master Ekow',
      driverPhone: '024 330 1199',
      totalSeats: 30,
      seatsAvailable: 5,
      status: 'Arriving in 4m',
      operatingHours: '06:30 AM - 11:30 PM',
    ),
    ShuttleRoute(
      id: 'ucc_sh_2',
      routeName: 'Kwesimintsim - New Site Express',
      routeCode: 'UCC-02',
      fromStop: 'Superannuation Complex',
      toStop: 'Medical School Block',
      viaStops: ['SRC Hostel', 'KNH', 'Atlantic Hall'],
      fareGhs: 4.00,
      nextArrivalMinutes: 11,
      busNumberPlate: 'CR-4401-24',
      driverName: 'Uncle Francis',
      driverPhone: '027 881 2233',
      totalSeats: 32,
      seatsAvailable: 14,
      status: 'On Route',
      operatingHours: '06:30 AM - 11:30 PM',
    ),
  ];

  static const _uewShuttles = [
    ShuttleRoute(
      id: 'uew_sh_1',
      routeName: 'North Campus - South Campus Shuttle',
      routeCode: 'UEW-01',
      fromStop: 'North Campus (Faculty Block)',
      toStop: 'South Campus (Auditorium)',
      viaStops: ['Simpa Hall', 'Ghartey Hall', 'Library Junction'],
      fareGhs: 3.50,
      nextArrivalMinutes: 5,
      busNumberPlate: 'CR-8821-23',
      driverName: 'Kwesi Mensah',
      driverPhone: '024 551 2200',
      totalSeats: 30,
      seatsAvailable: 9,
      status: 'Departing Soon',
      operatingHours: '06:30 AM - 11:30 PM',
    ),
  ];

  static const _ugDues = [
    CampusDue(
      id: 'ug_due_1',
      title: 'COMPSSA (Computer Science Association) Dues',
      category: DueCategory.departmentDues,
      amountGhs: 50.00,
      dueDate: '2026-09-30',
      description: 'Includes annual departmental shirt, hackathon access & project server cloud hosting.',
    ),
    CampusDue(
      id: 'ug_due_2',
      title: 'Commonwealth Hall (Vandals) JCR Dues',
      category: DueCategory.hallDues,
      amountGhs: 80.00,
      dueDate: '2026-10-15',
      description: 'Annual Vandal hall week, sports fund and common room amenities.',
    ),
    CampusDue(
      id: 'ug_due_3',
      title: 'UG SRC Development & Technology Fund',
      category: DueCategory.srcLevy,
      amountGhs: 45.00,
      dueDate: '2026-08-10',
      description: 'Campus Wi-Fi expansion, shuttle subsidies, and student legal aid fund.',
    ),
    CampusDue(
      id: 'ug_due_4',
      title: 'Official Certified Transcript Application',
      category: DueCategory.transcriptAdmin,
      amountGhs: 100.00,
      dueDate: '2026-11-20',
      description: 'Academic Affairs certified statement of results & transcript envelope.',
    ),
    CampusDue(
      id: 'ug_due_5',
      title: 'Mid-Semester Assessment Resit Fee',
      category: DueCategory.examResit,
      amountGhs: 70.00,
      dueDate: '2026-10-05',
      description: 'Registration fee for supplementary paper or deferred practical assessment.',
    ),
  ];

  static const _knustDues = [
    CampusDue(
      id: 'kn_due_1',
      title: 'KNUST Computer Science Society (CoSS) Dues',
      category: DueCategory.departmentDues,
      amountGhs: 60.00,
      dueDate: '2026-09-30',
      description: 'Semester association dues for hackathons, lab kits & study packs.',
    ),
    CampusDue(
      id: 'kn_due_2',
      title: 'University Hall (Katanga) JCR Dues',
      category: DueCategory.hallDues,
      amountGhs: 85.00,
      dueDate: '2026-10-15',
      description: 'Hall week, sanitation levy & Wi-Fi maintenance.',
    ),
    CampusDue(
      id: 'kn_due_3',
      title: 'KNUST SRC Development Levy',
      category: DueCategory.srcLevy,
      amountGhs: 40.00,
      dueDate: '2026-08-15',
      description: 'Official university student representative council development fund.',
    ),
    CampusDue(
      id: 'kn_due_4',
      title: 'Official Academic Transcript Request',
      category: DueCategory.transcriptAdmin,
      amountGhs: 120.00,
      dueDate: '2026-11-30',
      description: 'Certified digital & stamped transcript from Academic Affairs.',
    ),
  ];

  static const _uccDues = [
    CampusDue(
      id: 'ucc_due_1',
      title: 'UCC Information Tech Association (ITA) Dues',
      category: DueCategory.departmentDues,
      amountGhs: 50.00,
      dueDate: '2026-09-28',
      description: 'Faculty handbook, annual seminar & technical workshop dues.',
    ),
    CampusDue(
      id: 'ucc_due_2',
      title: 'Casely Hayford Hall Dues',
      category: DueCategory.hallDues,
      amountGhs: 75.00,
      dueDate: '2026-10-10',
      description: 'Hall week celebrations, power levy and hostel maintenance.',
    ),
    CampusDue(
      id: 'ucc_due_3',
      title: 'UCC SRC Welfare & Health Levy',
      category: DueCategory.srcLevy,
      amountGhs: 35.00,
      dueDate: '2026-08-20',
      description: 'Student emergency health insurance and welfare support.',
    ),
  ];

  static const _lostFoundSeed = [
    LostFoundItem(
      id: 'lf_1',
      title: 'Casio fx-991EX ClassWiz Calculator',
      category: LostFoundCategory.calculatorsAndElectronics,
      status: LostFoundStatus.found,
      campusLocation: 'Balme Library Ground Floor Reference Desk',
      dateReported: 'Today, 10:15 AM',
      reporterName: 'Librarian Mrs. Mensah',
      contactPhone: '030 250 0150',
      description: 'Black scientific calculator left on Desk #14 near the Africana wing. Has a small blue sticker on the back.',
      claimInstructions: 'Describe sticker details or show index number to claim at the Library Circulation Desk.',
    ),
    LostFoundItem(
      id: 'lf_2',
      title: 'Student ID Card',
      category: LostFoundCategory.idAndCards,
      status: LostFoundStatus.found,
      campusLocation: 'Bush Canteen Food Court',
      dateReported: 'Yesterday, 04:30 PM',
      reporterName: 'Security Officer Dan',
      contactPhone: '024 411 9023',
      description: 'University student identity card found at a table near the waakye joint.',
      claimInstructions: 'Collect from the Bush Canteen Security Post between 8am and 6pm.',
    ),
    LostFoundItem(
      id: 'lf_3',
      title: 'HP Laptop Charger (Type-C 65W)',
      category: LostFoundCategory.calculatorsAndElectronics,
      status: LostFoundStatus.lost,
      campusLocation: 'KAB 1 Lecture Auditorium',
      dateReported: '2 days ago',
      reporterName: 'Kwame Asante',
      contactPhone: '055 882 1100',
      description: 'Black 65W Type-C adapter with red velcro cable strap. Left after a lecture on Wednesday.',
      rewardGhs: 30.00,
    ),
    LostFoundItem(
      id: 'lf_4',
      title: 'Set of Room Keys with Everton FC Keychain',
      category: LostFoundCategory.keys,
      status: LostFoundStatus.found,
      campusLocation: 'Diaspora Hall Shuttle Bus Stop',
      dateReported: '3 days ago',
      reporterName: 'Driver Uncle Kwame',
      contactPhone: '024 991 8822',
      description: '3 silver Yale keys and a blue Everton FC logo rubber keychain found on the rear shuttle seat.',
      claimInstructions: 'Call the driver directly or collect at the Transport Office.',
    ),
    LostFoundItem(
      id: 'lf_5',
      title: 'Navy Blue Backpack with Notebooks',
      category: LostFoundCategory.bagsAndWallets,
      status: LostFoundStatus.lost,
      campusLocation: 'JQB Lecture Hall 12',
      dateReported: 'Aug 20, 2026',
      reporterName: 'Abena Serwaa',
      contactPhone: '020 771 4455',
      description: 'Puma backpack containing 3 spiral notebooks and a yellow pencil case.',
      rewardGhs: 50.00,
    ),
  ];
}
