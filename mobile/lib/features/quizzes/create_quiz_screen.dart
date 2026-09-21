import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/campus_companion_theme.dart';
import '../../data/models/course.dart';
import '../../data/models/quiz_models.dart';
import 'question_editor.dart';
import 'quizzes_providers.dart';

/// Manual quiz authoring for a pre-selected course (lecturer/admin only —
/// gated by AppUser.canCreateQuizzes at the call site). Also the landing
/// screen for a past-paper-derived draft: import_past_paper_screen.dart
/// pushes here with `initialQuestions` pre-filled from AI extraction, so
/// review/editing happens on the exact same form as manual authoring.
class CreateQuizScreen extends ConsumerStatefulWidget {
  const CreateQuizScreen({
    super.key,
    required this.course,
    this.initialTitle,
    this.initialQuestions,
    this.source = 'manual',
  });

  final Course course;
  final String? initialTitle;
  final List<QuizQuestionDraft>? initialQuestions;
  final String source;

  @override
  ConsumerState<CreateQuizScreen> createState() => _CreateQuizScreenState();
}

class _CreateQuizScreenState extends ConsumerState<CreateQuizScreen> {
  late final _titleController = TextEditingController(text: widget.initialTitle ?? '');
  late final _questionsController = QuestionEditorController(widget.initialQuestions ?? []);
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _questionsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final questions = _questionsController.value;

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a quiz title')));
      return;
    }
    if (questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add at least one question')));
      return;
    }
    for (final q in questions) {
      if (q.questionText.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Every question needs text')));
        return;
      }
    }

    setState(() => _isSaving = true);
    try {
      await ref.read(quizActionsControllerProvider.notifier).createQuiz(
            courseId: widget.course.courseId,
            title: title,
            source: widget.source,
            questions: questions,
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save quiz: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final campus = Theme.of(context).campusTheme;
    return Scaffold(
      appBar: AppBar(
        title: Text('New Quiz · ${widget.course.courseCode}'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: _isSaving
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : TextButton(onPressed: _save, child: const Text('Save')),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _titleController,
            decoration: campus.inputDecoration(label: 'Quiz title'),
          ),
          const SizedBox(height: 16),
          QuestionEditorList(controller: _questionsController),
        ],
      ),
    );
  }
}
