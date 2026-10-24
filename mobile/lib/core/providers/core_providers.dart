import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';
import '../services/google_auth_service.dart';
import '../services/notification_service.dart';
import '../storage/local_prefs.dart';
import '../storage/token_storage.dart';
import '../../data/api/admin_api.dart';
import '../../data/api/announcement_api.dart';
import '../../data/api/auth_api.dart';
import '../../data/api/club_api.dart';
import '../../data/api/course_api.dart';
import '../../data/api/dashboard_api.dart';
import '../../data/api/device_api.dart';
import '../../data/api/event_api.dart';
import '../../data/api/grade_api.dart';
import '../../data/api/location_api.dart';
import '../../data/api/quiz_api.dart';
import '../../data/api/schedule_api.dart';
import '../../data/models/course.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/exams_repository.dart';
import '../../data/repositories/local_schedule_repository.dart';
import '../../features/auth/session_controller.dart';

/// Overridden in main() once the async singletons (SharedPreferences) are ready.
final localPrefsProvider = Provider<LocalPrefs>((ref) {
  throw UnimplementedError('localPrefsProvider must be overridden in main()');
});

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    ref.watch(tokenStorageProvider),
    onSessionExpired: () {
      ref.read(sessionExpiredProvider.notifier).state = true;
      ref.invalidate(sessionControllerProvider);
    },
  );
});

final authApiProvider = Provider<AuthApi>((ref) => AuthApi(ref.watch(apiClientProvider)));
final courseApiProvider = Provider<CourseApi>((ref) => CourseApi(ref.watch(apiClientProvider)));
final dashboardApiProvider =
    Provider<DashboardApi>((ref) => DashboardApi(ref.watch(apiClientProvider)));
final scheduleApiProvider = Provider<ScheduleApi>((ref) => ScheduleApi(ref.watch(apiClientProvider)));
final announcementApiProvider =
    Provider<AnnouncementApi>((ref) => AnnouncementApi(ref.watch(apiClientProvider)));
final locationApiProvider = Provider<LocationApi>((ref) => LocationApi(ref.watch(apiClientProvider)));
final eventApiProvider = Provider<EventApi>((ref) => EventApi(ref.watch(apiClientProvider)));
final clubApiProvider = Provider<ClubApi>((ref) => ClubApi(ref.watch(apiClientProvider)));
final adminApiProvider = Provider<AdminApi>((ref) => AdminApi(ref.watch(apiClientProvider)));
final deviceApiProvider = Provider<DeviceApi>((ref) => DeviceApi(ref.watch(apiClientProvider)));
final gradeApiProvider = Provider<GradeApi>((ref) => GradeApi(ref.watch(apiClientProvider)));
final quizApiProvider = Provider<QuizApi>((ref) => QuizApi(ref.watch(apiClientProvider)));

/// Shared course list — used by both the Quizzes and AI Tutor course pickers.
final coursesProvider = FutureProvider<List<Course>>((ref) => ref.watch(courseApiProvider).fetch());

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.watch(authApiProvider),
    ref.watch(tokenStorageProvider),
    googleAuth: ref.watch(googleAuthServiceProvider),
  ),
);

/// The Google sign-in transport. NoopGoogleAuthService until main() swaps in
/// the real one (see google_auth_bootstrap.dart) — mirrors pushMessagingProvider.
final googleAuthServiceProvider = Provider<GoogleAuthService>((ref) => const NoopGoogleAuthService());

final examsRepositoryProvider =
    Provider<ExamsRepository>((ref) => ExamsRepository(ref.watch(localPrefsProvider)));

final localScheduleRepositoryProvider =
    Provider<LocalScheduleRepository>((ref) => LocalScheduleRepository(ref.watch(localPrefsProvider)));

final notificationServiceProvider = Provider<NotificationService>((ref) => NotificationService());
