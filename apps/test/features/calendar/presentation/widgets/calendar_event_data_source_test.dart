import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:habit_tracker/core/localization/locale_provider.dart';
import 'package:habit_tracker/features/calendar/domain/models/event_model.dart';
import 'package:habit_tracker/features/calendar/presentation/widgets/calendar_event_data_source.dart';

void main() {
  final seriesStart = DateTime.utc(2026, 5, 4, 10);
  final friday = DateTime.utc(2026, 9, 11, 10);
  final thursday = DateTime.utc(2026, 9, 10, 10);

  final series = EventModel(
    id: 'jog',
    title: 'Jogging',
    startTime: seriesStart,
    endTime: seriesStart.add(const Duration(hours: 1)),
    habitId: '',
    recurrenceRule: 'RRULE:FREQ=DAILY',
    recurrenceExceptionDates: thursday.toIso8601String(),
    isCompleted: true, // as a series completed before per-day completion existed
    // The current user's own events; squad members' events are drawn dimmer.
    userId: 'u1',
  );

  final splitOffFriday = EventModel(
    id: 'jog-fri',
    title: 'Jogging',
    startTime: friday,
    endTime: friday.add(const Duration(hours: 1)),
    habitId: '',
    parentEventId: 'jog',
    exceptionDate: friday,
    isCompleted: true,
    userId: 'u1',
  );

  Future<EventDataSource> buildSource(WidgetTester tester, List<EventModel> events) async {
    late ShadThemeData theme;
    await tester.pumpWidget(
      ShadApp(
        home: Builder(
          builder: (context) {
            theme = ShadTheme.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    return EventDataSource(events, const [], theme, 'u1', AppTranslations(AppLocale.en));
  }

  testWidgets('hides a split-off day from the series, so it is not drawn twice', (tester) async {
    // The calendar draws the series' days itself and hides only its exception dates. A
    // day split off locally is deliberately not in that list (it would reach Google and
    // cancel the day there), so the data source has to add it.
    final source = await buildSource(tester, [series, splitOffFriday]);

    final hidden = source.getRecurrenceExceptionDates(0)!;

    expect(hidden, contains(friday.toLocal()), reason: 'the split-off day');
    expect(hidden, contains(thursday.toLocal()), reason: 'the stored exception still applies');
    expect(source.getRecurrenceExceptionDates(1), isNull, reason: 'the day itself repeats nothing');
  });

  testWidgets('has no exception dates for a series nobody has touched', (tester) async {
    final untouched = series.copyWith(recurrenceExceptionDates: null);
    final source = await buildSource(tester, [untouched]);

    expect(source.getRecurrenceExceptionDates(0), isNull);
  });

  testWidgets('a tapped day of the series is undone, even if the series row says done', (tester) async {
    final source = await buildSource(tester, [series]);
    final friday0930 = Appointment(
      startTime: friday.toLocal(),
      endTime: friday.add(const Duration(hours: 1)).toLocal(),
    );

    final day = source.convertAppointmentToObject(series, friday0930) as EventModel;

    expect(day.id, 'jog');
    expect(day.startTime, friday);
    expect(day.isCompleted, isFalse);
  });

  testWidgets('a split-off day keeps its own completion', (tester) async {
    final source = await buildSource(tester, [splitOffFriday]);
    final appointment = Appointment(
      startTime: friday.toLocal(),
      endTime: friday.add(const Duration(hours: 1)).toLocal(),
    );

    final day = source.convertAppointmentToObject(splitOffFriday, appointment) as EventModel;

    expect(day.isCompleted, isTrue);
  });

  testWidgets('does not paint every day of a series as done', (tester) async {
    final source = await buildSource(tester, [series, splitOffFriday]);

    expect(source.getColor(0), isNot(const Color(0xFF10B981)), reason: 'the series');
    expect(source.getColor(1), const Color(0xFF10B981), reason: 'the completed day');
  });
}
