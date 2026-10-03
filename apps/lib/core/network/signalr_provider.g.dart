// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'signalr_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SignalrConnection)
final signalrConnectionProvider = SignalrConnectionProvider._();

final class SignalrConnectionProvider
    extends $AsyncNotifierProvider<SignalrConnection, HubConnection?> {
  SignalrConnectionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'signalrConnectionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$signalrConnectionHash();

  @$internal
  @override
  SignalrConnection create() => SignalrConnection();
}

String _$signalrConnectionHash() => r'855ca49d113649d20be7a97b4e4b8803924a232f';

abstract class _$SignalrConnection extends $AsyncNotifier<HubConnection?> {
  FutureOr<HubConnection?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<HubConnection?>, HubConnection?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<HubConnection?>, HubConnection?>,
              AsyncValue<HubConnection?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
