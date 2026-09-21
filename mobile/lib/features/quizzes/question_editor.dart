import 'package:flutter/material.dart';
import '../../data/models/quiz_models.dart';

/// Owns the current draft question list — the parent screen (manual
/// authoring or the past-paper-import review step) reads .value when
/// ready to submit.
class QuestionEditorController extends ValueNotifier<List<QuizQuestionDraft>> {
  QuestionEditorController([List<QuizQuestionDraft>? initial]) : super(initial ?? []);

  void add() {
    value = [
      ...value,
      QuizQuestionDraft(
        questionType: QuestionType.multipleChoice,
        questionText: '',
        options: const ['', ''],
        correctOption: 0,
      ),
    ];
  }

  void removeAt(int index) {
    final updated = [...value]..removeAt(index);
    value = updated;
  }

  void updateAt(int index, QuizQuestionDraft draft) {
    final updated = [...value];
    updated[index] = draft;
    value = updated;
  }
}

/// Shared question-authoring UI: used both for manually creating a quiz
/// from scratch and for reviewing/editing an AI-extracted draft from a
/// past-paper PDF before publishing — the same editing surface either way,
/// so a curated past-paper quiz is held to the same scrutiny as one an
/// admin typed by hand.
class QuestionEditorList extends StatelessWidget {
  const QuestionEditorList({super.key, required this.controller});
  final QuestionEditorController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final questions = controller.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < questions.length; i++)
              _QuestionCard(
                key: ValueKey(questions[i].id),
                index: i,
                draft: questions[i],
                onChanged: (draft) => controller.updateAt(i, draft),
                onRemove: () => controller.removeAt(i),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: controller.add,
              icon: const Icon(Icons.add),
              label: const Text('Add Question'),
            ),
          ],
        );
      },
    );
  }
}

class _QuestionCard extends StatefulWidget {
  const _QuestionCard({
    super.key,
    required this.index,
    required this.draft,
    required this.onChanged,
    required this.onRemove,
  });

  final int index;
  final QuizQuestionDraft draft;
  final void Function(QuizQuestionDraft) onChanged;
  final VoidCallback onRemove;

  @override
  State<_QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<_QuestionCard> {
  late final _textController = TextEditingController(text: widget.draft.questionText);
  late final _modelAnswerController = TextEditingController(text: widget.draft.modelAnswer ?? '');
  late List<TextEditingController> _optionControllers;

  @override
  void initState() {
    super.initState();
    _optionControllers = (widget.draft.options ?? const ['', '']).map((o) => TextEditingController(text: o)).toList();
  }

  @override
  void dispose() {
    _textController.dispose();
    _modelAnswerController.dispose();
    for (final controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _emit() {
    widget.onChanged(widget.draft.copyWith(
      questionText: _textController.text,
      options: widget.draft.questionType == QuestionType.multipleChoice
          ? _optionControllers.map((c) => c.text).toList()
          : null,
      modelAnswer: _modelAnswerController.text.isEmpty ? null : _modelAnswerController.text,
    ));
  }

  /// Constructs a fresh draft rather than using copyWith (which can't null
  /// out fields) — switching types must actually clear the shape that
  /// doesn't apply to the new type (e.g. MCQ options when going open_ended).
  void _setType(QuestionType type) {
    widget.onChanged(QuizQuestionDraft(
      id: widget.draft.id,
      questionType: type,
      questionText: _textController.text,
      options: type == QuestionType.multipleChoice ? _optionControllers.map((c) => c.text).toList() : null,
      correctOption: type == QuestionType.multipleChoice ? 0 : null,
      modelAnswer: _modelAnswerController.text.isEmpty ? null : _modelAnswerController.text,
    ));
  }

  void _addOption() {
    setState(() => _optionControllers.add(TextEditingController()));
    _emit();
  }

  void _removeOption(int index) {
    setState(() {
      _optionControllers[index].dispose();
      _optionControllers.removeAt(index);
    });
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    final isMcq = widget.draft.questionType == QuestionType.multipleChoice;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text('Question ${widget.index + 1}', style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                IconButton(icon: const Icon(Icons.delete_outline), onPressed: widget.onRemove),
              ],
            ),
            SegmentedButton<QuestionType>(
              segments: const [
                ButtonSegment(value: QuestionType.multipleChoice, label: Text('Multiple Choice')),
                ButtonSegment(value: QuestionType.openEnded, label: Text('Open Ended')),
              ],
              selected: {widget.draft.questionType},
              onSelectionChanged: (selection) => _setType(selection.first),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _textController,
              decoration: const InputDecoration(labelText: 'Question text'),
              maxLines: 2,
              onChanged: (_) => _emit(),
            ),
            const SizedBox(height: 8),
            if (isMcq) ...[
              RadioGroup<int>(
                groupValue: widget.draft.correctOption,
                onChanged: (value) => widget.onChanged(widget.draft.copyWith(correctOption: value)),
                child: Column(
                  children: [
                    for (var i = 0; i < _optionControllers.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Radio<int>(value: i),
                            Expanded(
                              child: TextField(
                                controller: _optionControllers[i],
                                decoration: InputDecoration(labelText: 'Option ${i + 1}'),
                                onChanged: (_) => _emit(),
                              ),
                            ),
                            if (_optionControllers.length > 2)
                              IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () => _removeOption(i),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              if (_optionControllers.length < 6)
                TextButton.icon(
                  onPressed: _addOption,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add option'),
                ),
              const SizedBox(height: 4),
              TextField(
                controller: _modelAnswerController,
                decoration: const InputDecoration(labelText: 'Explanation (optional)'),
                maxLines: 2,
                onChanged: (_) => _emit(),
              ),
            ] else
              TextField(
                controller: _modelAnswerController,
                decoration: const InputDecoration(labelText: 'Model answer'),
                maxLines: 3,
                onChanged: (_) => _emit(),
              ),
          ],
        ),
      ),
    );
  }
}
