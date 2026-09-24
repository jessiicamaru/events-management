// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_category_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(EventCategoriesNotifier)
final eventCategoriesProvider = EventCategoriesNotifierFamily._();

final class EventCategoriesNotifierProvider
    extends
        $AsyncNotifierProvider<EventCategoriesNotifier, List<EventCategory>> {
  EventCategoriesNotifierProvider._({
    required EventCategoriesNotifierFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'eventCategoriesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$eventCategoriesNotifierHash();

  @override
  String toString() {
    return r'eventCategoriesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  EventCategoriesNotifier create() => EventCategoriesNotifier();

  @override
  bool operator ==(Object other) {
    return other is EventCategoriesNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$eventCategoriesNotifierHash() =>
    r'2072937f0bfa3eba8ca6e368aabb61d3f08b3934';

final class EventCategoriesNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          EventCategoriesNotifier,
          AsyncValue<List<EventCategory>>,
          List<EventCategory>,
          FutureOr<List<EventCategory>>,
          String?
        > {
  EventCategoriesNotifierFamily._()
    : super(
        retry: null,
        name: r'eventCategoriesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  EventCategoriesNotifierProvider call({String? squadId}) =>
      EventCategoriesNotifierProvider._(argument: squadId, from: this);

  @override
  String toString() => r'eventCategoriesProvider';
}

abstract class _$EventCategoriesNotifier
    extends $AsyncNotifier<List<EventCategory>> {
  late final _$args = ref.$arg as String?;
  String? get squadId => _$args;

  FutureOr<List<EventCategory>> build({String? squadId});
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<EventCategory>>, List<EventCategory>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<EventCategory>>, List<EventCategory>>,
              AsyncValue<List<EventCategory>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(squadId: _$args));
  }
}
