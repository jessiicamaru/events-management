import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:habit_tracker/features/calendar/presentation/calendar_screen.dart';
import 'package:habit_tracker/features/calendar/presentation/widgets/calendar_toolbar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return ProviderScope(
      child: ShadApp(
        home: Scaffold(body: child),
      ),
    );
  }

  group('CalendarToolbar', () {
    testWidgets('renders all components correctly', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      AppCalendarView view = AppCalendarView.threeDay;

      await tester.pumpWidget(buildTestableWidget(
        CalendarToolbar(
          displayDate: DateTime(2025, 4, 15),
          currentView: AppCalendarView.threeDay,
          onViewChanged: (v) { view = v; },
          onTodayPressed: () {  },
          onNextPressed: () {  },
          onPrevPressed: () {  },
          totalEvents: 5,
        ),
      ));

      // Check Date Block text
      expect(find.text('15'), findsOneWidget); // Day
      expect(find.text('April 2025'), findsOneWidget); // Month Year
      expect(find.text('5 events'), findsOneWidget); // Badge

      // Check view switcher icons
      expect(find.byIcon(LucideIcons.layoutList), findsOneWidget);
      expect(find.byIcon(LucideIcons.columns), findsOneWidget);
      expect(find.byIcon(LucideIcons.calendarDays), findsOneWidget);

      // Check category dropdown
      expect(find.text('All Categories'), findsWidgets);

      // Tap Month icon
      await tester.tap(find.byIcon(LucideIcons.calendarDays));
      await tester.pumpAndSettle();
      expect(view, equals(AppCalendarView.month));
    });
  });
}
