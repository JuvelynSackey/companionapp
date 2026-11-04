import 'package:flutter/material.dart';

/// Institution branding and grading rules.
/// Phase 1 used this for branding/theme only; Phase 2 restores the grading
/// system + honours thresholds for the institution-aware GPA/CWA engine
/// (see AcademicEngine). Campus-zone and sample-schedule/exam fields from
/// the source model stay dropped — Phase 1/2 get real data from the backend.
enum GradingSystemType { gpa4_0, knustCwa, scale5_0, scale4_3 }

class HonoursThreshold {
  const HonoursThreshold({
    required this.title,
    required this.minScore,
    required this.maxScore,
    required this.color,
  });

  final String title;
  final double minScore;
  final double maxScore;
  final Color color;
}

/// The category of a portal entry that is an official document (a PDF of
/// regulations, say) rather than a website to sign in to.
const officialDocumentsCategory = 'Official documents';

class InstitutionPortal {
  const InstitutionPortal({
    required this.id,
    required this.name,
    required this.description,
    required this.url,
    required this.category,
  });

  final String id;
  final String name;
  final String description;
  final String url;
  final String category;
}

class InstitutionProfile {
  const InstitutionProfile({
    required this.id,
    required this.name,
    required this.shortCode,
    required this.motto,
    required this.city,
    required this.region,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.gradingSystem,
    required this.honoursThresholds,
    required this.portals,
    required this.studentPortalName,
    required this.lmsName,
    required this.libraryName,
    this.levelWeights = const {},
  });

  final String id;
  final String name;
  final String shortCode;
  final String motto;
  final String city;
  final String region;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final GradingSystemType gradingSystem;
  final List<HonoursThreshold> honoursThresholds;
  final List<InstitutionPortal> portals;
  final String studentPortalName;
  final String lmsName;
  final String libraryName;

  /// How each course level counts towards the degree class, when the
  /// institution classifies on a level-weighted average (keyed 100, 200, ...).
  /// Empty means the class comes from the plain cumulative average.
  final Map<int, int> levelWeights;
}

class InstitutionRegistry {
  InstitutionRegistry._();

  static const ug = InstitutionProfile(
    id: 'ug_legon',
    name: 'University of Ghana',
    shortCode: 'UG',
    motto: 'Integri Procedamus (Proceed with Integrity)',
    city: 'Legon, Accra',
    region: 'Greater Accra',
    primaryColor: Color(0xFF1E3A8A),
    secondaryColor: Color(0xFFD97706),
    accentColor: Color(0xFFDC2626),
    gradingSystem: GradingSystemType.gpa4_0,
    honoursThresholds: [
      HonoursThreshold(title: 'First Class Honours', minScore: 3.60, maxScore: 4.00, color: Color(0xFF10B981)),
      HonoursThreshold(title: 'Second Class (Upper)', minScore: 3.00, maxScore: 3.59, color: Color(0xFF3B82F6)),
      HonoursThreshold(title: 'Second Class (Lower)', minScore: 2.00, maxScore: 2.99, color: Color(0xFFF59E0B)),
      HonoursThreshold(title: 'Third Class', minScore: 1.50, maxScore: 1.99, color: Color(0xFFF97316)),
      HonoursThreshold(title: 'Pass', minScore: 1.00, maxScore: 1.49, color: Color(0xFF6B7280)),
      HonoursThreshold(title: 'Fail', minScore: 0.00, maxScore: 0.99, color: Color(0xFFEF4444)),
    ],
    portals: [
      InstitutionPortal(
        id: 'ug_sakai',
        name: 'Sakai LMS',
        description: 'Course materials, lecture slides, assignments & quiz submissions',
        url: 'https://sakai.ug.edu.gh',
        category: 'LMS & Virtual Class',
      ),
      InstitutionPortal(
        id: 'ug_mis',
        name: 'MIS Web Portal',
        description: 'Semester registration, grades slip, fees statement & student profile',
        url: 'https://misweb.ug.edu.gh',
        category: 'Student Records / SIS',
      ),
      InstitutionPortal(
        id: 'ug_balme',
        name: 'Balme Digital Library',
        description: 'UGRIS digital repository, e-journals, research theses & past questions',
        url: 'http://balme.ug.edu.gh',
        category: 'Library & E-Resources',
      ),
      InstitutionPortal(
        id: 'ug_regulations',
        name: 'Regulations for Junior Members (2017)',
        description: 'The official grading system, degree classification and examination rules (PDF)',
        url: 'https://www.ug.edu.gh/sites/default/files/UG_Regulations_for_Junior_Members-2017.pdf',
        category: officialDocumentsCategory,
      ),
    ],
    studentPortalName: 'MIS Web',
    lmsName: 'Sakai LMS',
    libraryName: 'Balme Library',
    // The FGPA weights the GPAs of Levels 100-400 as 1:1:2:2 (Regulations for
    // Junior Members, September 2017, 9.31b).
    levelWeights: {100: 1, 200: 1, 300: 2, 400: 2},
  );

