import 'package:mobile/core/storage/local_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// LocalPrefs over an in-memory SharedPreferences, for containers whose code
/// reads or writes device-local state (the saved guest flag, for one).
Future<LocalPrefs> testLocalPrefs([Map<String, Object> values = const {}]) {
  SharedPreferences.setMockInitialValues(values);
  return LocalPrefs.create();
}
