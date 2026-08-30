import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_root.dart';
import 'core/providers/core_providers.dart';
import 'core/storage/local_prefs.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final localPrefs = await LocalPrefs.create();

  runApp(
    ProviderScope(
      overrides: [
        localPrefsProvider.overrideWithValue(localPrefs),
      ],
      child: const AppRoot(),
    ),
  );
}
