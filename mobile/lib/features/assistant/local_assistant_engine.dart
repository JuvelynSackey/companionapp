import '../../data/models/exam_countdown.dart';
import 'context_aggregator.dart';

/// Deterministic fallback used when no Gemini key is configured or the API
/// call fails. A 12-branch keyword engine, adapted to the data this app actually has
/// (e.g. no shortCode on locations, no per-class "moved" flag from the
/// backend) — branches 7-11 (shuttle/MoMo/wifi/food/stress) had no real
/// data backing in the source either, so they stay as informational text.
class LocalAssistantEngine {
  LocalAssistantEngine._();

  static String respond(String query, AssistantContext context) {
    final q = query.toLowerCase().trim();

    if (q.contains('library') || q.contains('seat') || q.contains('desk') || q.contains('study spot')) {
      return _libraryResponse(context);
    }
    if (q.contains('exam') || q.contains('leave') || q.contains('countdown') || q.contains('venue')) {
      return _examResponse(context);
    }
    if (q.contains('event') || q.contains('club') || q.contains('happening')) {
      if (context.unavailable.contains(ContextSource.events)) return _unavailableResponse('events');
      return _eventsResponse(context);
    }
    if (q.contains('class') || q.contains('schedule') || q.contains('today') || q.contains('timetable') || q.contains('lecture')) {
      return _classResponse(context);
    }
    final matchedLocation = _matchLocation(q, context);
    if (matchedLocation != null) return matchedLocation;
    if (q.contains('gpa') || q.contains('cgpa') || q.contains('cwa') || q.contains('grade') || q.contains('first class') || q.contains('calculate')) {
      if (context.unavailable.contains(ContextSource.grades)) return _unavailableResponse('grades');
      return _gpaResponse(context);
    }
    if (q.contains('registration') || q.contains('register') || q.contains('portal') || q.contains('sakai') || q.contains('mis web') || q.contains('osis') || q.contains('aim')) {
      return _portalsResponse(context);
    }
    if (q.contains('shuttle') || q.contains('bus') || q.contains('trotro') || q.contains('fare')) {
      return '🚌 **Campus Shuttle & Transit Assistance**:\n'
          '• Dedicated campus shuttles run every 8-12 minutes connecting residential halls to central lecture auditoriums.\n'
          '• Standard fare: ~GH₵ 3.50 - GH₵ 5.00 per trip.\n'
          '• Night shuttle service operates 08:00 PM - 11:30 PM for safe student transit.';
    }
    if (q.contains('momo') || q.contains('dues') || q.contains('fee') || q.contains('pay') || q.contains('bursary')) {
      return '💳 **Campus Dues & MoMo Payment**:\n'
          '• Departmental dues, hall dues, and transcript fees can be paid via MTN Mobile Money, Telecel Cash, or AT Money.\n'
          '• For bank slip clearance or fee payment plans, visit the Cash Office at the Registry (Weekdays 8:30 AM - 4:30 PM).';
    }
    if (q.contains('wifi') || q.contains('wi-fi') || q.contains('internet') || q.contains('eduroam')) {
      return '📶 **Campus Wi-Fi Connectivity Guide**:\n'
          '1. Connect to **eduroam** or your university network.\n'
          '2. Identity/Username: your full student email.\n'
          '3. Password: your student portal PIN or Active Directory password.\n'
          '4. EAP Method: `PEAP`, Phase 2 Authentication: `MSCHAPV2`.';
    }
    if (q.contains('food') || q.contains('eat') || q.contains('canteen') || q.contains('hungry')) {
      return '🍽️ **Campus Dining & Food Spots**:\n'
          '• Bush canteens and night markets: waakye, jollof rice, kelewele, fresh juices.\n'
          '• Commercial areas: fast food outlets and bakeries.\n'
          '• Standard hours: 07:00 AM - 10:30 PM daily.';
    }
    if (q.contains('stress') || q.contains('tired') || q.contains('help') || q.contains('scared') || q.contains('advice') || q.contains('motivation')) {
      return '🇬🇭 **Akwaaba & Words of Encouragement!**\n'
          'University life can be demanding, but you are more than capable.\n'
          '• Break study sessions into 25-minute focused blocks (Pomodoro technique).\n'
          '• Take short walks to reset between sessions.\n'
          '• Need a quiet spot? Check the Resources tab for library seat availability.\n'
          'You\'ve got this — one lecture and one revision session at a time! 🚀';
    }

    return "🇬🇭 **Campus Companion Assistant**:\n"
        'Akwaaba, ${context.userName}! Ask me anything:\n'
        '1. *"Where are vacant study desks right now?"*\n'
        '2. *"When is my next exam and when should I leave?"*\n'
        '3. *"What classes do I have today?"*\n'
        '4. *"How do I register on my student portal?"*\n'
        '5. *"Calculate my ${context.academicMetric.isPercentage ? 'CWA' : 'GPA'}"*\n'
        '6. *"Connect to campus Wi-Fi"*';
  }

  /// For data that lives on the server when the server could not be reached.
  /// Better to say so than to report "no grades" or "no events".
  static String _unavailableResponse(String what) {
    return "📡 I can't reach the server to read your $what right now, so I'd only be guessing. "
        'Please try again when you have a connection.';
  }

