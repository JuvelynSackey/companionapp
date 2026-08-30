import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../data/models/app_user.dart';
import '../../data/models/institution_profile.dart';
import '../../data/models/local_student_profile.dart';
import '../../data/models/student_identity.dart';
import '../auth/session_controller.dart';
import '../onboarding/institution_controller.dart';
import 'widgets/flippable_id_card.dart';

/// Pure presentation — no new backend or persistence, matches the source
/// app's Digital Student ID (a Student Hub sub-tab we haven't built the
/// rest of yet). Reads the signed-in user + selected institution branding,
/// plus the local-only cosmetic profile (role/level/programme) from
/// onboarding, if the student filled it in.
class DigitalIdScreen extends ConsumerWidget {
  const DigitalIdScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionControllerProvider).valueOrNull;
    final institution = ref.watch(institutionControllerProvider);
    final localProfile = ref.watch(localProfileControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Digital Student ID')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: user == null
                ? const Text('Sign in to view your student ID.')
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FlippableIdCard(
                        front: _IdCard(
                          user: user,
                          institution: institution,
                          localProfile: localProfile,
                          studentId: displayStudentId(user.userId, institution, localProfile),
                        ),
                        back: _IdCardBack(
                          institution: institution,
                          studentId: displayStudentId(user.userId, institution, localProfile),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Tap the card to flip',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _IdCard extends StatelessWidget {
  const _IdCard({required this.user, required this.institution, required this.localProfile, required this.studentId});

  final AppUser user;
  final InstitutionProfile institution;
  final LocalStudentProfile localProfile;
  final String studentId;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [institution.primaryColor, institution.secondaryColor],
        ),
        boxShadow: [
          BoxShadow(color: institution.primaryColor.withValues(alpha: 0.4), blurRadius: 24, offset: const Offset(0, 12)),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white,
                child: Text(
                  institution.shortCode.substring(0, institution.shortCode.length.clamp(0, 2)),
                  style: TextStyle(color: institution.primaryColor, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  institution.name,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: QrImageView(
              data: 'CAMPUSCOMPANION|${institution.id}|${user.userId}|${user.email}',
              size: 140,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Text(user.fullName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
          const SizedBox(height: 4),
          Text(user.email, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _CardStat(label: 'STUDENT ID', value: studentId),
              _CardStat(
                label: 'ROLE',
                value: localProfile.role == StudentRole.lecturer ? 'LECTURER' : 'STUDENT',
              ),
            ],
          ),
          if (localProfile.academicLevel.isNotEmpty || localProfile.programme.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (localProfile.academicLevel.isNotEmpty) _CardStat(label: 'LEVEL', value: localProfile.academicLevel),
                if (localProfile.programme.isNotEmpty)
                  Flexible(child: _CardStat(label: 'PROGRAMME', value: localProfile.programme)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// No fabricated emergency phone number here — a made-up "campus security"
/// number presented as if real could genuinely mislead someone in an
/// actual emergency, so this points to the institution's own security
/// office generically instead of inventing a digit string.
class _IdCardBack extends StatelessWidget {
  const _IdCardBack({required this.institution, required this.studentId});
  final InstitutionProfile institution;
  final String studentId;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: institution.secondaryColor,
        boxShadow: [
          BoxShadow(color: institution.secondaryColor.withValues(alpha: 0.4), blurRadius: 24, offset: const Offset(0, 12)),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('ACADEMIC INTEGRITY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
          const SizedBox(height: 6),
          Text(
            'This card certifies that the holder is a member of the ${institution.name} community and agrees to uphold its code of academic honesty and conduct.',
            style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 16),
          const Text('IN AN EMERGENCY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
          const SizedBox(height: 6),
          const Text(
            "Contact your institution's campus security or help desk directly — this app does not have a verified emergency contact number on file.",
            style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 24),
          Center(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
              child: SizedBox(
                height: 48,
                width: double.infinity,
                child: CustomPaint(painter: BarcodePainter(seed: studentId)),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(child: Text(studentId, style: const TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 2))),
        ],
      ),
    );
  }
}

class _CardStat extends StatelessWidget {
  const _CardStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10, letterSpacing: 1)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}
