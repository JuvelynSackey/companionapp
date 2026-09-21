import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/core_providers.dart';
import '../../data/models/resource_models.dart';

/// Logs a document request (never generates the document itself — see
/// DocumentType's doc comment on resource_models.dart).
class DocumentRequestController extends Notifier<List<DocumentRequest>> {
  final _random = Random();

  @override
  List<DocumentRequest> build() => ref.watch(localPrefsProvider).documentRequests;

  DocumentRequest? latestFor(DocumentType type) {
    final matches = state.where((r) => r.type == type).toList();
    if (matches.isEmpty) return null;
    matches.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
    return matches.first;
  }

  Future<DocumentRequest> request(DocumentType type) async {
    final prefix = type == DocumentType.transcript ? 'TRX' : 'POR';
    final request = DocumentRequest(
      type: type,
      referenceNumber: '$prefix-${DateTime.now().millisecondsSinceEpoch}-${_random.nextInt(9999)}',
      requestedAt: DateTime.now(),
    );
    final updated = [...state, request];
    await ref.read(localPrefsProvider).saveDocumentRequests(updated);
    state = updated;
    return request;
  }
}

final documentRequestControllerProvider =
    NotifierProvider<DocumentRequestController, List<DocumentRequest>>(DocumentRequestController.new);
