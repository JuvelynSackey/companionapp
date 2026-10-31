import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/campus_companion_theme.dart';
import '../../data/models/institution_profile.dart';
import 'institution_controller.dart';
import 'profile_setup_screen.dart';

class InstitutionPickerScreen extends ConsumerStatefulWidget {
  const InstitutionPickerScreen({super.key});

  @override
  ConsumerState<InstitutionPickerScreen> createState() => _InstitutionPickerScreenState();
}

class _InstitutionPickerScreenState extends ConsumerState<InstitutionPickerScreen> {
  InstitutionProfile? _selected;
  bool _confirming = false;

  @override
  Widget build(BuildContext context) {
    final institutions = InstitutionRegistry.all;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'STEP 1 OF 2',
                    style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 1.1),
                  ),
                  const SizedBox(height: 6),
                  Text('Choose your institution', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text(
                    "This sets your grading scale and your institution's branding.",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: institutions.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final institution = institutions[index];
                  final isSelected = _selected?.id == institution.id;
                  final campus = Theme.of(context).campusTheme;
                  return Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: campus.cardDecoration().copyWith(
                          border: Border.all(color: isSelected ? institution.primaryColor : campus.subtleBorder, width: isSelected ? 2 : 1),
                        ),
                    child: Row(
                      children: [
                        // Brand-color swatch on the leading edge — the one
                        // place this screen still shows institution color
                        // as a strip, not the whole card.
                        Container(width: 5, height: 72, color: institution.primaryColor),
                        Expanded(
                          child: Material(
                            color: Colors.transparent,
                            child: ListTile(
                              onTap: () => setState(() => _selected = institution),
                              leading: CircleAvatar(
                                backgroundColor: institution.primaryColor,
                                child: Text(
                                  institution.shortCode.substring(0, institution.shortCode.length.clamp(0, 2)),
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(institution.name),
                              subtitle: Text('${institution.city} · ${institution.region}', style: TextStyle(color: campus.textMuted)),
                              trailing: isSelected ? Icon(Icons.check_circle, color: campus.accentGlow) : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton(
                style: Theme.of(context).campusTheme.primaryButtonStyle.copyWith(
                      minimumSize: const WidgetStatePropertyAll(Size.fromHeight(54)),
                    ),
                onPressed: _selected == null || _confirming
                    ? null
                    : () async {
                        setState(() => _confirming = true);
                        await ref.read(institutionControllerProvider.notifier).select(_selected!);
                        if (mounted) setState(() => _confirming = false);
                        if (context.mounted) {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
                          );
                        }
                      },
                child: _confirming
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
