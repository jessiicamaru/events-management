// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar_settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CalendarSettingsNotifier)
final calendarSettingsProvider = CalendarSettingsNotifierProvider._();

final class CalendarSettingsNotifierProvider
    extends $NotifierProvider<CalendarSettingsNotifier, CalendarSettings> {
  CalendarSettingsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calendarSettingsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calendarSettingsNotifierHash();

  @$internal
  @override
  CalendarSettingsNotifier create() => CalendarSettingsNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CalendarSettings value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CalendarSettings>(value),
    );
  }
}

String _$calendarSettingsNotifierHash() =>
    r'94b17f2de662ff90f36650274d349da0b5be3a06';

abstract class _$CalendarSettingsNotifier extends $Notifier<CalendarSettings> {
  CalendarSettings build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<CalendarSettings, CalendarSettings>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CalendarSettings, CalendarSettings>,
              CalendarSettings,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
