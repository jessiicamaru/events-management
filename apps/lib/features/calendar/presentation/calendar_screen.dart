import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import '../../../core/utils/app_constants.dart';
import '../../habits/domain/models/habit_model.dart';
import '../../habits/presentation/habits_provider.dart';
import '../domain/models/event_model.dart';
import 'events_provider.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  final CalendarController _calendarController = CalendarController();

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(habitsProvider);
    final eventsAsync = ref.watch(eventsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.appTitle)),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: DragTarget<HabitModel>(
              onAcceptWithDetails: (details) async {
                final habit = details.data;
                final startTime = DateTime.now();
                final endTime = startTime.add(const Duration(minutes: AppConstants.defaultPomodoroDurationMinutes));

                final newEvent = EventModel(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  title: habit.name,
                  category: habit.category ?? AppConstants.uncategorized,
                  startTime: startTime,
                  endTime: endTime,
                );

                await ref.read(eventsProvider.notifier).addEvent(newEvent);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Scheduled ${habit.name} at ${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')}')),
                  );
                }
              },
              builder: (context, candidateData, rejectedData) {
                return eventsAsync.when(
                  data: (events) => SfCalendar(
                    controller: _calendarController,
                    view: CalendarView.week,
                    allowDragAndDrop: true,
                    dataSource: _EventDataSource(events),
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('${AppConstants.errorPrefix}$err')),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(AppConstants.unscheduledHabitsLabel, style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: habitsAsync.when(
                    data: (habits) {
                      if (habits.isEmpty) {
                        return const Center(child: Text(AppConstants.noUnscheduledHabitsMessage));
                      }
                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: habits.length,
                        itemBuilder: (context, index) {
                          final habit = habits[index];
                          return Draggable<HabitModel>(
                            data: habit,
                            feedback: Material(
                              elevation: AppConstants.draggableElevation,
                              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                                ),
                                child: Text(habit.name, style: const TextStyle(color: Colors.white)),
                              ),
                            ),
                            childWhenDragging: Container(
                              width: 120,
                              margin: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                              ),
                            ),
                            child: Container(
                              width: 120,
                              margin: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(habit.name, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    if (habit.category != null) ...[
                                      const SizedBox(height: 4),
                                      Text(habit.category!, style: const TextStyle(fontSize: 10, color: Colors.black54)),
                                    ]
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Center(child: Text('${AppConstants.errorPrefix}$err')),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EventDataSource extends CalendarDataSource {
  _EventDataSource(List<EventModel> source) {
    appointments = source.map((e) {
      return Appointment(
        startTime: e.startTime,
        endTime: e.endTime,
        subject: e.title,
        color: Colors.blue,
      );
    }).toList();
  }
}
