import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/core_providers.dart';
import '../../core/theme/campus_companion_theme.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/campus_card_tile.dart';
import '../auth/session_controller.dart';
import 'create_quiz_screen.dart';
import 'import_past_paper_screen.dart';
import 'quiz_taking_screen.dart';
import 'quizzes_providers.dart';

/// Body content for the "Quizzes" tab in resources_screen.dart — course
/// picker at the top, then that course's quiz list below. Not its own
/// Scaffold since it's embedded inside Resources' existing AppBar/TabBar.
class QuizzesTab extends ConsumerStatefulWidget {
  const QuizzesTab({super.key});

  @override
  ConsumerState<QuizzesTab> createState() => _QuizzesTabState();
}

class _QuizzesTabState extends ConsumerState<QuizzesTab> {
  int? _selectedCourseId;

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(coursesProvider);
    final campus = Theme.of(context).campusTheme;
    final canCreateQuizzes = ref.watch(sessionControllerProvider).valueOrNull?.canCreateQuizzes ?? false;

    return AsyncValueView(
      value: coursesAsync,
      onRetry: () => ref.invalidate(coursesProvider),
      data: (context, courses) {
        if (courses.isEmpty) {
          return const Center(child: Text('No courses available yet.'));
        }

        _selectedCourseId ??= courses.first.courseId;
        final course = courses.firstWhere((c) => c.courseId == _selectedCourseId);
        final quizzesAsync = ref.watch(quizzesForCourseProvider(course.courseId));

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: DropdownButtonFormField<int>(
                initialValue: course.courseId,
                // Long course names are cut short instead of overflowing.
                isExpanded: true,
                decoration: campus.inputDecoration(label: 'Course', icon: Icons.menu_book_outlined),
                items: [
                  for (final c in courses) DropdownMenuItem(value: c.courseId, child: Text(c.label, maxLines: 1, overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (value) => setState(() => _selectedCourseId = value),
              ),
            ),
            if (canCreateQuizzes)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final created = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(builder: (_) => CreateQuizScreen(course: course)),
                          );
                          if (created == true) ref.invalidate(quizzesForCourseProvider(course.courseId));
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Create Quiz'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final created = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(builder: (_) => ImportPastPaperScreen(course: course)),
                          );
                          if (created == true) ref.invalidate(quizzesForCourseProvider(course.courseId));
                        },
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                        label: const Text('Import PDF'),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: AsyncValueView(
                value: quizzesAsync,
                onRetry: () => ref.invalidate(quizzesForCourseProvider(course.courseId)),
                data: (context, quizzes) {
                  if (quizzes.isEmpty) {
                    return Center(
                      child: Text('No quizzes yet for ${course.courseCode}.', style: TextStyle(color: campus.textMuted)),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: quizzes.length,
                    itemBuilder: (context, index) {
                      final quiz = quizzes[index];
                      return CampusCardTile(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: campus.cardDecoration(),
                        radius: campus.cardRadius,
                        child: ListTile(
                          leading: Icon(
                            quiz.source == 'past_paper' ? Icons.picture_as_pdf_outlined : Icons.quiz_outlined,
                            color: campus.accentGlow,
                          ),
                          title: Text(quiz.title),
                          subtitle: Text('${quiz.questionCount} question(s)'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => QuizTakingScreen(quizId: quiz.quizId)),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
