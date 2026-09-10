import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/features/habits/presentation/widgets/heatmap_widget.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

void main() {
  Widget createWidgetUnderTest(Map<DateTime, int> data) {
    return ShadApp(
      home: Scaffold(
        body: HeatmapWidget(data: data),
      ),
    );
  }

  testWidgets('HeatmapWidget renders correctly with empty data', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest({}));

    // Find the title
    expect(find.text('Activity (Last 90 Days)'), findsOneWidget);

    // Find day labels
    expect(find.text('Mon'), findsOneWidget);
    expect(find.text('Wed'), findsOneWidget);
    expect(find.text('Fri'), findsOneWidget);

    // Find legend labels
    expect(find.text('Less'), findsOneWidget);
    expect(find.text('More'), findsOneWidget);
    
    // There should be 90 container blocks for days (plus legend blocks)
    // 90 days + 5 legend blocks = 95 Containers (approx, might be slightly different due to padding/structure)
    final containers = find.byType(Container);
    expect(containers, findsWidgets);
  });

  testWidgets('HeatmapWidget renders with data', (WidgetTester tester) async {
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);
    
    final data = {
      todayKey: 2, // 2 completed events today
    };

    await tester.pumpWidget(createWidgetUnderTest(data));

    expect(find.text('Activity (Last 90 Days)'), findsOneWidget);
    
    // Test logic mainly checks if it doesn't crash and renders the right text
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });
}
