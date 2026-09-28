// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habit_tasks_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(HabitTasks)
final habitTasksProvider = HabitTasksFamily._();

final class HabitTasksProvider
    extends $AsyncNotifierProvider<HabitTasks, List<HabitTaskModel>> {
  HabitTasksProvider._({
    required HabitTasksFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'habitTasksProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$habitTasksHash();

  @override
  String toString() {
    return r'habitTasksProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  HabitTasks create() => HabitTasks();

  @override
  bool operator ==(Object other) {
    return other is HabitTasksProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$habitTasksHash() => r'e9e681c2049eb20734cc9730f0d86cd291f9aa32';

final class HabitTasksFamily extends $Family
    with
        $ClassFamilyOverride<
          HabitTasks,
          AsyncValue<List<HabitTaskModel>>,
          List<HabitTaskModel>,
          FutureOr<List<HabitTaskModel>>,
          String
        > {
  HabitTasksFamily._()
    : super(
        retry: null,
        name: r'habitTasksProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  HabitTasksProvider call(String habitId) =>
      HabitTasksProvider._(argument: habitId, from: this);

  @override
  String toString() => r'habitTasksProvider';
}

abstract class _$HabitTasks extends $AsyncNotifier<List<HabitTaskModel>> {
  late final _$args = ref.$arg as String;
  String get habitId => _$args;

  FutureOr<List<HabitTaskModel>> build(String habitId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<HabitTaskModel>>, List<HabitTaskModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<HabitTaskModel>>,
                List<HabitTaskModel>
              >,
              AsyncValue<List<HabitTaskModel>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
