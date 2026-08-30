import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/core_providers.dart';
import '../../data/models/course_grade.dart';

final gradesProvider = FutureProvider.autoDispose<List<CourseGrade>>((ref) {
  return ref.watch(gradeApiProvider).fetch();
});
