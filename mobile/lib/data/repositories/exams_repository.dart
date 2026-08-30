import 'dart:math';
import '../../core/storage/local_prefs.dart';
import '../models/exam.dart';

/// Local-only CRUD — no backend endpoint exists for exams.
class ExamsRepository {
  ExamsRepository(this._prefs);
  final LocalPrefs _prefs;
  final _random = Random();

  List<Exam> getAll() => _prefs.exams;

  Future<List<Exam>> add(Exam exam) async {
    final id = exam.id.isNotEmpty
        ? exam.id
        : 'exam_${DateTime.now().microsecondsSinceEpoch}_${_random.nextInt(9999)}';
    final withId = Exam(
      id: id,
      courseCode: exam.courseCode,
      courseTitle: exam.courseTitle,
      examDate: exam.examDate,
      startTime: exam.startTime,
      endTime: exam.endTime,
      venue: exam.venue,
      seatRange: exam.seatRange,
      invigilator: exam.invigilator,
      walkingTimeMinutes: exam.walkingTimeMinutes,
      rules: exam.rules,
    );
    final all = [..._prefs.exams, withId];
    await _prefs.saveExams(all);
    return all;
  }

  Future<List<Exam>> update(Exam exam) async {
    final all = _prefs.exams.map((e) => e.id == exam.id ? exam : e).toList();
    await _prefs.saveExams(all);
    return all;
  }

  Future<List<Exam>> delete(String id) async {
    final all = _prefs.exams.where((e) => e.id != id).toList();
    await _prefs.saveExams(all);
    return all;
  }
}
