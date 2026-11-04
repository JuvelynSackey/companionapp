import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/providers/core_providers.dart';
import 'package:mobile/core/storage/local_prefs.dart';
import 'package:mobile/data/api/event_api.dart';
import 'package:mobile/data/api/grade_api.dart';
import 'package:mobile/data/models/announcement.dart';
import 'package:mobile/data/models/campus_event.dart';
import 'package:mobile/data/models/campus_location.dart';
import 'package:mobile/data/models/course_grade.dart';
import 'package:mobile/data/repositories/local_schedule_repository.dart';
import 'package:mobile/features/assistant/context_aggregator.dart';
import 'package:mobile/features/assistant/local_assistant_engine.dart';
import 'package:mobile/features/auth/session_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/admin_fakes.dart';
import 'support/assistant_fakes.dart';
import 'support/club_fakes.dart';

/// What the server-backed pieces do in a given test.
class _Env {
  _Env({this.grades, this.events, this.locations, this.announcements});
  final GradeApi? grades; // null = offline
  final EventApi? events;
  final bool? locations; // true = reachable
  final bool? announcements;
}

final _grade = CourseGrade(
  gradeId: 1,
  courseCode: 'DCIT 201',
  courseTitle: 'Mathematics',
  creditHours: 3,
  score: 85,
  letterGrade: 'A',
  semester: 'Semester 1',
  passed: true,
);

/// A student with one class today on their own (local) timetable.
Future<ProviderContainer> _container(_Env env) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await LocalPrefs.create();
  await _addClassToday(prefs);

  final container = ProviderContainer(overrides: [
    localPrefsProvider.overrideWithValue(prefs),
    sessionControllerProvider.overrideWith(() => FakeSessionController(studentUser)),
    gradeApiProvider.overrideWithValue(env.grades ?? OfflineGradeApi()),
    eventApiProvider.overrideWithValue(env.events ?? _OfflineEventApi()),
    locationApiProvider.overrideWithValue(env.locations == true ? FakeLocationApi() : OfflineLocationApi()),
    announcementApiProvider.overrideWithValue(env.announcements == true ? FakeAnnouncementApi() : OfflineAnnouncementApi()),
  ]);
  addTearDown(container.dispose);
  await container.read(sessionControllerProvider.future);
  container.listen(assistantContextProvider, (_, _) {});
  return container;
}

class _OfflineEventApi implements EventApi {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw Exception('offline');
}

/// One class today, written the way the app itself writes the timetable.
Future<void> _addClassToday(LocalPrefs prefs) async {
  await LocalScheduleRepository(prefs).add(
    courseCode: 'DCIT 205',
    courseTitle: 'Computer Science',
    lecturer: 'Prof. E. Darko',
    dayOfWeek: DateTime.now().weekday,
    startTime: '08:00',
    endTime: '09:30',
    room: 'Lab 3',
  );
}

