import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../../core/theme/campus_companion_theme.dart';
import '../../data/models/course.dart';
import '../assistant/assistant_controller.dart' show geminiAssistantServiceProvider;
import 'create_quiz_screen.dart';
import 'past_paper_extraction.dart';

/// All PDF text extraction and AI structuring happens here, entirely on
/// this device — the backend never sees raw PDF bytes or makes an AI call
/// itself (Gemini stays 100% client-side, matching
/// gemini_assistant_service.dart). Only the final, human-reviewed question
/// set (edited on CreateQuizScreen, reusing the exact same form as manual
/// authoring) is ever sent to the backend. The actual JSON-parsing logic
/// lives in past_paper_extraction.dart so it's unit-testable on its own.
enum _Stage { pickFile, extracting, error }

class ImportPastPaperScreen extends ConsumerStatefulWidget {
  const ImportPastPaperScreen({super.key, required this.course});
  final Course course;

  @override
  ConsumerState<ImportPastPaperScreen> createState() => _ImportPastPaperScreenState();
}

class _ImportPastPaperScreenState extends ConsumerState<ImportPastPaperScreen> {
  _Stage _stage = _Stage.pickFile;
  String? _errorMessage;

  String _extractText(Uint8List bytes) {
    final document = PdfDocument(inputBytes: bytes);
    try {
      return PdfTextExtractor(document).extractText();
    } finally {
      document.dispose();
    }
  }

  Future<void> _pickAndExtract() async {
    final files = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (files.isEmpty) return;
    final picked = files.first;

    setState(() {
      _stage = _Stage.extracting;
      _errorMessage = null;
    });

    try {
      final bytes = await picked.readAsBytes();
      final rawText = _extractText(bytes);

      if (rawText.trim().isEmpty) {
        setState(() {
          _stage = _Stage.error;
          _errorMessage = 'This PDF appears to be a scanned image with no extractable text layer — '
              'try a different file, or enter questions manually instead.';
        });
        return;
      }

      final truncated = PastPaperExtraction.truncate(rawText);
      final geminiReply = await ref
          .read(geminiAssistantServiceProvider)
          .ask(systemPrompt: PastPaperExtraction.systemPrompt, query: truncated);

      if (geminiReply == null) {
        setState(() {
          _stage = _Stage.error;
          _errorMessage = 'Could not reach the AI extraction service. Check your connection and try again, '
              'or enter questions manually.';
        });
        return;
      }

      final questions = PastPaperExtraction.parseQuestions(geminiReply);
      if (questions.isEmpty) {
        setState(() {
          _stage = _Stage.error;
          _errorMessage = 'No questions could be extracted from this PDF. Try a different file or enter questions manually.';
        });
        return;
      }

      if (!mounted) return;
      final created = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => CreateQuizScreen(
            course: widget.course,
            initialTitle: 'Past Paper Practice - ${widget.course.courseCode}',
            initialQuestions: questions,
            source: 'past_paper',
          ),
        ),
      );
      if (mounted && created == true) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _stage = _Stage.error;
        _errorMessage = 'Something went wrong reading this PDF: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final campus = Theme.of(context).campusTheme;
    return Scaffold(
      appBar: AppBar(title: Text('Import Past Paper · ${widget.course.courseCode}')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_stage == _Stage.extracting) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text('Extracting text and generating questions with AI...', textAlign: TextAlign.center),
              ] else ...[
                Icon(Icons.picture_as_pdf_outlined, size: 56, color: campus.accentGlow),
                const SizedBox(height: 16),
                const Text(
                  "Pick a text-based past exam PDF. AI drafts questions from it for you to review and edit "
                  'before publishing — nothing is published automatically. Scanned/image-only PDFs have no '
                  'extractable text and will not work.',
                  textAlign: TextAlign.center,
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(_errorMessage!, style: TextStyle(color: Colors.orange.shade800), textAlign: TextAlign.center),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton.icon(
                  style: campus.primaryButtonStyle,
                  onPressed: _pickAndExtract,
                  icon: const Icon(Icons.upload_file_outlined),
                  label: const Text('Choose PDF'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
