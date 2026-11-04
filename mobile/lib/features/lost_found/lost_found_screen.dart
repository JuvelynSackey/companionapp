import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/network/api_exception.dart';
import '../../core/providers/core_providers.dart';
import '../../core/theme/campus_companion_theme.dart';
import '../../data/models/lost_found_item.dart';
import '../../widgets/async_value_view.dart';
import '../auth/guest_prompt.dart';

/// The shared board (GET /api/lost-found), refetched after every change.
final lostFoundProvider = FutureProvider.autoDispose<List<LostFoundItem>>((ref) {
  return ref.watch(lostFoundApiProvider).fetch();
});

/// Lost & Found: a board shared by everyone on the server. Students post
/// what they lost or found; the poster (or an admin) marks it returned or
/// removes it. It replaced a sample list that lived on each phone only.
class LostFoundScreen extends ConsumerWidget {
  const LostFoundScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(lostFoundProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Lost & Found')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          if (!await ensureSignedIn(context, ref, action: 'post on the Lost & Found board')) return;
          if (!context.mounted) return;
          final posted = await showDialog<bool>(context: context, builder: (_) => const ReportItemDialog());
          if (posted == true) ref.invalidate(lostFoundProvider);
        },
        icon: const Icon(Icons.add),
        label: const Text('Post an item'),
      ),
      body: AsyncValueView<List<LostFoundItem>>(
        value: items,
        onRetry: () => ref.invalidate(lostFoundProvider),
        data: (context, list) => RefreshIndicator(
          onRefresh: () => ref.refresh(lostFoundProvider.future),
          child: list.isEmpty
              ? ListView(children: const [
                  Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'Nothing has been posted yet. Lost something, or found something? Post it here.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ])
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  itemCount: list.length,
                  itemBuilder: (context, index) => _ItemCard(item: list[index]),
                ),
        ),
      ),
    );
  }
}

class _ItemCard extends ConsumerWidget {
  const _ItemCard({required this.item});
  final LostFoundItem item;

  Future<void> _change(BuildContext context, WidgetRef ref, Future<void> Function() action, String done) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      ref.invalidate(lostFoundProvider);
      messenger.showSnackBar(SnackBar(content: Text(done)));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campus = Theme.of(context).campusTheme;
    final api = ref.read(lostFoundApiProvider);
    final kindColor = item.kind == LostFoundKind.lost ? Theme.of(context).colorScheme.error : Colors.green.shade700;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: campus.cardDecoration(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Chip(label: item.kind.label, color: kindColor),
              if (item.isReturned) ...[
                const SizedBox(width: 8),
                _Chip(label: 'Returned', color: campus.textMuted),
              ],
              const Spacer(),
              Text(DateFormat('d MMM').format(item.createdAt.toLocal()), style: TextStyle(color: campus.textMuted, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Text(item.title, style: Theme.of(context).textTheme.titleMedium),
          if (item.location != null) ...[
            const SizedBox(height: 4),
            Row(children: [
              Icon(Icons.place_outlined, size: 16, color: campus.textMuted),
              const SizedBox(width: 4),
              Expanded(child: Text(item.location!, style: TextStyle(color: campus.textMuted))),
            ]),
          ],
          if (item.description != null) ...[
            const SizedBox(height: 8),
            Text(item.description!),
          ],
          if (item.postedBy != null || item.contact != null) ...[
            const SizedBox(height: 8),
            Text(
              [if (item.postedBy != null) 'Posted by ${item.postedBy}', if (item.contact != null) 'Contact: ${item.contact}'].join(' · '),
              style: TextStyle(color: campus.textMuted, fontSize: 12),
            ),
          ],
          if (item.canManage) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!item.isReturned)
                  TextButton.icon(
                    onPressed: () => _change(context, ref, () => api.markReturned(item.itemId), 'Marked as returned.'),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Mark returned'),
                  ),
                TextButton.icon(
                  onPressed: () => _change(context, ref, () => api.remove(item.itemId), 'Post removed.'),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Remove'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}

/// Posts an item. Pops `true` once the server has accepted it.
class ReportItemDialog extends ConsumerStatefulWidget {
  const ReportItemDialog({super.key});

  @override
  ConsumerState<ReportItemDialog> createState() => _ReportItemDialogState();
}

class _ReportItemDialogState extends ConsumerState<ReportItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _location = TextEditingController();
  final _description = TextEditingController();
  final _contact = TextEditingController();
  LostFoundKind _kind = LostFoundKind.lost;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    _description.dispose();
    _contact.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(lostFoundApiProvider).post(
            kind: _kind,
            title: _title.text.trim(),
            location: _location.text.trim(),
            description: _description.text.trim(),
            contact: _contact.text.trim(),
          );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Post an item'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<LostFoundKind>(
                segments: const [
                  ButtonSegment(value: LostFoundKind.lost, label: Text('I lost this')),
                  ButtonSegment(value: LostFoundKind.found, label: Text('I found this')),
                ],
                selected: {_kind},
                onSelectionChanged: (selection) => setState(() => _kind = selection.first),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _title,
                maxLength: 120,
                decoration: const InputDecoration(labelText: 'What is it?'),
                validator: (v) => (v == null || v.trim().length < 3) ? 'At least 3 characters' : null,
              ),
              TextFormField(
                controller: _location,
                maxLength: 160,
                decoration: const InputDecoration(labelText: 'Where (optional)'),
              ),
              TextFormField(
                controller: _description,
                maxLines: 3,
                maxLength: 1000,
                decoration: const InputDecoration(labelText: 'Details (optional)'),
              ),
              TextFormField(
                controller: _contact,
                maxLength: 160,
                decoration: const InputDecoration(
                  labelText: 'How to reach you (optional)',
                  helperText: 'Only shown to signed-in students.',
                ),
              ),
              if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _submitting ? null : () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(onPressed: _submitting ? null : _submit, child: const Text('Post')),
      ],
    );
  }
}
