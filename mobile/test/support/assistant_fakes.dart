import 'dart:async';

import 'package:mobile/data/api/announcement_api.dart';
import 'package:mobile/data/api/grade_api.dart';
import 'package:mobile/data/api/location_api.dart';
import 'package:mobile/data/logic/academic_engine.dart';
import 'package:mobile/data/models/announcement.dart';
import 'package:mobile/data/models/campus_location.dart';
import 'package:mobile/data/models/course_grade.dart';
import 'package:mobile/data/models/institution_profile.dart';
import 'package:mobile/features/assistant/context_aggregator.dart';
import 'package:mobile/features/assistant/gemini_assistant_service.dart';
import 'package:mobile/features/assistant/models/assistant_message.dart';

/// Shared fakes for the assistant tests.

AssistantContext sampleContext({Set<ContextSource> unavailable = const {}}) => AssistantContext(
      userName: 'Ama',
      institution: InstitutionRegistry.ug,
      todaysClasses: const [],
      examCountdowns: const [],
      locations: const [],
      announcements: const [],
      academicMetric: AcademicEngine.calculate(const <CourseGrade>[], InstitutionRegistry.ug),
      events: const [],
      unavailable: unavailable,
    );

/// Records every question and the history it was sent with; replies with
/// [reply] (null = "Gemini failed, use the local engine"), optionally held
/// until [gate] completes.
class FakeGemini implements GeminiAssistantService {
  FakeGemini({this.reply});

  String? reply;
  Completer<void>? gate;
  final queries = <String>[];
  final histories = <List<AssistantMessage>>[];
  final systemPrompts = <String>[];
  final attachments = <GeminiAttachment?>[];

  @override
  Future<String?> ask({
    required String systemPrompt,
    required String query,
    List<AssistantMessage> history = const [],
    GeminiAttachment? attachment,
  }) async {
    queries.add(query);
    attachments.add(attachment);
    histories.add(history);
    systemPrompts.add(systemPrompt);
    await gate?.future;
    return reply;
  }
}

/// Every call fails, like a device with no connection.
class OfflineLocationApi implements LocationApi {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw Exception('offline');
}

class OfflineAnnouncementApi implements AnnouncementApi {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw Exception('offline');
}

class OfflineGradeApi implements GradeApi {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw Exception('offline');
}

class FakeLocationApi implements LocationApi {
  @override
  Future<List<CampusLocation>> fetch({String? category, String? search}) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class FakeAnnouncementApi implements AnnouncementApi {
  @override
  Future<List<Announcement>> fetch({int limit = 50}) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class FakeGradeApi implements GradeApi {
  FakeGradeApi(this.grades);
  final List<CourseGrade> grades;

  @override
  Future<List<CourseGrade>> fetch() async => grades;
}
