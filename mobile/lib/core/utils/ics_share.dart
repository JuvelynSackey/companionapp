import 'dart:convert';
import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';

Future<void> shareIcsFile(String icsContent, String filename) async {
  final bytes = Uint8List.fromList(utf8.encode(icsContent));
  final file = XFile.fromData(bytes, mimeType: 'text/calendar', name: filename);
  await SharePlus.instance.share(ShareParams(files: [file], text: 'Import into your calendar app'));
}
