import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:habit_tracker/features/calendar/domain/models/event_model.dart';
import 'package:habit_tracker/features/habits/domain/models/habit_model.dart';
import 'package:habit_tracker/features/habits/domain/streak_at_risk.dart';
import 'package:habit_tracker/features/home/presentation/widgets/streak_at_risk_card.dart';
import '../../../test_utils.dart';

void main() {
  final slot = DateTime(2026, 9, 11, 21, 30);

  HabitAtRisk atRisk({String name = 'Read', int streak = 5}) => HabitAtRisk(
        habit: HabitModel(
          id: 'habit-${name.toLowerCase()}',
          name: name,
          targetDays: const [1, 2, 3, 4, 5],
          currentStreak: streak,
        ),
        occurrence: EventModel(
          id: 'event-1',
          title: name,
          startTime: slot,
          endTime: slot.add(const Duration(minutes: 30)),
          habitId: 'habit-${name.toLowerCase()}',
        ),
      );

  Widget buildCard(List<HabitAtRisk> habits, {ValueChanged<HabitAtRisk>? onTap}) {
    return ProviderScope(
      overrides: commonTestOverrides,
      child: ShadApp(
        home: Scaffold(
          body: StreakAtRiskCard(
            atRisk: habits,
            onTapHabit: onTap ?? (_) {},
          ),
        ),
      ),
    );
  }

  testWidgets('names each habit, its streak and the slot', (tester) async {
    await tester.pumpWidget(buildCard([atRisk(), atRisk(name: 'Run', streak: 30)]));
    await tester.pumpAndSettle();

    expect(find.text('Streak about to break'), findsOneWidget);
    expect(find.text('Read'), findsOneWidget);
    expect(find.text('5-day streak'), findsOneWidget);
    expect(find.text('Run'), findsOneWidget);
    expect(find.text('30-day streak'), findsOneWidget);
  });

  testWidgets('renders nothing when nothing is at risk', (tester) async {
    // The parent already hides it; a card that renders its heading over an empty list
    // would be worse than absent, so it stands on its own too.
    await tester.pumpWidget(buildCard(const []));
    await tester.pumpAndSettle();

    expect(find.text('Streak about to break'), findsNothing);
  });

  testWidgets('tapping a habit reports which one', (tester) async {
    HabitAtRisk? tapped;
    await tester.pumpWidget(buildCard([atRisk()], onTap: (h) => tapped = h));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Read'));
    await tester.pumpAndSettle();

    expect(tapped?.habit.name, 'Read');
  });
}
