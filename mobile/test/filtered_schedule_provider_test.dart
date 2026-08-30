import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/core/providers/core_providers.dart';
import 'package:mobile/core/storage/local_prefs.dart';
import 'package:mobile/features/timetable/timetable_providers.dart';

void main() {
  // Regression test: filteredScheduleProvider used to sort the Notifier's
  // own state list in place. When the local schedule is empty,
  // LocalPrefs.schedule returns `const []` (immutable), and sorting an
  // immutable list throws `Unsupported operation: sort` — this crashed the
  // Timetable screen on first launch, before any class was ever added.
  test('does not throw when the local schedule is empty and no day filter is selected', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await LocalPrefs.create();
    final container = ProviderContainer(overrides: [localPrefsProvider.overrideWithValue(prefs)]);
    addTearDown(container.dispose);

    expect(() => container.read(filteredScheduleProvider), returnsNormally);
    expect(container.read(filteredScheduleProvider), isEmpty);
  });
}