  static const knust = InstitutionProfile(
    id: 'knust_kumasi',
    name: 'Kwame Nkrumah Univ. of Science & Tech',
    shortCode: 'KNUST',
    motto: 'Nyansapɔw Wɔsane No Badwemma',
    city: 'Kumasi',
    region: 'Ashanti Region',
    primaryColor: Color(0xFFB45309),
    secondaryColor: Color(0xFF15803D),
    accentColor: Color(0xFF881337),
    gradingSystem: GradingSystemType.knustCwa,
    honoursThresholds: [
      HonoursThreshold(title: 'First Class Honours', minScore: 70.0, maxScore: 100.0, color: Color(0xFF10B981)),
      HonoursThreshold(title: 'Second Class (Upper)', minScore: 60.0, maxScore: 69.99, color: Color(0xFF3B82F6)),
      HonoursThreshold(title: 'Second Class (Lower)', minScore: 50.0, maxScore: 59.99, color: Color(0xFFF59E0B)),
      HonoursThreshold(title: 'Pass', minScore: 40.0, maxScore: 49.99, color: Color(0xFFF97316)),
      HonoursThreshold(title: 'Fail / Trail', minScore: 0.0, maxScore: 39.99, color: Color(0xFFEF4444)),
    ],
    portals: [
      InstitutionPortal(
        id: 'knust_vclass',
        name: 'Virtual Classroom (VClass)',
        description: 'KNUST official online learning portal and lecture materials',
        url: 'https://vclass.knust.edu.gh',
        category: 'LMS & Virtual Class',
      ),
      InstitutionPortal(
        id: 'knust_aim',
        name: 'AIM Student App Portal',
        description: 'Academic Information Manager: course registration, results & fees',
        url: 'https://apps.knust.edu.gh/students',
        category: 'Student Records / SIS',
      ),
      InstitutionPortal(
        id: 'knust_prempeh',
        name: 'Prempeh II Digital Library',
        description: 'E-Repository, science publications, and research archives',
        url: 'https://library.knust.edu.gh',
        category: 'Library & E-Resources',
      ),
    ],
    studentPortalName: 'AIM Portal',
    lmsName: 'VClass (Virtual Classroom)',
    libraryName: 'Prempeh II Library',
  );

  static const ashesi = InstitutionProfile(
    id: 'ashesi_berekuso',
    name: 'Ashesi University',
    shortCode: 'ASHESI',
    motto: 'Scholarship, Leadership, Citizenship',
    city: 'Berekuso',
    region: 'Eastern Region',
    primaryColor: Color(0xFF991B1B),
    secondaryColor: Color(0xFFD97706),
    accentColor: Color(0xFF0F766E),
    gradingSystem: GradingSystemType.gpa4_0,
    honoursThresholds: [
      HonoursThreshold(title: 'Summa Cum Laude', minScore: 3.85, maxScore: 4.00, color: Color(0xFF10B981)),
      HonoursThreshold(title: 'Magna Cum Laude', minScore: 3.70, maxScore: 3.84, color: Color(0xFF3B82F6)),
      HonoursThreshold(title: 'Cum Laude', minScore: 3.50, maxScore: 3.69, color: Color(0xFF8B5CF6)),
      HonoursThreshold(title: 'Good Standing', minScore: 2.50, maxScore: 3.49, color: Color(0xFFF59E0B)),
      HonoursThreshold(title: 'Academic Warning', minScore: 2.00, maxScore: 2.49, color: Color(0xFFF97316)),
      HonoursThreshold(title: 'Probation / Fail', minScore: 0.00, maxScore: 1.99, color: Color(0xFFEF4444)),
    ],
    portals: [
      InstitutionPortal(
        id: 'ashesi_canvas',
        name: 'Canvas LMS',
        description: 'Assignments, lecture discussions, and gradebook updates',
        url: 'https://ashesi.instructure.com',
        category: 'LMS & Virtual Class',
      ),
      InstitutionPortal(
        id: 'ashesi_sis',
        name: 'Ashesi SIS Portal',
        description: 'Course registration, degree audits, and financial account ledger',
        url: 'https://sis.ashesi.edu.gh',
        category: 'Student Records / SIS',
      ),
      InstitutionPortal(
        id: 'ashesi_lib',
        name: 'Todd & Diana Berman Library',
        description: 'EBSCO, JSTOR, IEEE research databases, and archives',
        url: 'https://library.ashesi.edu.gh',
        category: 'Library & E-Resources',
      ),
    ],
    studentPortalName: 'Ashesi SIS',
    lmsName: 'Canvas LMS',
    libraryName: 'Berman Library',
  );

