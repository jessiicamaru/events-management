import 'package:habit_tracker/core/localization/locale_provider.dart';
import 'package:habit_tracker/features/auth/presentation/providers/auth_provider.dart';

class MockLocaleNotifier extends LocaleNotifier {
  @override
  AppLocale build() => AppLocale.en;
}

final commonTestOverrides = [
  localeProvider.overrideWith(() => MockLocaleNotifier()),
  translationsProvider.overrideWithValue(AppTranslations(AppLocale.en)),
];

/// Signed in, without touching the platform's secure storage.
///
/// `eventsProvider` and `habitsProvider` wait for a token before fetching (they are
/// alive from app start, so a tokenless fetch would 401 across the login — see
/// `AuthInterceptor`). Any test that drives them therefore has to say the user is
/// signed in, or they resolve to an empty list.
class MockAuth extends Auth {
  @override
  Future<String?> build() async => 'test-token';
}

/// Overrides for a test whose user is signed in.
final signedInOverrides = [authProvider.overrideWith(MockAuth.new)];
