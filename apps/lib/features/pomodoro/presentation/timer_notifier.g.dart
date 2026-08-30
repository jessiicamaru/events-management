// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timer_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TimerNotifier)
final timerProvider = TimerNotifierProvider._();

final class TimerNotifierProvider
    extends $NotifierProvider<TimerNotifier, PomodoroState> {
  TimerNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'timerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$timerNotifierHash();

  @$internal
  @override
  TimerNotifier create() => TimerNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PomodoroState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PomodoroState>(value),
    );
  }
}

String _$timerNotifierHash() => r'a5b4836cd1c9e96de316c5b0a9989ebcd2f733d7';

abstract class _$TimerNotifier extends $Notifier<PomodoroState> {
  PomodoroState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<PomodoroState, PomodoroState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PomodoroState, PomodoroState>,
              PomodoroState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
