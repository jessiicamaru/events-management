import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../features/calendar/presentation/calendar_screen.dart';
import '../../features/habits/presentation/habits_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

import '../../features/squads/presentation/screens/squad_dashboard_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      
      // While auth state is still loading from storage, show splash
      if (authState.isLoading) {
        return state.uri.path == '/splash' ? null : '/splash';
      }

      final isAuthenticated = authState.value != null;
      final isLoggingIn = state.uri.path == '/login' || state.uri.path == '/register';
      final isSplash = state.uri.path == '/splash';

      if (!isAuthenticated && !isLoggingIn) return '/login';
      if (isAuthenticated && (isLoggingIn || isSplash)) return '/calendar';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
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
            path: '/squad',
            builder: (context, state) => const SquadDashboardScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );

  ref.listen(authProvider, (_, __) => router.refresh());

  return router;
});

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
            icon: Icon(LucideIcons.users),
            label: 'Squad',
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
    if (location.startsWith('/squad')) {
      return 2;
    }
    if (location.startsWith('/settings')) {
      return 3;
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
        GoRouter.of(context).go('/squad');
        break;
      case 3:
        GoRouter.of(context).go('/settings');
        break;
    }
  }
}