void main() {
  group('with the server unreachable', () {
    test('the context still builds, with today\'s classes from the local timetable', () async {
      final container = await _container(_Env());

      final context = await container.read(assistantContextProvider.future);

      expect(context.todaysClasses.map((c) => c.courseTitle), ['Computer Science']);
      expect(context.userName, 'Test student');
    });

    test('all four server-backed sources are flagged unavailable', () async {
      final container = await _container(_Env());

      final context = await container.read(assistantContextProvider.future);

      expect(context.unavailable, {
        ContextSource.grades,
        ContextSource.events,
        ContextSource.announcements,
        ContextSource.locations,
      });
    });

    test('a timetable question is still answered from local data', () async {
      final container = await _container(_Env());
      final context = await container.read(assistantContextProvider.future);

      final reply = LocalAssistantEngine.respond('what classes do I have today?', context);

      expect(reply, contains('Computer Science'));
      expect(reply, contains('Lab 3'));
    });

    test('a portal question is still answered, and a library question says the map is out of reach', () async {
      final container = await _container(_Env());
      final context = await container.read(assistantContextProvider.future);

      expect(LocalAssistantEngine.respond('how do I register on my student portal', context), contains('Sakai'));
      expect(LocalAssistantEngine.respond('where are the study desks', context), contains("can't reach the server"));
    });

    test('topics with no real data behind them get the general help, not invented facts', () async {
      final container = await _container(_Env());
      final context = await container.read(assistantContextProvider.future);

      for (final question in ['how do I connect to wifi', 'when does the shuttle come', 'how do I pay my dues with momo']) {
        final reply = LocalAssistantEngine.respond(question, context);
        expect(reply, contains('Ask me anything'), reason: question);
        for (final invented in ['eduroam', 'PEAP', 'every 8-12 minutes', 'GH₵', 'Cash Office']) {
          expect(reply, isNot(contains(invented)), reason: '$question: $invented');
        }
      }
    });

    test('a GPA question says the server cannot be reached, instead of claiming there are no grades', () async {
      final container = await _container(_Env());
      final context = await container.read(assistantContextProvider.future);

      final reply = LocalAssistantEngine.respond('what is my gpa', context);

      expect(reply, contains("can't reach the server"));
      expect(reply, contains('grades'));
      expect(reply, isNot(contains('No Data')));
      expect(reply, isNot(contains('0.00')));
    });

    test('an events question says the server cannot be reached, instead of "no events"', () async {
      final container = await _container(_Env());
      final context = await container.read(assistantContextProvider.future);

      final reply = LocalAssistantEngine.respond('what events are happening', context);

      expect(reply, contains("can't reach the server"));
      expect(reply, isNot(contains('No upcoming events')));
    });

    test('the Gemini prompt says what is unavailable and does not invent a GPA', () async {
      final container = await _container(_Env());
      final context = await container.read(assistantContextProvider.future);

      final prompt = context.toSystemPrompt();

      expect(prompt, contains('could not be reached'));
      expect(prompt, contains('grades'));
      expect(prompt, contains('Cumulative GPA: unavailable'));
      expect(prompt, contains('Upcoming Events: Unavailable.'));
      expect(prompt, contains('Computer Science'), reason: 'local data is still included');
    });
  });

  group('when only some of the server is unreachable', () {
    test('only the failed source is flagged; the others load normally', () async {
      final container = await _container(_Env(
        grades: null, // offline
        events: FakeEventApi(const []),
        locations: true,
        announcements: true,
      ));

      final context = await container.read(assistantContextProvider.future);

      expect(context.unavailable, {ContextSource.grades});
      expect(LocalAssistantEngine.respond('what events are happening', context), contains('No upcoming events'),
          reason: 'reachable and genuinely empty is different from unreachable');
    });

    test('grades that load produce a real GPA, and nothing is flagged', () async {
      final container = await _container(_Env(
        grades: FakeGradeApi([_grade]),
        events: FakeEventApi(const []),
        locations: true,
        announcements: true,
      ));

      final context = await container.read(assistantContextProvider.future);

      expect(context.unavailable, isEmpty);
      expect(context.academicMetric.formattedScore, '4.00 / 4.00');
      expect(context.toSystemPrompt(), isNot(contains('could not be reached')));
      expect(LocalAssistantEngine.respond('what is my gpa', context), contains('4.00'));
      // DCIT 201 has a readable level, so the class comes from the FGPA and says so.
      expect(LocalAssistantEngine.respond('what is my gpa', context), contains('Class (from FGPA 4.00)'));
      expect(context.toSystemPrompt(), contains('class (from fgpa 4.00): First Class Honours'));
    });
  });

  test('the four server calls run at the same time, not one after another', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await LocalPrefs.create();
    final gate = Completer<void>();
    final started = <String>[];

    final container = ProviderContainer(overrides: [
      localPrefsProvider.overrideWithValue(prefs),
      sessionControllerProvider.overrideWith(() => FakeSessionController(studentUser)),
      gradeApiProvider.overrideWithValue(_SlowGradeApi(started, gate.future)),
      eventApiProvider.overrideWithValue(_SlowEventApi(started, gate.future)),
      locationApiProvider.overrideWithValue(_SlowLocationApi(started, gate.future)),
      announcementApiProvider.overrideWithValue(_SlowAnnouncementApi(started, gate.future)),
    ]);
    addTearDown(container.dispose);
    await container.read(sessionControllerProvider.future);
    container.listen(assistantContextProvider, (_, _) {});

    final pending = container.read(assistantContextProvider.future);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(started.toSet(), {'grades', 'events', 'locations', 'announcements'},
        reason: 'all four requests were sent before any of them finished');

    gate.complete();
    expect((await pending).unavailable, isEmpty);
  });
}

class _SlowGradeApi extends FakeGradeApi {
  _SlowGradeApi(this.started, this.gate) : super(const []);
  final List<String> started;
  final Future<void> gate;

  @override
  Future<List<CourseGrade>> fetch() async {
    started.add('grades');
    await gate;
    return const [];
  }
}

class _SlowEventApi extends FakeEventApi {
  _SlowEventApi(this.started, this.gate) : super(const []);
  final List<String> started;
  final Future<void> gate;

  @override
  Future<List<CampusEvent>> fetch({bool upcoming = true}) async {
    started.add('events');
    await gate;
    return const [];
  }
}

class _SlowLocationApi extends FakeLocationApi {
  _SlowLocationApi(this.started, this.gate);
  final List<String> started;
  final Future<void> gate;

  @override
  Future<List<CampusLocation>> fetch({String? category, String? search}) async {
    started.add('locations');
    await gate;
    return const [];
  }
}

class _SlowAnnouncementApi extends FakeAnnouncementApi {
  _SlowAnnouncementApi(this.started, this.gate);
  final List<String> started;
  final Future<void> gate;

  @override
  Future<List<Announcement>> fetch({int limit = 50}) async {
    started.add('announcements');
    await gate;
    return const [];
  }
}
