import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../features/calendar/presentation/calendar_screen.dart';
import '../../features/habits/presentation/habits_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/calendar',
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return ScaffoldWithNavBar(child: child);
      },
      routes: [
        GoRoute(
          path: '/calendar',
          builder: (context, state) => const CalendarScreen(),
        ),
        GoRoute(
          path: '/habits',
          builder: (context, state) => const HabitsScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
  ],
);

class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: theme.colorScheme.border)),
        ),
        child: BottomNavigationBar(
          backgroundColor: theme.colorScheme.background,
          selectedItemColor: theme.colorScheme.primary,
          unselectedItemColor: theme.colorScheme.mutedForeground,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.calendarDays),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.listTodo),
            label: 'Habits',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.settings),
            label: 'Settings',
          ),
        ],
          currentIndex: _calculateSelectedIndex(context),
          onTap: (int idx) => _onItemTapped(idx, context),
        ),
      ),
    );
  }

  static int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/calendar')) {
      return 0;
    }
    if (location.startsWith('/habits')) {
      return 1;
    }
    if (location.startsWith('/settings')) {
      return 2;
    }
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        GoRouter.of(context).go('/calendar');
        break;
      case 1:
        GoRouter.of(context).go('/habits');
        break;
      case 2:
        GoRouter.of(context).go('/settings');
        break;
    }
  }
}
