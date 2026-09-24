// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_tasks_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(EventTasks)
final eventTasksProvider = EventTasksFamily._();

final class EventTasksProvider
    extends $AsyncNotifierProvider<EventTasks, List<EventTaskModel>> {
  EventTasksProvider._({
    required EventTasksFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'eventTasksProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$eventTasksHash();

  @override
  String toString() {
    return r'eventTasksProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  EventTasks create() => EventTasks();

  @override
  bool operator ==(Object other) {
    return other is EventTasksProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$eventTasksHash() => r'168518d5764353a413d90bd509af4e7ddb11c752';

final class EventTasksFamily extends $Family
    with
        $ClassFamilyOverride<
          EventTasks,
          AsyncValue<List<EventTaskModel>>,
          List<EventTaskModel>,
          FutureOr<List<EventTaskModel>>,
          String
        > {
  EventTasksFamily._()
    : super(
        retry: null,
        name: r'eventTasksProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  EventTasksProvider call(String eventId) =>
      EventTasksProvider._(argument: eventId, from: this);

  @override
  String toString() => r'eventTasksProvider';
}

abstract class _$EventTasks extends $AsyncNotifier<List<EventTaskModel>> {
  late final _$args = ref.$arg as String;
  String get eventId => _$args;

  FutureOr<List<EventTaskModel>> build(String eventId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<EventTaskModel>>, List<EventTaskModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<EventTaskModel>>,
                List<EventTaskModel>
              >,
              AsyncValue<List<EventTaskModel>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
