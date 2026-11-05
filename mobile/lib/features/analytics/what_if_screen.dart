import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/campus_companion_theme.dart';
import '../../data/logic/academic_engine.dart';
import '../../data/models/course_grade.dart';
import '../../data/models/institution_profile.dart';
import '../../widgets/async_value_view.dart';
import '../onboarding/institution_controller.dart';
import '../timetable/timetable_providers.dart';
import 'analytics_providers.dart';

/// A mark inside each letter's band on a 4.0 scale (UG: A is 80-100, and so
/// on), so a "what if I get a B+" course counts exactly as a B+ would.
const whatIfLetterMarks = <String, double>{
  'A': 85, 'B+': 77, 'B': 72, 'C+': 67, 'C': 62, 'D+': 57, 'D': 52, 'E': 47, 'F': 30,
};

/// One course the student expects to take, with the grade they expect.
class WhatIfCourse {
  WhatIfCourse({required this.code, this.credits = 3, this.letter = 'B'});
  String code;
  int credits;
  String letter;
}

/// What the grades would be with [planned] added to [current] (pure; tested).
AcademicMetricResult projectWithPlanned(List<CourseGrade> current, List<WhatIfCourse> planned, InstitutionProfile institution) {
  var id = -1;
  final extra = [
    for (final c in planned)
      if (c.code.trim().isNotEmpty)
        CourseGrade(
          gradeId: id--,
          courseCode: c.code.trim().toUpperCase(),
          courseTitle: c.code.trim(),
          creditHours: c.credits,
          score: whatIfLetterMarks[c.letter]!,
          letterGrade: c.letter,
          semester: 'Planned',
          passed: c.letter != 'F',
        ),
  ];
  return AcademicEngine.calculate([...current, ...extra], institution);
}

/// "What if?": enter expected grades for coming courses and see the CGPA,
/// FGPA and class they would give. Nothing is saved or sent anywhere.
class WhatIfScreen extends ConsumerStatefulWidget {
  const WhatIfScreen({super.key});

  @override
  ConsumerState<WhatIfScreen> createState() => _WhatIfScreenState();
}

class _WhatIfScreenState extends ConsumerState<WhatIfScreen> {
  List<WhatIfCourse>? _planned;

  /// Starts from the timetable's courses that have no grade yet.
  List<WhatIfCourse> _initial(List<CourseGrade> grades) {
    final graded = grades.map((g) => g.courseCode).toSet();
    final codes = <String>{
      for (final entry in ref.read(timetableControllerProvider))
        if (!graded.contains(entry.courseCode)) entry.courseCode,
    };
    return codes.isEmpty ? [WhatIfCourse(code: '')] : [for (final code in codes) WhatIfCourse(code: code)];
  }

  @override
  Widget build(BuildContext context) {
    final grades = ref.watch(gradesProvider);
    final institution = ref.watch(institutionControllerProvider);
    final campus = Theme.of(context).campusTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('What if?')),
      body: AsyncValueView<List<CourseGrade>>(
        value: grades,
        onRetry: () => ref.invalidate(gradesProvider),
        data: (context, current) {
          final planned = _planned ??= _initial(current);
          final now = AcademicEngine.calculate(current, institution);
          final after = projectWithPlanned(current, planned, institution);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Pick the grade you expect in each course. The course number sets its level (DCIT 418 is Level 400, '
                'which counts double in the FGPA). Nothing here is saved.',
                style: TextStyle(color: campus.textMuted),
              ),
              const SizedBox(height: 12),
              _ResultCard(now: now, after: after),
              const SizedBox(height: 16),
              for (var i = 0; i < planned.length; i++)
                _CourseRow(
                  key: ObjectKey(planned[i]),
                  course: planned[i],
                  onChanged: () => setState(() {}),
                  onRemove: () => setState(() => planned.removeAt(i)),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(() => planned.add(WhatIfCourse(code: ''))),
                  icon: const Icon(Icons.add),
                  label: const Text('Add a course'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.now, required this.after});
  final AcademicMetricResult now;
  final AcademicMetricResult after;

  @override
  Widget build(BuildContext context) {
    final campus = Theme.of(context).campusTheme;
    Widget column(String heading, AcademicMetricResult m) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(heading, style: TextStyle(color: campus.textMuted, fontSize: 12)),
              const SizedBox(height: 4),
              Text('CGPA ${m.scoreValue.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleMedium),
              if (m.fgpa != null) Text('FGPA ${m.fgpa!.toStringAsFixed(2)}'),
              const SizedBox(height: 4),
              Text(m.honoursClass, style: TextStyle(color: m.honoursColor, fontWeight: FontWeight.w700)),
            ],
          ),
        );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: campus.cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          column('Now', now),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 16), child: Icon(Icons.arrow_forward)),
          column('With these grades', after),
        ],
      ),
    );
  }
}

class _CourseRow extends StatelessWidget {
  const _CourseRow({super.key, required this.course, required this.onChanged, required this.onRemove});
  final WhatIfCourse course;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: TextFormField(
              initialValue: course.code,
              decoration: const InputDecoration(labelText: 'Course', hintText: 'DCIT 418', isDense: true),
              textCapitalization: TextCapitalization.characters,
              onChanged: (v) {
                course.code = v;
                onChanged();
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<int>(
              initialValue: course.credits,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Credits', isDense: true),
              items: [for (final c in [1, 2, 3, 4, 6]) DropdownMenuItem(value: c, child: Text('$c'))],
              onChanged: (v) {
                course.credits = v ?? 3;
                onChanged();
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<String>(
              initialValue: course.letter,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Grade', isDense: true),
              items: [for (final l in whatIfLetterMarks.keys) DropdownMenuItem(value: l, child: Text(l))],
              onChanged: (v) {
                course.letter = v ?? 'B';
                onChanged();
              },
            ),
          ),
          IconButton(tooltip: 'Remove', icon: const Icon(Icons.close), onPressed: onRemove),
        ],
      ),
    );
  }
}
