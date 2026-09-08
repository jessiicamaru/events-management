// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'events_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

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

String _$eventsNotifierHash() => r'9f3d6fe0bbec8eb07b2a2604627a7f2d2d2d83eb';

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
