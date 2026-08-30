import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppTab { dashboard, timetable, exams, alerts, resources }

final selectedTabProvider = StateProvider<AppTab>((ref) => AppTab.dashboard);
