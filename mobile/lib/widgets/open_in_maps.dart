import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> openInMaps(BuildContext context, {required String label, required double latitude, required double longitude}) async {
  final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open maps for $label')));
    }
  }
}
