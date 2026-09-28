import 'package:flutter/material.dart';

/// A sticky overlay widget that displays time labels, designed to be
/// positioned on top of a horizontally scrollable [SfCalendar] to keep
/// the time column visible at all times.
///
/// Uses [IgnorePointer] so touch events pass through to the calendar
/// and DragTarget underneath.
class StickyTimeRulerOverlay extends StatelessWidget {
  final double viewHeaderHeight;
  final double timeRulerWidth;
  final double timeIntervalHeight;
  final int startHour;
  final int endHour;
  final ScrollController scrollController;
  final TextStyle? timeTextStyle;
  final Color backgroundColor;
  final Color borderColor;

  const StickyTimeRulerOverlay({
    super.key,
    required this.viewHeaderHeight,
    required this.timeRulerWidth,
    required this.timeIntervalHeight,
    required this.startHour,
    required this.endHour,
    required this.scrollController,
    this.timeTextStyle,
    required this.backgroundColor,
    required this.borderColor,
  });

  /// Format hour in 12-hour AM/PM format (e.g., "7 AM", "12 PM").
  String _formatHour(int hour) {
    if (hour == 0 || hour == 24) return '12 AM';
    if (hour == 12) return '12 PM';
    if (hour < 12) return '$hour AM';
    return '${hour - 12} PM';
  }

  @override
  Widget build(BuildContext context) {
    final hourCount = endHour - startHour;

    return IgnorePointer(
      child: Container(
        width: timeRulerWidth,
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border(
            right: BorderSide(color: borderColor, width: 0.5),
          ),
        ),
        child: Column(
          children: [
            // Corner cell matching the view header height.
            // This covers the top-left corner where time ruler meets
            // the day headers (M 20, T 21, etc.)
            Container(
              height: viewHeaderHeight,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: borderColor, width: 0.5),
                ),
              ),
            ),
            // Scrollable time labels synced with the calendar's
            // internal vertical scroll via NotificationListener
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: hourCount,
                itemExtent: timeIntervalHeight,
                itemBuilder: (context, index) {
                  final hour = startHour + index;
                  return Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      _formatHour(hour),
                      style: timeTextStyle,
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
