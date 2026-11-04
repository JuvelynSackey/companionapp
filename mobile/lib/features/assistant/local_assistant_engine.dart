import '../../data/models/exam_countdown.dart';
import 'context_aggregator.dart';

/// Deterministic fallback used when no Gemini key is configured or the API
/// call fails. A keyword engine over the data this app actually has (e.g. no
/// shortCode on locations, no per-class "moved" flag from the backend). It
/// only states what that data supports: the earlier shuttle, MoMo, Wi-Fi
/// and food answers, and live library seat counts, had no real data behind
/// them and were removed.
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
    if (q.contains('stress') || q.contains('tired') || q.contains('help') || q.contains('scared') || q.contains('advice') || q.contains('motivation')) {
      return '🇬🇭 **Akwaaba & Words of Encouragement!**\n'
          'University life can be demanding, but you are more than capable.\n'
          '• Break study sessions into 25-minute focused blocks (Pomodoro technique).\n'
          '• Take short walks to reset between sessions.\n'
          '• Need a quiet spot? Ask me where the library is.\n'
          'You\'ve got this — one lecture and one revision session at a time! 🚀';
    }

    return "🇬🇭 **Campus Companion Assistant**:\n"
        'Akwaaba, ${context.userName}! Ask me anything:\n'
        '1. *"Where is the library?"*\n'
        '2. *"When is my next exam and when should I leave?"*\n'
        '3. *"What classes do I have today?"*\n'
        '4. *"How do I register on my student portal?"*\n'
        '5. *"Calculate my ${context.academicMetric.isPercentage ? 'CWA' : 'GPA'}"*';
  }

  /// For data that lives on the server when the server could not be reached.
  /// Better to say so than to report "no grades" or "no events".
  static String _unavailableResponse(String what) {
    return "📡 I can't reach the server to read your $what right now, so I'd only be guessing. "
        'Please try again when you have a connection.';
  }

  /// The libraries among the campus locations the server knows about. There
  /// is no live seat data, so the answer says where they are, not how full.
  static String _libraryResponse(AssistantContext context) {
    if (context.unavailable.contains(ContextSource.locations)) return _unavailableResponse('campus locations');
    final libraries = context.locations.where((l) => l.category == 'library').toList();
    if (libraries.isEmpty) {
      return '📚 No libraries are listed on the campus map yet. Your library portal is in the Resources tab.';
    }
    final buffer = StringBuffer('📚 **Campus Libraries**:\n');
    for (final lib in libraries) {
      buffer.write('• **${lib.name}**${lib.description.isNotEmpty ? ': ${lib.description}' : ''}\n');
    }
    buffer.write('\n💡 *Tip: open the campus map to see where they are and get directions.*');
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
