import 'package:mobile/data/api/club_api.dart';
import 'package:mobile/data/api/event_api.dart';
import 'package:mobile/data/models/campus_event.dart';
import 'package:mobile/data/models/club.dart';

/// Shared fakes for the Clubs tests.

class FakeClubApi implements ClubApi {
  FakeClubApi(this.clubs);

  List<Club> clubs;
  int fetchCount = 0;
  final joined = <int>[];
  final left = <int>[];
  Future<void> Function(int clubId)? onJoin;
  Future<void> Function(int clubId)? onLeave;

  @override
  Future<List<Club>> fetch() async {
    fetchCount++;
    return clubs;
  }

  @override
  Future<void> join(int clubId) async {
    joined.add(clubId);
    await onJoin?.call(clubId);
  }

  @override
  Future<void> leave(int clubId) async {
    left.add(clubId);
    await onLeave?.call(clubId);
  }
}

class FakeEventApi implements EventApi {
  FakeEventApi(this.events);
  final List<CampusEvent> events;

  @override
  Future<List<CampusEvent>> fetch({bool upcoming = true}) async => events;

  @override
  Future<int> create({
    required String title,
    required String description,
    required DateTime eventDate,
    String? location,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> register(int eventId) => throw UnimplementedError();

  @override
  Future<void> cancelRegistration(int eventId) => throw UnimplementedError();
}

const cs = Club(clubId: 1, name: 'Computer Science Society', description: 'Hackathons and study groups.', memberCount: 3, isMember: false);
const debate = Club(clubId: 2, name: 'Debate Union', description: 'Weekly debates.', memberCount: 5, isMember: true);
const photo = Club(clubId: 3, name: 'Photography Club', description: 'Photo walks.', memberCount: 1, isMember: false);