  static const ucc = InstitutionProfile(
    id: 'ucc_capecoast',
    name: 'University of Cape Coast',
    shortCode: 'UCC',
    motto: 'Veritas Nobis Lumen',
    city: 'Cape Coast',
    region: 'Central Region',
    primaryColor: Color(0xFF1D4ED8),
    secondaryColor: Color(0xFFBE123C),
    accentColor: Color(0xFFEAB308),
    gradingSystem: GradingSystemType.gpa4_0,
    honoursThresholds: [
      HonoursThreshold(title: 'First Class Honours', minScore: 3.60, maxScore: 4.00, color: Color(0xFF10B981)),
      HonoursThreshold(title: 'Second Class (Upper)', minScore: 3.00, maxScore: 3.59, color: Color(0xFF3B82F6)),
      HonoursThreshold(title: 'Second Class (Lower)', minScore: 2.00, maxScore: 2.99, color: Color(0xFFF59E0B)),
      HonoursThreshold(title: 'Third Class', minScore: 1.50, maxScore: 1.99, color: Color(0xFFF97316)),
      HonoursThreshold(title: 'Pass', minScore: 1.00, maxScore: 1.49, color: Color(0xFF6B7280)),
      HonoursThreshold(title: 'Fail', minScore: 0.00, maxScore: 0.99, color: Color(0xFFEF4444)),
    ],
    portals: [
      InstitutionPortal(
        id: 'ucc_moodle',
        name: 'UCC Moodle LMS',
        description: 'Official course repository, e-quizzes, and lecture modules',
        url: 'https://moodle.ucc.edu.gh',
        category: 'LMS & Virtual Class',
      ),
      InstitutionPortal(
        id: 'ucc_osis',
        name: 'UCC OSIS Portal',
        description: 'Online Student Information System for registration and results',
        url: 'https://osis.ucc.edu.gh',
        category: 'Student Records / SIS',
      ),
      InstitutionPortal(
        id: 'ucc_jonah',
        name: 'Sam Jonah E-Library',
        description: 'Research papers, past question bank, and journal databases',
        url: 'https://library.ucc.edu.gh',
        category: 'Library & E-Resources',
      ),
    ],
    studentPortalName: 'UCC OSIS',
    lmsName: 'UCC Moodle',
    libraryName: 'Sam Jonah Library',
  );

  static const gimpa = InstitutionProfile(
    id: 'gimpa_greenhill',
    name: 'GIMPA (Greenhill)',
    shortCode: 'GIMPA',
    motto: 'Excellence in Leadership, Management and Administration',
    city: 'Greenhill, Accra',
    region: 'Greater Accra',
    primaryColor: Color(0xFF047857),
    secondaryColor: Color(0xFFCA8A04),
    accentColor: Color(0xFF1E293B),
    gradingSystem: GradingSystemType.gpa4_0,
    honoursThresholds: [
      HonoursThreshold(title: 'First Class Honours', minScore: 3.60, maxScore: 4.00, color: Color(0xFF10B981)),
      HonoursThreshold(title: 'Second Class (Upper)', minScore: 3.00, maxScore: 3.59, color: Color(0xFF3B82F6)),
      HonoursThreshold(title: 'Second Class (Lower)', minScore: 2.00, maxScore: 2.99, color: Color(0xFFF59E0B)),
      HonoursThreshold(title: 'Third Class', minScore: 1.50, maxScore: 1.99, color: Color(0xFFF97316)),
      HonoursThreshold(title: 'Pass', minScore: 1.00, maxScore: 1.49, color: Color(0xFF6B7280)),
      HonoursThreshold(title: 'Fail', minScore: 0.00, maxScore: 0.99, color: Color(0xFFEF4444)),
    ],
    portals: [
      InstitutionPortal(
        id: 'gimpa_erp',
        name: 'GIMPA ERP Portal',
        description: 'Student ERP for course registration, fee receipts & results',
        url: 'https://erp.gimpa.edu.gh',
        category: 'Student Records / SIS',
      ),
      InstitutionPortal(
        id: 'gimpa_moodle',
        name: 'GIMPA Moodle',
        description: 'Virtual classes and postgraduate executive assignments',
        url: 'https://moodle.gimpa.edu.gh',
        category: 'LMS & Virtual Class',
      ),
      InstitutionPortal(
        id: 'gimpa_lib',
        name: 'Greenhill Digital Library',
        description: 'Public administration, governance, and business journals',
        url: 'https://library.gimpa.edu.gh',
        category: 'Library & E-Resources',
      ),
    ],
    studentPortalName: 'GIMPA ERP',
    lmsName: 'GIMPA Moodle',
    libraryName: 'Greenhill Library',
  );

