import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_exception.dart';
import '../../data/models/app_user.dart';
import 'admin_providers.dart';

/// Admin tools. Right now that is creating lecturer and admin accounts, which
/// have no self-service path. Event deletion lives on the event cards
/// (see DeleteEventButton) since that is where the events are.
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isAdminProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Admin panel')),
      body: isAdmin
          ? const _ProvisionUserForm()
          : const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('This area is for administrators only.', textAlign: TextAlign.center),
              ),
            ),
    );
  }
}

class _ProvisionUserForm extends ConsumerStatefulWidget {
  const _ProvisionUserForm();

  @override
  ConsumerState<_ProvisionUserForm> createState() => _ProvisionUserFormState();
}

class _ProvisionUserFormState extends ConsumerState<_ProvisionUserForm> {
  static const _defaultRole = 'lecturer';

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _role = _defaultRole;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _nameController.clear();
    _emailController.clear();
    _passwordController.clear();
    _formKey.currentState?.reset();
    setState(() {
      _role = _defaultRole;
      _obscurePassword = true;
    });
  }

  Future<bool> _confirmAdminRole() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create an admin account?'),
        content: Text(
          '${_nameController.text.trim()} will be able to manage schedules, grades, '
          'announcements, quizzes and other accounts.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Create admin')),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_role == 'admin' && !await _confirmAdminRole()) return;
    if (!mounted) return;

    await ref.read(provisionUserProvider.notifier).provision(
          fullName: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          role: _role,
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<AppUser?>>(provisionUserProvider, (previous, next) {
      // Replace, don't queue behind, any message still on screen.
      final messenger = ScaffoldMessenger.of(context)..removeCurrentSnackBar();
      if (next.hasError) {
        messenger.showSnackBar(SnackBar(content: Text(describeApiError(next.error!))));
      } else if (next.valueOrNull != null) {
        final user = next.value!;
        _resetForm();
        messenger.showSnackBar(SnackBar(content: Text('Created ${user.role} account for ${user.fullName}.')));
      }
    });

    final submitting = ref.watch(provisionUserProvider).isLoading;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Create an account', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Lecturer and admin accounts can only be created here. '
              'Share the password with them directly.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Full name', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().length < 2) ? 'Enter at least 2 characters' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
              validator: (v) {
                final value = v?.trim() ?? '';
                return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value) ? null : 'Enter a valid email address';
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                  icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (v) => (v == null || v.length < 8) ? 'Password must be at least 8 characters' : null,
            ),
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'lecturer', label: Text('Lecturer'), icon: Icon(Icons.school_outlined)),
                ButtonSegment(value: 'admin', label: Text('Admin'), icon: Icon(Icons.admin_panel_settings_outlined)),
              ],
              selected: {_role},
              onSelectionChanged: (selection) => setState(() => _role = selection.first),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: submitting ? null : _submit,
              child: submitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Create account'),
            ),
          ],
        ),
      ),
    );
  }
}
