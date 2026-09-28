import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:habit_tracker/core/network/api_service.dart';
import 'package:habit_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:habit_tracker/features/squads/domain/models/squad_model.dart';

class SquadChatState {
  final List<SquadChatMessageModel> messages;
  final bool isConnecting;
  final String? error;

  SquadChatState({
    this.messages = const [],
    this.isConnecting = false,
    this.error,
  });

  SquadChatState copyWith({
    List<SquadChatMessageModel>? messages,
    bool? isConnecting,
    String? error,
  }) {
    return SquadChatState(
      messages: messages ?? this.messages,
      isConnecting: isConnecting ?? this.isConnecting,
      error: error ?? this.error,
    );
  }
}

final squadChatProvider = Provider.family<SquadChatNotifier, String>((ref, squadId) {
  ref.watch(authProvider);
  return SquadChatNotifier(ref, squadId);
});

class SquadChatNotifier extends ValueNotifier<SquadChatState> {
  final Ref ref;
  final String squadId;
  HubConnection? _connection;
  bool _isDisposed = false;

  SquadChatNotifier(this.ref, this.squadId) : super(SquadChatState(isConnecting: true)) {
    _init();
    ref.onDispose(() {
      _isDisposed = true;
      _disconnect();
    });
  }

  Future<void> _init() async {
    final api = ref.read(apiServiceProvider);

    try {
      // 1. Fetch chat history
      final history = await api.fetchChatHistory(squadId);
      if (!_isDisposed) {
        value = SquadChatState(messages: history, isConnecting: false);
      }

      // 2. Setup SignalR Connection
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
        if (!_isDisposed) {
          value = value.copyWith(error: error?.toString() ?? "Disconnected");
        }
      });

      // Handle receiving messages
      _connection!.on("ReceiveMessage", (arguments) {
        if (arguments != null && arguments.isNotEmpty && !_isDisposed) {
          try {
            final data = Map<String, dynamic>.from(arguments.first as Map);
            final msg = SquadChatMessageModel.fromJson(data);
            value = value.copyWith(messages: [...value.messages, msg]);
          } catch (e) {
            print("Error parsing chat message: $e");
          }
        }
      });



      await _connection!.start();

      // Join the squad group
      await _connection!.invoke("JoinSquadGroup", args: [squadId]);

    } catch (e) {
      if (!_isDisposed) {
        value = SquadChatState(messages: value.messages, error: e.toString(), isConnecting: false);
      }
    }
  }

  Future<void> sendMessage(String text) async {
    if (_connection == null || _connection!.state != HubConnectionState.Connected) {
      throw Exception("Chat is not connected");
    }
    await _connection!.invoke("SendMessage", args: [squadId, text]);
  }

  Future<void> sendPoke(String targetUserId) async {
    if (_connection == null || _connection!.state != HubConnectionState.Connected) {
      throw Exception("Chat is not connected");
    }
    await _connection!.invoke("SendPoke", args: [squadId, targetUserId]);
  }

  Future<void> sendReaction(String targetUserId, String emoji) async {
    if (_connection == null || _connection!.state != HubConnectionState.Connected) {
      throw Exception("Chat is not connected");
    }
    await _connection!.invoke("SendReaction", args: [squadId, targetUserId, emoji]);
  }

  Future<void> _disconnect() async {
    if (_connection != null) {
      await _connection!.stop();
      _connection = null;
    }
  }
}
