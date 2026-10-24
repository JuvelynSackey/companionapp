import 'package:flutter/material.dart';
import '../../core/theme/landing_theme.dart';
import '../onboarding/institution_picker_screen.dart';
import 'widgets/social_auth_buttons.dart';

/// The very first screen the app shows, before onboarding or sign-in —
/// styled after the reference design (illustration, headline, Google/Apple/
/// Guest row). "Get Started" and "Already have an account? Log in" both lead
/// into the existing onboarding flow (InstitutionPickerScreen) first: this
/// app's institution/branding choice is local to the device, not the
/// account, so even a returning user on a new device still needs to make it
/// once — see PROJECT_AUDIT.md.
///
/// Signing in with Google directly from here (via SocialAuthButtons) does
/// skip ahead: AppRoot's gate checks onboarding before session state, so a
/// successful sign-in still lands on the institution picker next, and only
/// after that does the already-authenticated session carry straight into the
/// app, bypassing the sign-in form entirely. No navigation changes were
/// needed for that to work — it falls out of the existing gate order.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(),
                    const _HeroIllustration(),
                    const SizedBox(height: 32),
                    Text(
                      'Campus Companion',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: LandingColors.ink,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your timetable, exams, grades and campus life, all in one place.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: LandingColors.inkMuted, fontSize: 15, height: 1.4),
                    ),
                    const SizedBox(height: 32),
                    FilledButton(
                      style: LandingStyle.primaryButtonStyle,
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const InstitutionPickerScreen()),
                      ),
                      child: const Text('Get Started'),
                    ),
                    const SizedBox(height: 16),
                    Row(children: const [
                      Expanded(child: Divider(color: LandingColors.border)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('or', style: TextStyle(color: LandingColors.inkMuted)),
                      ),
                      Expanded(child: Divider(color: LandingColors.border)),
                    ]),
                    const SizedBox(height: 16),
                    const SocialAuthButtons(),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const InstitutionPickerScreen()),
                      ),
                      child: RichText(
                        text: const TextSpan(
                          style: TextStyle(color: LandingColors.inkMuted, fontSize: 14),
                          children: [
                            TextSpan(text: 'Already have an account? '),
                            TextSpan(
                              text: 'Log in',
                              style: TextStyle(color: LandingColors.green700, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A simple original illustration (no third-party art assets) in the spirit
/// of the reference design: a student at a laptop, soft green blob behind.
/// Kept to plain shapes/icons so there is nothing to license or attribute.
class _HeroIllustration extends StatelessWidget {
  const _HeroIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 200,
            width: 200,
            decoration: const BoxDecoration(color: LandingColors.green100, shape: BoxShape.circle),
          ),
          Positioned(
            bottom: 36,
            child: Icon(Icons.school_rounded, size: 56, color: LandingColors.green500),
          ),
          Positioned(
            bottom: 16,
            child: Container(
              width: 140,
              height: 14,
              decoration: BoxDecoration(
                color: LandingColors.green700,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const Positioned(
            top: 8,
            right: 40,
            child: _FloatingChip(icon: Icons.calendar_today_rounded),
          ),
          const Positioned(
            top: 28,
            left: 32,
            child: _FloatingChip(icon: Icons.insights_rounded),
          ),
        ],
      ),
    );
  }
}

class _FloatingChip extends StatelessWidget {
  const _FloatingChip({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Icon(icon, size: 18, color: LandingColors.green700),
    );
  }
}