  static const uew = InstitutionProfile(
    id: 'uew_winneba',
    name: 'University of Education, Winneba',
    shortCode: 'UEW',
    motto: 'Education for Service',
    city: 'Winneba',
    region: 'Central Region',
    primaryColor: Color(0xFF831843),
    secondaryColor: Color(0xFFF59E0B),
    accentColor: Color(0xFF1E3A8A),
    gradingSystem: GradingSystemType.gpa4_0,
    honoursThresholds: [
      HonoursThreshold(title: 'First Class Honours', minScore: 3.60, maxScore: 4.00, color: Color(0xFF10B981)),
      HonoursThreshold(title: 'Second Class (Upper)', minScore: 3.00, maxScore: 3.59, color: Color(0xFF3B82F6)),
      HonoursThreshold(title: 'Second Class (Lower)', minScore: 2.00, maxScore: 2.99, color: Color(0xFFF59E0B)),
      HonoursThreshold(title: 'Third Class', minScore: 1.50, maxScore: 1.99, color: Color(0xFFF97316)),
      HonoursThreshold(title: 'Pass', minScore: 1.00, maxScore: 1.49, color: Color(0xFF6B7280)),
      HonoursThreshold(title: 'Fail', minScore: 0.00, maxScore: 0.99, color: Color(0xFFEF4444)),
    ],
    portals: [
      InstitutionPortal(
        id: 'uew_its',
        name: 'UEW OSIS / ITS Portal',
        description: 'Course registration, fee slips and semester examination results',
        url: 'https://osis.uew.edu.gh',
        category: 'Student Records / SIS',
      ),
      InstitutionPortal(
        id: 'uew_lms',
        name: 'UEW VClass LMS',
        description: 'Virtual learning environment, module materials & lecture submissions',
        url: 'https://vclass.uew.edu.gh',
        category: 'LMS & Virtual Class',
      ),
      InstitutionPortal(
        id: 'uew_lib',
        name: 'Osagyefo Library',
        description: 'Institutional repository, educational journals & past papers',
        url: 'https://library.uew.edu.gh',
        category: 'Library & E-Resources',
      ),
    ],
    studentPortalName: 'UEW OSIS',
    lmsName: 'UEW VClass',
    libraryName: 'Osagyefo Library',
  );

  static const atu = InstitutionProfile(
    id: 'atu_accra',
    name: 'Accra Technical University',
    shortCode: 'ATU',
    motto: 'Work Conquers All',
    city: 'Barnes Road, Accra',
    region: 'Greater Accra',
    primaryColor: Color(0xFF0284C7),
    secondaryColor: Color(0xFFE11D48),
    accentColor: Color(0xFFF59E0B),
    gradingSystem: GradingSystemType.scale5_0,
    honoursThresholds: [
      HonoursThreshold(title: 'First Class Honours', minScore: 4.50, maxScore: 5.00, color: Color(0xFF10B981)),
      HonoursThreshold(title: 'Second Class (Upper)', minScore: 3.50, maxScore: 4.49, color: Color(0xFF3B82F6)),
      HonoursThreshold(title: 'Second Class (Lower)', minScore: 2.50, maxScore: 3.49, color: Color(0xFFF59E0B)),
      HonoursThreshold(title: 'Pass', minScore: 1.50, maxScore: 2.49, color: Color(0xFF6B7280)),
      HonoursThreshold(title: 'Fail', minScore: 0.00, maxScore: 1.49, color: Color(0xFFEF4444)),
    ],
    portals: [
      InstitutionPortal(
        id: 'atu_portal',
        name: 'ATU Student Portal',
        description: 'Admissions, semester course registration & grades',
        url: 'https://portal.atu.edu.gh',
        category: 'Student Records / SIS',
      ),
      InstitutionPortal(
        id: 'atu_lms',
        name: 'ATU E-Learning',
        description: 'Online lecture notes, engineering labs and continuous assessments',
        url: 'https://elearning.atu.edu.gh',
        category: 'LMS & Virtual Class',
      ),
    ],
    studentPortalName: 'ATU Portal',
    lmsName: 'ATU E-Learning',
    libraryName: 'ATU Central Library',
  );

  static const List<InstitutionProfile> all = [ug, knust, ashesi, ucc, uew, atu, gimpa];

  static InstitutionProfile getById(String id) {
    for (final institution in all) {
      if (institution.id.toLowerCase() == id.toLowerCase() ||
          institution.shortCode.toLowerCase() == id.toLowerCase()) {
        return institution;
      }
    }
    return ug;
  }
}
