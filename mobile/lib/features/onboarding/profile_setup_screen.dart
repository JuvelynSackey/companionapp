import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/campus_companion_theme.dart';
import '../../data/models/local_student_profile.dart';
import 'institution_controller.dart';

/// Step 2 of onboarding — local-only cosmetic details (see
/// LocalStudentProfile). Entirely skippable since none of it is required
/// for the app to function; it only personalizes the Digital ID card.
class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  StudentRole _role = StudentRole.student;
  final _studentIdController = TextEditingController();
  final _levelController = TextEditingController();
  final _programmeController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _studentIdController.dispose();
    _levelController.dispose();
    _programmeController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    await ref.read(localProfileControllerProvider.notifier).save(LocalStudentProfile(
          role: _role,
          studentId: _studentIdController.text.trim(),
          academicLevel: _levelController.text.trim(),
          programme: _programmeController.text.trim(),
        ));
    await ref.read(onboardingControllerProvider.notifier).complete();
    _backToRoot();
  }

  /// _RootGate (the first route) has now rebuilt past onboarding. The picker
  /// and this screen are both pushed routes above it (Welcome pushes the
  /// picker, the picker pushes this), so clear both, not just this one.
  void _backToRoot() {
    if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _skip() async {
    await ref.read(onboardingControllerProvider.notifier).complete();
    _backToRoot();
  }

  @override
  Widget build(BuildContext context) {
    final campus = Theme.of(context).campusTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'STEP 2 OF 2',
                style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 1.1),
              ),
              const SizedBox(height: 6),
              Text('Your profile', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'Optional — personalizes your Digital ID card. Stored on this device only, never sent anywhere.',
                style: TextStyle(color: campus.textMuted),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: campus.cardDecoration(),
                child: SegmentedButton<StudentRole>(
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: campus.accentGlow,
                    selectedForegroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(campus.innerRadius)),
                  ),
                  segments: const [
                    ButtonSegment(value: StudentRole.student, label: Text('Student'), icon: Icon(Icons.school_outlined)),
                    ButtonSegment(value: StudentRole.lecturer, label: Text('Lecturer'), icon: Icon(Icons.person_outline)),
                  ],
                  selected: {_role},
                  onSelectionChanged: (s) => setState(() => _role = s.first),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _studentIdController,
                decoration: campus.inputDecoration(label: 'Student/Staff ID (optional)'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _levelController,
                decoration: campus.inputDecoration(label: 'Academic Level (optional, e.g. Level 300)'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _programmeController,
                decoration: campus.inputDecoration(label: 'Programme (optional, e.g. BSc. Computer Science)'),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _saving ? null : _skip,
                      child: const Text('Skip'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      style: campus.primaryButtonStyle,
                      onPressed: _saving ? null : _finish,
                      child: _saving
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Get Started'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
