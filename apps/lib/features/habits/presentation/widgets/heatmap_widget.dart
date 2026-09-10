import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class HeatmapWidget extends StatelessWidget {
  final Map<DateTime, int> data;
  final int daysToShow = 90; // Last 90 days

  const HeatmapWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final today = DateTime.now();
    final startDate = today.subtract(Duration(days: daysToShow - 1));

    // Create a list of all dates to show
    final dates = List.generate(daysToShow, (index) => startDate.add(Duration(days: index)));

    // Group dates by week (columns)
    final List<List<DateTime?>> weeks = [];
    List<DateTime?> currentWeek = List.filled(7, null);
    
    // Fill initial padding for the first week
    int currentDayOfWeek = dates.first.weekday % 7; // Sunday=0
    for (int i = 0; i < currentDayOfWeek; i++) {
      currentWeek[i] = null;
    }

    for (var date in dates) {
      final dayIndex = date.weekday % 7; // Sunday=0, Monday=1, ...
      currentWeek[dayIndex] = date;

      if (dayIndex == 6 || date == dates.last) {
        weeks.add(currentWeek);
        currentWeek = List.filled(7, null);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activity (Last 90 Days)',
          style: theme.textTheme.h4,
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          reverse: true, // Start from the right (today)
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Day labels (Sun, Mon, Wed, Fri)
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildDayLabel(''),
                  _buildDayLabel('Mon'),
                  _buildDayLabel(''),
                  _buildDayLabel('Wed'),
                  _buildDayLabel(''),
                  _buildDayLabel('Fri'),
                  _buildDayLabel(''),
                ],
              ),
              const SizedBox(width: 8),
              // Weeks columns
              ...weeks.map((week) {
                return Padding(
                  padding: const EdgeInsets.only(right: 4.0),
                  child: Column(
                    children: week.map((date) {
                      if (date == null) {
                        return const SizedBox(width: 12, height: 12);
                      }
                      
                      // Normalize date to ignore time
                      final dateKey = DateTime(date.year, date.month, date.day);
                      final count = data.entries
                          .where((e) => e.key.year == dateKey.year && e.key.month == dateKey.month && e.key.day == dateKey.day)
                          .fold(0, (sum, e) => sum + e.value);

                      return Container(
                        width: 12,
                        height: 12,
                        margin: const EdgeInsets.only(bottom: 4.0),
                        decoration: BoxDecoration(
                          color: _getColor(count, theme),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }).toList(),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('Less', style: theme.textTheme.small.copyWith(fontSize: 10)),
            const SizedBox(width: 4),
            _buildLegendBox(_getColor(0, theme)),
            _buildLegendBox(_getColor(1, theme)),
            _buildLegendBox(_getColor(2, theme)),
            _buildLegendBox(_getColor(3, theme)),
            _buildLegendBox(_getColor(4, theme)),
            const SizedBox(width: 4),
            Text('More', style: theme.textTheme.small.copyWith(fontSize: 10)),
          ],
        )
      ],
    );
  }

  Widget _buildDayLabel(String text) {
    return SizedBox(
      height: 16,
      child: Text(
        text,
        style: const TextStyle(fontSize: 10, color: Colors.grey),
      ),
    );
  }

  Widget _buildLegendBox(Color color) {
    return Container(
      width: 10,
      height: 10,
      margin: const EdgeInsets.symmetric(horizontal: 2.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Color _getColor(int count, ShadThemeData theme) {
    if (count == 0) return theme.colorScheme.muted;
    if (count == 1) return Colors.green.withOpacity(0.3);
    if (count == 2) return Colors.green.withOpacity(0.5);
    if (count == 3) return Colors.green.withOpacity(0.7);
    return Colors.green;
  }
}
