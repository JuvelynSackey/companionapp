import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/engine/context_engine.dart';
import 'package:mobile/data/models/campus_location.dart';
import 'package:mobile/data/models/exam.dart';
import 'package:mobile/data/models/exam_countdown.dart';
import 'package:mobile/data/models/schedule_entry.dart';

ScheduleEntry _entry({
  required int id,
  required String code,
  required String start,
  required String end,
  String? room,
}) =>
    ScheduleEntry.create(
      scheduleId: id,
      courseCode: code,
      courseTitle: code,
      lecturer: 'Prof. X',
      dayOfWeek: 1,
      startTime: start,
      endTime: end,
      room: room,
    );

void main() {
  group('ContextEngine.evaluate — daily brief', () {
    test('reports zero classes and no exam when both are empty', () {
      final actions = ContextEngine.evaluate(
        todaysSchedule: const [],
        examCountdowns: const [],
        locations: const [],
        now: DateTime(2026, 8, 31, 8, 0),
      );
      final brief = actions.firstWhere((a) => a.type == ContextActionType.dailyBrief);
      expect(brief.description, 'No classes today.');
    });

    test('summarizes class count and the next non-past exam', () {
      final exam = ExamCountdownUtils.getCountdownInfo(
        Exam(id: 'e1', courseCode: 'DCIT 201', courseTitle: 'Mathematics', examDate: '2026-09-09', startTime: '09:00', endTime: '12:00', venue: 'Room 204'),
        now: DateTime(2026, 8, 31),
      );
      final actions = ContextEngine.evaluate(
        todaysSchedule: [_entry(id: 1, code: 'DCIT 201', start: '09:00', end: '10:00')],
        examCountdowns: [exam],
        locations: const [],
        now: DateTime(2026, 8, 31, 8, 0),
      );
      final brief = actions.firstWhere((a) => a.type == ContextActionType.dailyBrief);
      expect(brief.description, contains('1 class today'));
      expect(brief.description, contains('DCIT 201'));
    });
  });

  group('ContextEngine.evaluate — schedule conflicts', () {
    test('detects two overlapping classes on the same day', () {
      final actions = ContextEngine.evaluate(
        todaysSchedule: [
          _entry(id: 1, code: 'DCIT 201', start: '09:00', end: '10:30'),
          _entry(id: 2, code: 'DCIT 202', start: '10:00', end: '11:00'),
        ],
        examCountdowns: const [],
        locations: const [],
        now: DateTime(2026, 8, 31, 8, 0),
      );
      expect(actions.where((a) => a.type == ContextActionType.scheduleConflict), hasLength(1));
    });

    test('does not flag back-to-back classes that only touch at the boundary', () {
      final actions = ContextEngine.evaluate(
        todaysSchedule: [
          _entry(id: 1, code: 'DCIT 201', start: '09:00', end: '10:00'),
          _entry(id: 2, code: 'DCIT 202', start: '10:00', end: '11:00'),
        ],
        examCountdowns: const [],
        locations: const [],
        now: DateTime(2026, 8, 31, 8, 0),
      );
      expect(actions.where((a) => a.type == ContextActionType.scheduleConflict), isEmpty);
    });
  });

  group('ContextEngine.evaluate — class starting soon', () {
    test('fires within the warning window and not outside it', () {
      final actions = ContextEngine.evaluate(
        todaysSchedule: [_entry(id: 1, code: 'DCIT 201', start: '09:20', end: '10:00')],
        examCountdowns: const [],
        locations: const [],
        now: DateTime(2026, 8, 31, 9, 0), // 20 min before start — inside the 30-min window
      );
      expect(actions.where((a) => a.type == ContextActionType.classStartingSoon), hasLength(1));

      final tooEarly = ContextEngine.evaluate(
        todaysSchedule: [_entry(id: 1, code: 'DCIT 201', start: '12:00', end: '13:00')],
        examCountdowns: const [],
        locations: const [],
        now: DateTime(2026, 8, 31, 9, 0), // hours away
      );
      expect(tooEarly.where((a) => a.type == ContextActionType.classStartingSoon), isEmpty);
    });

    test('computes a walk-time estimate when both rooms match a real CampusLocation', () {
      // Balme Library and Great Hall from the real backend seed data, ~250m apart.
      final locations = [
        CampusLocation(locationId: 1, name: 'Balme Library', category: 'library', description: '', latitude: 5.6508, longitude: -0.1866),
        CampusLocation(locationId: 2, name: 'Great Hall', category: 'other', description: '', latitude: 5.6522, longitude: -0.1869),
      ];
      final actions = ContextEngine.evaluate(
        todaysSchedule: [
          _entry(id: 1, code: 'DCIT 201', start: '09:00', end: '09:50', room: 'Balme Library'),
          _entry(id: 2, code: 'DCIT 202', start: '10:00', end: '11:00', room: 'Great Hall'),
        ],
        examCountdowns: const [],
        locations: locations,
        now: DateTime(2026, 8, 31, 9, 45), // 15 min before the second class
      );
      final warning = actions.firstWhere(
        (a) => a.type == ContextActionType.classStartingSoon && a.title.contains('DCIT 202'),
      );
      expect(warning.estimatedWalkMinutes, isNotNull);
      expect(warning.estimatedWalkMinutes, greaterThan(0));
    });

    test('omits the walk estimate (but still reminds) when the room cannot be matched to a known location', () {
      final actions = ContextEngine.evaluate(
        todaysSchedule: [_entry(id: 1, code: 'DCIT 201', start: '09:20', end: '10:00', room: 'Some Unknown Room 999')],
        examCountdowns: const [],
        locations: const [],
        now: DateTime(2026, 8, 31, 9, 0),
      );
      final warning = actions.firstWhere((a) => a.type == ContextActionType.classStartingSoon);
      expect(warning.estimatedWalkMinutes, isNull);
      expect(warning.description, contains('Starts in 20 min'));
    });
  });

  group('ContextEngine.evaluate — exam approaching', () {
    test('flags an exam within 48 hours and excludes one further out', () {
      final soon = ExamCountdownUtils.getCountdownInfo(
        Exam(id: 'e1', courseCode: 'DCIT 201', courseTitle: 'Math', examDate: '2026-09-01', startTime: '09:00', endTime: '12:00', venue: 'Room 204'),
        now: DateTime(2026, 8, 31),
      );
      final far = ExamCountdownUtils.getCountdownInfo(
        Exam(id: 'e2', courseCode: 'DCIT 205', courseTitle: 'CS', examDate: '2026-09-20', startTime: '09:00', endTime: '12:00', venue: 'Room 204'),
        now: DateTime(2026, 8, 31),
      );
      final actions = ContextEngine.evaluate(
        todaysSchedule: const [],
        examCountdowns: [soon, far],
        locations: const [],
        now: DateTime(2026, 8, 31),
      );
      final examActions = actions.where((a) => a.type == ContextActionType.examApproaching).toList();
      expect(examActions, hasLength(1));
      expect(examActions.single.title, contains('DCIT 201'));
    });
  });

  group('CampusContextAction.requiresImmediateDeparture', () {
    test('is true when the walk takes about as long as the time remaining', () {
      const action = CampusContextAction(
        type: ContextActionType.classStartingSoon,
        title: 't',
        description: 'd',
        minutesRemaining: 10,
        estimatedWalkMinutes: 8,
        primaryButtonText: 'Go',
      );
      expect(action.requiresImmediateDeparture, isTrue);
    });

    test('is false with a comfortable margin, and false when data is missing', () {
      const comfortable = CampusContextAction(
        type: ContextActionType.classStartingSoon,
        title: 't',
        description: 'd',
        minutesRemaining: 20,
        estimatedWalkMinutes: 5,
        primaryButtonText: 'Go',
      );
      expect(comfortable.requiresImmediateDeparture, isFalse);

      const noWalkData = CampusContextAction(
        type: ContextActionType.classStartingSoon,
        title: 't',
        description: 'd',
        minutesRemaining: 5,
        primaryButtonText: 'Go',
      );
      expect(noWalkData.requiresImmediateDeparture, isFalse);
    });
  });
}
