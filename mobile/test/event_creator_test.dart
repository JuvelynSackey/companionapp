import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/models/app_user.dart';
import 'package:mobile/data/models/campus_event.dart';

import 'support/admin_fakes.dart';

Map<String, dynamic> _json({Object? createdBy = 7, bool includeCreatedBy = true}) => {
      'eventId': 5,
      'title': 'Tech Talk',
      'description': 'Speakers',
      'eventDate': '2030-05-01T14:00:00.000Z',
      'location': 'Auditorium',
      'clubName': 'Computer Science Society',
      'attendeeCount': 2,
      'isRegistered': null,
      if (includeCreatedBy) 'createdBy': createdBy,
    };

void main() {
  group('CampusEvent.fromJson createdBy', () {
    test('is read from the API', () {
      expect(CampusEvent.fromJson(_json(createdBy: 7)).createdBy, 7);
    });

    test('is null when the creating account no longer exists', () {
      expect(CampusEvent.fromJson(_json(createdBy: null)).createdBy, isNull);
    });

    test('is null when an older server does not send it, and nothing else breaks', () {
      final event = CampusEvent.fromJson(_json(includeCreatedBy: false));
      expect(event.createdBy, isNull);
      expect(event.title, 'Tech Talk');
      expect(event.isRegistered, isFalse);
    });
  });

  group('AppUser.canDeleteEvent', () {
    test('an admin can delete any event, including one with no known creator', () {
      expect(adminUser.canDeleteEvent(adminUser.userId), isTrue);
      expect(adminUser.canDeleteEvent(lecturerUser.userId), isTrue);
      expect(adminUser.canDeleteEvent(999), isTrue);
      expect(adminUser.canDeleteEvent(null), isTrue);
    });

    test('a lecturer can delete only events they created', () {
      expect(lecturerUser.canDeleteEvent(lecturerUser.userId), isTrue);
      expect(lecturerUser.canDeleteEvent(adminUser.userId), isFalse, reason: 'an admin\'s event');
      expect(lecturerUser.canDeleteEvent(999), isFalse, reason: 'another lecturer\'s event');
    });

    test('a lecturer cannot delete an event with no known creator', () {
      expect(lecturerUser.canDeleteEvent(null), isFalse);
    });

    test('a student can delete nothing, even where the creator id happens to match theirs', () {
      expect(studentUser.canDeleteEvent(studentUser.userId), isFalse);
      expect(studentUser.canDeleteEvent(adminUser.userId), isFalse);
      expect(studentUser.canDeleteEvent(null), isFalse);
    });

    test('the lecturer rule follows the events:create permission, the same gate as the backend route', () {
      AppUser lecturerWith(Set<String> permissions) =>
          AppUser(userId: 7, fullName: 'L', email: 'l@ug.edu.gh', role: 'lecturer', permissions: permissions);

      expect(lecturerWith({'events:create'}).canDeleteEvent(7), isTrue);
      expect(lecturerWith(const {}).canDeleteEvent(7), isFalse);
    });
  });
}
