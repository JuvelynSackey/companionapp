import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/core_providers.dart';
import '../../core/theme/campus_companion_theme.dart';
import '../../widgets/async_value_view.dart';
import '../assistant/widgets/chat_view.dart';
import 'tutor_controller.dart';

const _quickSuggestions = [
  'Explain a concept in this course',
  'Give me practice questions',
];

/// Course-focused AI Tutor — distinct from the general campus AI Assistant
/// (assistant_screen.dart): a course picker up top scopes every message to
/// that course's TutorContext, so answers stay relevant to a specific
/// subject instead of general campus info.
class TutorScreen extends ConsumerStatefulWidget {
  const TutorScreen({super.key});

  @override
  ConsumerState<TutorScreen> createState() => _TutorScreenState();
}

class _TutorScreenState extends ConsumerState<TutorScreen> {
  int? _selectedCourseId;

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(coursesProvider);
    final campus = Theme.of(context).campusTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('AI Tutor')),
      body: AsyncValueView(
        value: coursesAsync,
        onRetry: () => ref.invalidate(coursesProvider),
        data: (context, courses) {
          if (courses.isEmpty) {
            return const Center(child: Text('No courses available yet.'));
          }

          _selectedCourseId ??= courses.first.courseId;
          final courseId = _selectedCourseId!;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: DropdownButtonFormField<int>(
                  initialValue: courseId,
                  decoration: campus.inputDecoration(label: 'Course', icon: Icons.menu_book_outlined),
                  items: [
                    for (final course in courses)
                      DropdownMenuItem(value: course.courseId, child: Text(course.label)),
                  ],
                  onChanged: (value) => setState(() => _selectedCourseId = value),
                ),
              ),
              Expanded(
                child: _TutorChat(courseId: courseId),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TutorChat extends ConsumerWidget {
  const _TutorChat({required this.courseId});
  final int courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(tutorControllerProvider(courseId));
    final isSending = ref.watch(tutorSendingProvider(courseId));

    return ChatView(
      key: ValueKey('tutor_chat_$courseId'),
      messages: messages,
      isSending: isSending,
      quickSuggestions: _quickSuggestions,
      emptyStateText: 'Ask the AI Tutor to explain a concept or generate practice questions for this course.',
      inputHint: 'Ask about this course...',
      onSend: (text) => ref.read(tutorControllerProvider(courseId).notifier).sendMessage(text),
    );
  }
}
