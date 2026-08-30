import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/core_providers.dart';
import '../../data/models/exam.dart';

class ExamsController extends Notifier<List<Exam>> {
  @override
  List<Exam> build() => ref.watch(examsRepositoryProvider).getAll();

  Future<void> add(Exam exam) async {
    state = await ref.read(examsRepositoryProvider).add(exam);
  }

  Future<void> update(Exam exam) async {
    state = await ref.read(examsRepositoryProvider).update(exam);
  }

  Future<void> delete(String id) async {
    state = await ref.read(examsRepositoryProvider).delete(id);
  }
}

final examsControllerProvider = NotifierProvider<ExamsController, List<Exam>>(ExamsController.new);
