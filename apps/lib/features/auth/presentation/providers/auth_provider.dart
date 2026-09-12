import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_provider.g.dart';

const _storage = FlutterSecureStorage();
const _tokenKey = 'jwt_token';

@riverpod
class Auth extends _$Auth {
  @override
  Future<String?> build() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> login(String token) async {
    await _storage.write(key: _tokenKey, value: token);
    state = AsyncData(token);
  }

  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    state = const AsyncData(null);
  }
}
