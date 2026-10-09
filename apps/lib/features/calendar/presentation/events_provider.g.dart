// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'events_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CalendarViewRangeNotifier)
final calendarViewRangeProvider = CalendarViewRangeNotifierProvider._();

final class CalendarViewRangeNotifierProvider
    extends $NotifierProvider<CalendarViewRangeNotifier, CalendarViewRange?> {
  CalendarViewRangeNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calendarViewRangeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calendarViewRangeNotifierHash();

  @$internal
  @override
  CalendarViewRangeNotifier create() => CalendarViewRangeNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CalendarViewRange? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CalendarViewRange?>(value),
    );
  }
}

String _$calendarViewRangeNotifierHash() =>
    r'f97ca44cb860b5dae7ce57a7a43634460329a9e1';

abstract class _$CalendarViewRangeNotifier
    extends $Notifier<CalendarViewRange?> {
  CalendarViewRange? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<CalendarViewRange?, CalendarViewRange?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CalendarViewRange?, CalendarViewRange?>,
              CalendarViewRange?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(GoogleCalendarSyncTracker)
final googleCalendarSyncTrackerProvider = GoogleCalendarSyncTrackerProvider._();

final class GoogleCalendarSyncTrackerProvider
    extends $NotifierProvider<GoogleCalendarSyncTracker, DateTime?> {
  GoogleCalendarSyncTrackerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'googleCalendarSyncTrackerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$googleCalendarSyncTrackerHash();

  @$internal
  @override
  GoogleCalendarSyncTracker create() => GoogleCalendarSyncTracker();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime?>(value),
    );
  }
}

String _$googleCalendarSyncTrackerHash() =>
    r'dc653073091f43994325bbffc80f5f3112241101';

abstract class _$GoogleCalendarSyncTracker extends $Notifier<DateTime?> {
  DateTime? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<DateTime?, DateTime?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DateTime?, DateTime?>,
              DateTime?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(EventsNotifier)
final eventsProvider = EventsNotifierProvider._();

final class EventsNotifierProvider
    extends $AsyncNotifierProvider<EventsNotifier, List<EventModel>> {
  EventsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'eventsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$eventsNotifierHash();

  @$internal
  @override
  EventsNotifier create() => EventsNotifier();
}

String _$eventsNotifierHash() => r'7f5c41246c711216b7ae2864798d56f55feadce6';

abstract class _$EventsNotifier extends $AsyncNotifier<List<EventModel>> {
  FutureOr<List<EventModel>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<EventModel>>, List<EventModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<EventModel>>, List<EventModel>>,
              AsyncValue<List<EventModel>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
