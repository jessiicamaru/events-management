import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:habit_tracker/features/calendar/presentation/calendar_screen.dart';
import 'package:habit_tracker/features/habits/presentation/habits_screen.dart';
import 'package:habit_tracker/features/home/presentation/home_screen.dart';
import 'package:habit_tracker/features/settings/presentation/settings_screen.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker/features/auth/presentation/screens/login_screen.dart';
import 'package:habit_tracker/features/auth/presentation/screens/register_screen.dart';
import 'package:habit_tracker/features/auth/presentation/providers/auth_provider.dart';

import 'package:habit_tracker/features/squads/presentation/screens/squads_list_screen.dart';
import 'package:habit_tracker/features/assistant/presentation/screens/assistant_screen.dart';
import 'package:habit_tracker/features/assistant/presentation/widgets/assistant_fab.dart';
import 'package:habit_tracker/core/localization/locale_provider.dart';
import 'package:habit_tracker/core/utils/app_constants.dart';

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
      if (isAuthenticated && (isLoggingIn || isSplash)) return AppConstants.landingRoute;
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
      // Over the tabs, not inside them: the chat takes the whole screen and has a back button.
      GoRoute(
        path: AppConstants.assistantRoute,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AssistantScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return ScaffoldWithNavBar(child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
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
            builder: (context, state) => const SquadsListScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );

  ref.listen(authProvider, (_, _) => router.refresh());

  return router;
});

class ScaffoldWithNavBar extends ConsumerWidget {
  const ScaffoldWithNavBar({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final translations = ref.watch(translationsProvider);
    
    return Scaffold(
      body: child,
      // The calendar stacks its own, smaller one above its create-event button instead.
      floatingActionButton: GoRouterState.of(context).uri.path.startsWith(_calendarPath)
          ? null
          : const AssistantFab(),
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
          items: [
            for (final tab in _tabs)
              BottomNavigationBarItem(
                icon: Icon(tab.icon),
                label: translations.translate(tab.labelKey),
              ),
          ],
          currentIndex: _selectedIndex(context),
          onTap: (index) => GoRouter.of(context).go(_tabs[index].path),
        ),
      ),
    );
  }

  static const String _calendarPath = '/calendar';

  /// The one place a tab is defined. The index into this list *is* the bar's
  /// index, so the icons, the labels and the destinations cannot drift apart —
  /// which they previously could, being three separate hardcoded lists.
  static const List<_NavTab> _tabs = [
    _NavTab('/home', LucideIcons.house, 'nav_home'),
    _NavTab(_calendarPath, LucideIcons.calendarDays, 'nav_calendar'),
    _NavTab('/habits', LucideIcons.listTodo, 'nav_habits'),
    _NavTab('/squad', LucideIcons.users, 'nav_squad'),
    _NavTab('/settings', LucideIcons.settings, 'nav_settings'),
  ];

  static int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final index = _tabs.indexWhere((tab) => location.startsWith(tab.path));

    // A shell route the bar has no tab for — fall back to the first tab rather
    // than passing -1 to BottomNavigationBar, which throws.
    return index == -1 ? 0 : index;
  }
}

class _NavTab {
  const _NavTab(this.path, this.icon, this.labelKey);

  final String path;
  final IconData icon;
  final String labelKey;
}