  static String _libraryResponse(AssistantContext context) {
    final libraries = context.libraries;
    final totalAvailable = libraries.fold<int>(0, (sum, lib) => sum + lib.availableSeats);
    final buffer = StringBuffer('📚 **Campus Libraries & Live Desk Availability**:\n');
    buffer.write('There are currently **$totalAvailable vacant study desks** across campus.\n\n');
    for (final lib in libraries.take(3)) {
      buffer.write('• **${lib.name}** (${lib.campusZone}): **${lib.availableSeats} of ${lib.totalCapacity}** seats free\n');
      buffer.write('  🕒 Hours: ${lib.openingHoursWeekdays}\n');
    }
    buffer.write('\n💡 *Tip: Open the Resources tab to see the full libraries directory.*');
    return buffer.toString();
  }

  static String _examResponse(AssistantContext context) {
    ExamCountdown? nearest;
    for (final countdown in context.examCountdowns) {
      if (!countdown.isPast) {
        nearest = countdown;
        break;
      }
    }
    if (nearest == null) {
      return "🎓 You don't have any upcoming exams recorded. Add one from the Exams tab to get countdown reminders here.";
    }
    final exam = nearest.exam;
    return '🎓 **Upcoming Examination Alert**:\n'
        '• **Course:** ${exam.courseCode} - ${exam.courseTitle}\n'
        '• **Date & Time:** ${nearest.formattedExamDate} at ${exam.startTime} (${exam.endTime})\n'
        '• **Venue:** ${exam.venue}\n'
        '${exam.seatRange.isNotEmpty ? '• **Seating Range:** ${exam.seatRange}\n' : ''}'
        '• **Countdown:** ${nearest.formattedDaysRemaining}';
  }

  static String _eventsResponse(AssistantContext context) {
    if (context.events.isEmpty) {
      return "🎉 No upcoming events recorded right now. Check the Events tab for the latest campus happenings.";
    }
    final buffer = StringBuffer('🎉 **Upcoming Campus Events**:\n');
    for (final event in context.events.take(3)) {
      buffer.write('• **${event.title}**${event.clubName != null ? ' (${event.clubName})' : ''}: '
          '${event.eventDate.toLocal().toString().split('.').first}'
          '${event.location != null ? ' @ ${event.location}' : ''}\n');
    }
    buffer.write('\n💡 *Tip: Open the Events tab to register or see full details.*');
    return buffer.toString();
  }

  static String _classResponse(AssistantContext context) {
    if (context.todaysClasses.isEmpty) {
      return '📋 **Today\'s Schedule**:\nNo classes scheduled for today. Enjoy the free time!';
    }
    final buffer = StringBuffer('📋 **Today\'s Classes**:\n');
    for (final c in context.todaysClasses) {
      buffer.write('• **${c.courseTitle}**: ${c.startTime}-${c.endTime} @ ${c.room ?? 'TBA'} with ${c.lecturer}'
          '${c.inProgress ? ' (in progress now)' : ''}\n');
    }
    return buffer.toString();
  }

  static String? _matchLocation(String q, AssistantContext context) {
    for (final loc in context.locations) {
      final nameWords = loc.name.toLowerCase().split(RegExp(r'\s+'));
      final isMatch = q.contains(loc.name.toLowerCase()) || nameWords.any((w) => w.length > 3 && q.contains(w));
      if (isMatch) {
        return '📍 **Location: ${loc.name}**\n'
            '• **Category:** ${loc.category.replaceAll('_', ' ')}\n'
            '• **Guide:** ${loc.description}';
      }
    }
    return null;
  }

  static String _gpaResponse(AssistantContext context) {
    final metric = context.academicMetric;
    final topTier = context.institution.honoursThresholds.isNotEmpty ? context.institution.honoursThresholds.first : null;
    final buffer = StringBuffer('📊 **Academic Performance Analytics**:\n');
    buffer.write('• **${metric.metricLabel}:** ${metric.formattedScore}\n');
    buffer.write('• **${metric.classLabel}:** ${metric.honoursClass}\n');
    buffer.write('• **Completed Credits:** ${metric.totalCredits} credit hours\n\n');
    if (topTier != null && metric.scoreValue >= topTier.minScore) {
      buffer.write("🌟 You're maintaining **${topTier.title}**! Keep it up.");
    } else if (topTier != null) {
      final gap = (topTier.minScore - metric.scoreValue).clamp(0, double.infinity);
      buffer.write('🎯 **Target:** ${gap.toStringAsFixed(2)} more points to reach **${topTier.title}**.');
    }
    return buffer.toString();
  }

  static String _portalsResponse(AssistantContext context) {
    final buffer = StringBuffer('🌐 **Campus Portal & Registration Guide**:\n');
    for (final portal in context.portals) {
      buffer.write('• **${portal.name}** (${portal.category}): ${portal.description}\n');
    }
    buffer.write('\n💡 *Tip: Open these directly from the Resources > Portals tab.*');
    return buffer.toString();
  }
}
