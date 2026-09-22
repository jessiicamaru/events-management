import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker/core/localization/locale_provider.dart';

class MockLocaleNotifier extends LocaleNotifier {
  @override
  AppLocale build() => AppLocale.en;
}

final commonTestOverrides = [
  localeProvider.overrideWith(() => MockLocaleNotifier()),
  translationsProvider.overrideWithValue(AppTranslations(AppLocale.en)),
];
