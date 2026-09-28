import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker/features/squads/presentation/screens/squad_dashboard_screen.dart';
import 'package:habit_tracker/features/squads/presentation/providers/squad_provider.dart';
import 'package:habit_tracker/features/squads/domain/models/squad_model.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:habit_tracker/core/localization/locale_provider.dart';

class FakeActiveSquadNotifier extends ActiveSquadNotifier {
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
          activeSquadProvider.overrideWith(() => FakeActiveSquadNotifier()),
          translationsProvider.overrideWithValue(AppTranslations(AppLocale.en)),
        ],
        child: const ShadApp(
          home: SquadDashboardScreen(),
        ),
      ),
    );

    // Title 'Squad' (nav_squad translation) should be found on the AppBar
    expect(find.text('Squad'), findsOneWidget);

    await tester.pumpAndSettle();
  });
}
