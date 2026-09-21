import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/models/club.dart';

void main() {
  group('Club.fromJson', () {
    test('parses a full club', () {
      final club = Club.fromJson({
        'clubId': 3,
        'name': 'Debate Union',
        'description': 'Weekly debates.',
        'memberCount': 12,
        'isMember': true,
      });

      expect(club.clubId, 3);
      expect(club.name, 'Debate Union');
      expect(club.description, 'Weekly debates.');
      expect(club.memberCount, 12);
      expect(club.isMember, isTrue);
    });

    test('treats a null isMember as false (BOOL_OR over no members is NULL)', () {
      final club = Club.fromJson({
        'clubId': 1,
        'name': 'Empty Club',
        'description': null,
        'memberCount': 0,
        'isMember': null,
      });

      expect(club.isMember, isFalse);
      expect(club.description, '');
    });
  });

  group('Club.toggledMembership', () {
    const club = Club(clubId: 1, name: 'A', description: '', memberCount: 4, isMember: false);

    test('joining adds one member', () {
      final joined = club.toggledMembership();
      expect(joined.isMember, isTrue);
      expect(joined.memberCount, 5);
    });

    test('leaving removes one member and toggling twice is a no-op', () {
      expect(club.toggledMembership().toggledMembership().memberCount, 4);
      expect(club.toggledMembership().toggledMembership().isMember, isFalse);
    });

    test('the member count never goes below zero', () {
      const odd = Club(clubId: 1, name: 'A', description: '', memberCount: 0, isMember: true);
      expect(odd.toggledMembership().memberCount, 0);
    });

    test('other fields are unchanged', () {
      final joined = club.toggledMembership();
      expect(joined.clubId, 1);
      expect(joined.name, 'A');
    });
  });
}
