import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin/admin_dashboard_screen.dart';
import '../alerts/alerts_screen.dart';
import '../analytics/analytics_screen.dart';
import '../assistant/assistant_screen.dart';
import '../auth/session_controller.dart';
import '../dashboard/dashboard_screen.dart';
import '../events/events_screen.dart';
import '../exams/exams_screen.dart';
import '../locations/locations_screen.dart';
import '../onboarding/institution_controller.dart';
import '../profile/digital_id_screen.dart';
import '../resources/resources_screen.dart';
import '../student_hub/student_hub_screen.dart';
import '../timetable/timetable_screen.dart';
import '../tutor/tutor_screen.dart';
import 'nav_providers.dart';

const _tabTitles = {
  AppTab.dashboard: 'Dashboard',
  AppTab.timetable: 'Timetable',
  AppTab.exams: 'Exams',
  AppTab.alerts: 'Alerts',
  AppTab.resources: 'Resources',
};

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTab = ref.watch(selectedTabProvider);
    final institution = ref.watch(institutionControllerProvider);
    final user = ref.watch(sessionControllerProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: institution.primaryColor,
              child: Text(
                institution.shortCode.substring(0, institution.shortCode.length.clamp(0, 2)),
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(child: Text(_tabTitles[selectedTab] ?? '', overflow: TextOverflow.ellipsis)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.place_outlined),
            tooltip: 'Campus Locations',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LocationsScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.event_outlined),
            tooltip: 'Events',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EventsScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.storefront_outlined),
            tooltip: 'Student Hub',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StudentHubScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.insights_outlined),
            tooltip: 'Analytics',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AnalyticsScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.auto_awesome_outlined),
            tooltip: 'AI Assistant',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AssistantScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.school_outlined),
            tooltip: 'AI Tutor',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TutorScreen())),
          ),
          PopupMenuButton<String>(
            icon: const CircleAvatar(child: Icon(Icons.person)),
            onSelected: (value) {
              if (value == 'signOut') {
                ref.read(sessionControllerProvider.notifier).signOut();
              } else if (value == 'digitalId') {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DigitalIdScreen()));
              } else if (value == 'admin') {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false,
                child: Text(user != null ? '${user.fullName}\n${user.role}' : ''),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'digitalId', child: Text('Digital Student ID')),
              if (user?.isAdmin ?? false) const PopupMenuItem(value: 'admin', child: Text('Admin panel')),
              const PopupMenuItem(value: 'signOut', child: Text('Sign out')),
            ],
          ),
        ],
      ),
      body: IndexedStack(
        index: AppTab.values.indexOf(selectedTab),
        children: const [
          DashboardScreen(),
          TimetableScreen(),
          ExamsScreen(),
          AlertsScreen(),
          ResourcesScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: AppTab.values.indexOf(selectedTab),
        onDestinationSelected: (index) =>
            ref.read(selectedTabProvider.notifier).state = AppTab.values[index],
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.calendar_today_outlined), selectedIcon: Icon(Icons.calendar_today), label: 'Timetable'),
          NavigationDestination(icon: Icon(Icons.edit_note_outlined), selectedIcon: Icon(Icons.edit_note), label: 'Exams'),
          NavigationDestination(icon: Icon(Icons.notifications_outlined), selectedIcon: Icon(Icons.notifications), label: 'Alerts'),
          NavigationDestination(icon: Icon(Icons.local_library_outlined), selectedIcon: Icon(Icons.local_library), label: 'Resources'),
        ],
      ),
    );
  }
}
