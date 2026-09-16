import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker/features/profile/presentation/screens/cosmetics_screen.dart';
import 'package:habit_tracker/features/profile/presentation/providers/user_profile_provider.dart';
import 'package:habit_tracker/features/profile/domain/models/user_profile_model.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class FakeUserProfileNotifier extends UserProfileNotifier {
  @override
  Future<UserProfileModel> build() async {
    return const UserProfileModel(
      id: 'test',
      email: 'test@example.com',
      totalXP: 0,
      unlockedEmojis: [],
    );
  }
}

void main() {
  testWidgets('CosmeticsScreen displays title and sections', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileProvider.overrideWith(() => FakeUserProfileNotifier()),
        ],
        child: const ShadApp(
          home: CosmeticsScreen(),
        ),
      ),
    );

    // Initial state will be loading or empty, so it should at least display the App Bar or main title
    expect(find.text('Cosmetics & Rewards'), findsOneWidget);

    await tester.pumpAndSettle();
  });
}
