import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker/features/squads/presentation/screens/squad_dashboard_screen.dart';
import 'package:habit_tracker/features/squads/presentation/providers/squad_provider.dart';
import 'package:habit_tracker/features/squads/domain/models/squad_model.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class FakeSquadNotifier extends SquadNotifier {
  @override
  Future<SquadModel?> build() async {
    return null;
  }
}

void main() {
  testWidgets('SquadDashboardScreen displays title', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          squadProvider.overrideWith(() => FakeSquadNotifier()),
        ],
        child: const ShadApp(
          home: SquadDashboardScreen(),
        ),
      ),
    );

    // Initial state will be loading or empty, so it should at least display the App Bar or main title
    expect(find.text('Squad'), findsOneWidget);

    await tester.pumpAndSettle();
  });
}
