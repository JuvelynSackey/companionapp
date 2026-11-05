import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../assistant/gemini_assistant_service.dart';
import '../../core/providers/core_providers.dart';
import '../../core/theme/campus_companion_theme.dart';
import '../../widgets/async_value_view.dart';
import '../assistant/widgets/chat_view.dart';
import 'tutor_controller.dart';

const _quickSuggestions = [
  'Explain a concept in this course',
  'Give me practice questions',
];

const _slideSuggestions = [
  'Summarise these slides',
  'Quiz me on these slides',
  'Explain the hardest part of these slides',
];

/// Gemini takes at most about 20 MB per request, and the file grows by a
/// third when encoded, so slides are capped well below that.
const _maxSlidesBytes = 12 * 1024 * 1024;

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
                  isExpanded: true,
                  decoration: campus.inputDecoration(label: 'Course', icon: Icons.menu_book_outlined),
                  items: [
                    for (final course in courses)
                      DropdownMenuItem(value: course.courseId, child: Text(course.label, maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (value) => setState(() => _selectedCourseId = value),
                ),
              ),
              _SlidesBar(courseId: courseId),
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
    final hasSlides = ref.watch(tutorSlidesProvider(courseId)) != null;

    return ChatView(
      key: ValueKey('tutor_chat_$courseId'),
      messages: messages,
      isSending: isSending,
      quickSuggestions: hasSlides ? _slideSuggestions : _quickSuggestions,
      emptyStateText: 'Ask the AI Tutor to explain a concept or generate practice questions for this course.',
      inputHint: 'Ask about this course...',
      onSend: (text) => ref.read(tutorControllerProvider(courseId).notifier).sendMessage(text),
    );
  }
}

/// Attach (or remove) lecture slides for the selected course. PDF only:
/// export PowerPoint slides with File > Save As > PDF first.
class _SlidesBar extends ConsumerWidget {
  const _SlidesBar({required this.courseId});
  final int courseId;

  Future<void> _pick(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final files = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (files.isEmpty) return;
    final file = files.first;
    final bytes = await file.readAsBytes();
    if (bytes.length > _maxSlidesBytes) {
      messenger.showSnackBar(const SnackBar(content: Text('Those slides are over 12 MB. Try a smaller PDF, or split it.')));
      return;
    }
    ref.read(tutorSlidesProvider(courseId).notifier).state =
        GeminiAttachment(name: file.name, mimeType: 'application/pdf', bytes: bytes);
    messenger.showSnackBar(SnackBar(content: Text('Slides attached: ${file.name}. Ask anything about them.')));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slides = ref.watch(tutorSlidesProvider(courseId));
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: slides == null
            ? OutlinedButton.icon(
                onPressed: () => _pick(context, ref),
                icon: const Icon(Icons.upload_file),
                label: const Text('Attach lecture slides (PDF)'),
              )
            : InputChip(
                avatar: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                label: Text(slides.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                tooltip: 'Remove these slides',
                onDeleted: () => ref.read(tutorSlidesProvider(courseId).notifier).state = null,
              ),
      ),
    );
  }
}
