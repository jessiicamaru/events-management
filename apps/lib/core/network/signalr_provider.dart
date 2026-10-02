import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:habit_tracker/core/network/api_service.dart';
import 'package:habit_tracker/features/auth/presentation/providers/auth_provider.dart';

part 'signalr_provider.g.dart';

@Riverpod(keepAlive: true)
class SignalrConnection extends _$SignalrConnection {
  HubConnection? _connection;

  @override
  Future<HubConnection?> build() async {
    final authState = ref.watch(authProvider);
    
    // Clean up previous connection if any
    if (_connection != null) {
      await _connection!.stop();
      _connection = null;
    }

    final token = authState.value;
    if (token == null || token.isEmpty) {
      return null;
    }

    final api = ref.read(apiServiceProvider);
    final baseUrl = api.dio.options.baseUrl;
    final hubUrl = baseUrl.replaceAll('/api/v1', '/socialHub');

    _connection = HubConnectionBuilder()
        .withUrl(
          hubUrl,
          options: HttpConnectionOptions(
            accessTokenFactory: () async {
              final token = await ref.read(authProvider.future);
              return token ?? "";
            },
          ),
        )
        .build();

    _connection!.onclose(({error}) {
      print("SignalR Connection closed: $error");
    });

    try {
      await _connection!.start();
      print("SignalR Connected successfully to $hubUrl");
      return _connection;
    } catch (e) {
      print("SignalR Connection failed: $e");
      return null;
    }
  }
}
