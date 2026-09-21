import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/campus_companion_theme.dart';
import '../../data/models/quiz_models.dart';
import '../../widgets/async_value_view.dart';
import 'quizzes_providers.dart';

/// Takes one quiz: renders every question (radio group for multiple_choice,
/// free text for open_ended), submits all answers at once, then shows the
/// results view with the answer key the backend only reveals at this point.
class QuizTakingScreen extends ConsumerStatefulWidget {
  const QuizTakingScreen({super.key, required this.quizId});
  final int quizId;

  @override
  ConsumerState<QuizTakingScreen> createState() => _QuizTakingScreenState();
}

class _QuizTakingScreenState extends ConsumerState<QuizTakingScreen> {
  final Map<int, int> _selectedOptions = {};
  final Map<int, TextEditingController> _freeTextControllers = {};
  bool _isSubmitting = false;
  QuizAttemptResult? _result;

  TextEditingController _controllerFor(int questionId) =>
      _freeTextControllers.putIfAbsent(questionId, TextEditingController.new);

  @override
  void dispose() {
    for (final controller in _freeTextControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit(List<QuizQuestion> questions) async {
    final answers = [
      for (final q in questions)
        QuizAnswerInput(
          questionId: q.questionId,
          selectedOption: _selectedOptions[q.questionId],
          freeTextAnswer: _freeTextControllers[q.questionId]?.text,
        ),
    ];

    setState(() => _isSubmitting = true);
    try {
      final result = await ref.read(quizActionsControllerProvider.notifier).submitAttempt(widget.quizId, answers);
      setState(() => _result = result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not submit: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final quizAsync = ref.watch(quizDetailProvider(widget.quizId));

    return Scaffold(
      appBar: AppBar(title: const Text('Quiz')),
      body: AsyncValueView(
        value: quizAsync,
        onRetry: () => ref.invalidate(quizDetailProvider(widget.quizId)),
        data: (context, quiz) {
          if (_result != null) {
            return _ResultsView(quiz: quiz, result: _result!);
          }
          return _QuestionsView(
            quiz: quiz,
            selectedOptions: _selectedOptions,
            controllerFor: _controllerFor,
            onSelectOption: (questionId, option) => setState(() => _selectedOptions[questionId] = option),
            isSubmitting: _isSubmitting,
            onSubmit: () => _submit(quiz.questions),
          );
        },
      ),
    );
  }
}

class _QuestionsView extends StatelessWidget {
  const _QuestionsView({
    required this.quiz,
    required this.selectedOptions,
    required this.controllerFor,
    required this.onSelectOption,
    required this.isSubmitting,
    required this.onSubmit,
  });

  final Quiz quiz;
  final Map<int, int> selectedOptions;
  final TextEditingController Function(int questionId) controllerFor;
  final void Function(int questionId, int option) onSelectOption;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final campus = Theme.of(context).campusTheme;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(quiz.title, style: Theme.of(context).textTheme.headlineSmall),
              Text(quiz.courseCode, style: TextStyle(color: campus.textMuted)),
              const SizedBox(height: 16),
              for (var i = 0; i < quiz.questions.length; i++) _QuestionTile(
                    index: i,
                    question: quiz.questions[i],
                    selectedOption: selectedOptions[quiz.questions[i].questionId],
                    onSelectOption: (option) => onSelectOption(quiz.questions[i].questionId, option),
                    controller: quiz.questions[i].questionType == QuestionType.openEnded
                        ? controllerFor(quiz.questions[i].questionId)
                        : null,
                  ),
            ],
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: campus.primaryButtonStyle,
                onPressed: isSubmitting ? null : onSubmit,
                child: isSubmitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Submit'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _QuestionTile extends StatelessWidget {
  const _QuestionTile({
    required this.index,
    required this.question,
    required this.selectedOption,
    required this.onSelectOption,
    required this.controller,
  });

  final int index;
  final QuizQuestion question;
  final int? selectedOption;
  final void Function(int) onSelectOption;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    final campus = Theme.of(context).campusTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: campus.cardDecoration(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('${index + 1}. ${question.questionText}', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (question.questionType == QuestionType.multipleChoice)
            RadioGroup<int>(
              groupValue: selectedOption,
              onChanged: (value) {
                if (value != null) onSelectOption(value);
              },
              child: Column(
                children: [
                  for (var i = 0; i < (question.options ?? const []).length; i++)
                    RadioListTile<int>(
                      value: i,
                      title: Text(question.options![i]),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                ],
              ),
            )
          else
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: campus.inputDecoration(hint: 'Your answer'),
            ),
        ],
      ),
    );
  }
}

class _ResultsView extends StatelessWidget {
  const _ResultsView({required this.quiz, required this.result});
  final Quiz quiz;
  final QuizAttemptResult result;

  @override
  Widget build(BuildContext context) {
    final campus = Theme.of(context).campusTheme;
    final resultsByQuestionId = {for (final r in result.results) r.questionId: r};

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (result.score != null)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: campus.cardDecoration(),
            child: Column(
              children: [
                Text('${result.score!.toStringAsFixed(0)}%', style: Theme.of(context).textTheme.displaySmall),
                Text('Score on ${result.totalGraded} graded question(s)', style: TextStyle(color: campus.textMuted)),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: campus.cardDecoration(),
            child: const Text('This quiz has no auto-graded questions — review the model answers below.'),
          ),
        const SizedBox(height: 16),
        for (var i = 0; i < quiz.questions.length; i++) _ResultTile(
              index: i,
              question: quiz.questions[i],
              result: resultsByQuestionId[quiz.questions[i].questionId],
            ),
      ],
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.index, required this.question, required this.result});
  final int index;
  final QuizQuestion question;
  final QuizQuestionResult? result;

  @override
  Widget build(BuildContext context) {
    final campus = Theme.of(context).campusTheme;
    final isMcq = question.questionType == QuestionType.multipleChoice;
    final isCorrect = result?.isCorrect;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: campus.cardDecoration(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('${index + 1}. ${question.questionText}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              if (isMcq && isCorrect != null)
                Icon(isCorrect ? Icons.check_circle : Icons.cancel, color: isCorrect ? Colors.green : Theme.of(context).colorScheme.error),
            ],
          ),
          if (isMcq && result?.correctOption != null) ...[
            const SizedBox(height: 6),
            Text('Correct answer: ${question.options![result!.correctOption!]}', style: TextStyle(color: campus.textMuted)),
          ],
          if (result?.modelAnswer != null) ...[
            const SizedBox(height: 6),
            Text(isMcq ? 'Explanation: ${result!.modelAnswer}' : 'Model answer: ${result!.modelAnswer}', style: TextStyle(color: campus.textMuted)),
          ],
        ],
      ),
    );
  }
}
