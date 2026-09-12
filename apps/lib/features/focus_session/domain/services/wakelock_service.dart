import 'package:wakelock_plus/wakelock_plus.dart';

/// Abstract interface for wakelock operations.
/// Allows mocking in tests without hitting native platform channels.
abstract class WakelockService {
  Future<void> enable();
  Future<void> disable();
}

/// Production implementation using wakelock_plus.
class WakelockPlusService implements WakelockService {
  @override
  Future<void> enable() => WakelockPlus.enable();

  @override
  Future<void> disable() => WakelockPlus.disable();
}

/// No-op implementation for use in tests.
class NoOpWakelockService implements WakelockService {
  @override
  Future<void> enable() async {}

  @override
  Future<void> disable() async {}
}
