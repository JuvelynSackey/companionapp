import 'package:flutter/material.dart';

/// Matches GET /api/locations/categories exactly: lecture_hall, library,
/// laboratory, cafeteria, office, hostel, other.
Color colorForLocationCategory(String category) {
  switch (category) {
    case 'lecture_hall':
      return Colors.blue;
    case 'library':
      return Colors.purple;
    case 'laboratory':
      return Colors.teal;
    case 'cafeteria':
      return Colors.amber.shade700;
    case 'office':
      return Colors.indigo;
    case 'hostel':
      return Colors.green;
    default:
      return Colors.grey.shade600;
  }
}

IconData iconForLocationCategory(String category) {
  switch (category) {
    case 'lecture_hall':
      return Icons.school_outlined;
    case 'library':
      return Icons.local_library_outlined;
    case 'laboratory':
      return Icons.science_outlined;
    case 'cafeteria':
      return Icons.restaurant_outlined;
    case 'office':
      return Icons.business_outlined;
    case 'hostel':
      return Icons.hotel_outlined;
    default:
      return Icons.place_outlined;
  }
}
