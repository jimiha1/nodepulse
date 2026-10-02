import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stores the CF site credentials and the JWT issued for them in the
/// platform keystore (Android Keystore via flutter_secure_storage).
///
/// The JWT is valid for 7 days and the server has no refresh endpoint, so
/// the "log in once, forever" experience is built here: [token] silently
/// re-logins with the stored credentials whenever the stored token is
/// missing or within an hour of expiring. Sites without stored credentials
/// (public) yield `null` — the public-read path needs no token at all.
class CfCredentials {
  CfCredentials({
    FlutterSecureStorage? storage,
    Future<String> Function(String username, String password)? login,
  }) : _storage = storage ?? FlutterSecureStorage(),
       _login = login;

  static const _kUsername = 'cf_username';
  static const _kPassword = 'cf_password';
  static const _kToken = 'cf_token';
  static const _kTokenExp = 'cf_token_exp';

  /// How long before expiry a token is considered stale enough to refresh.
  static const _refreshAhead = Duration(hours: 1);

  final FlutterSecureStorage _storage;
  final Future<String> Function(String username, String password)? _login;

  /// The stored username/password, remembered permanently so the user only
  /// ever types them once (unless the server-side password changes).
  Future<void> save({
    required String username,
    required String password,
    required String token,
  }) async {
    await _storage.write(key: _kUsername, value: username);
    await _storage.write(key: _kPassword, value: password);
    await saveToken(token);
  }

  /// Persists [token] together with the expiry parsed from its `exp` claim,
  /// which is what schedules the next silent re-login.
  Future<void> saveToken(String token) async {
    await _storage.write(key: _kToken, value: token);
    final exp = expiryOf(token);
    final raw = exp == null
        ? null
        : (exp.millisecondsSinceEpoch ~/ 1000).toString();
    if (raw == null) {
      await _storage.delete(key: _kTokenExp);
    } else {
      await _storage.write(key: _kTokenExp, value: raw);
    }
  }

  /// A token to read with: the stored one while it still has more than an
  /// hour to live, else a fresh one from a silent re-login.
  ///
  /// Returns `null` when there is nothing to authenticate with — the public
  /// site path — or when a refresh is due but the credentials or the login
  /// seam are missing.
  Future<String?> token() async {
    final token = await _storage.read(key: _kToken);
    final exp = await _exp();
    if (token != null &&
        token.isNotEmpty &&
        exp != null &&
        DateTime.now().add(_refreshAhead).isBefore(exp)) {
      return token;
    }
    final username = await _storage.read(key: _kUsername);
    final password = await _storage.read(key: _kPassword);
    final login = _login;
    if (username == null ||
        username.isEmpty ||
        password == null ||
        password.isEmpty ||
        login == null) {
      return null;
    }
    final fresh = await login(username, password);
    await saveToken(fresh);
    return fresh;
  }

  /// Forgets everything, for the "log out / re-enter credentials" flow.
  Future<void> clear() async {
    await _storage.deleteAll();
  }

  Future<DateTime?> _exp() async {
    final raw = await _storage.read(key: _kTokenExp);
    final seconds = raw == null ? null : int.tryParse(raw);
    return seconds == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
  }

  /// Reads `exp` (unix seconds) from a JWT payload without verifying the
  /// signature: the token came straight from the server over HTTPS, the read
  /// only schedules the next silent re-login. `null` when unreadable.
  static DateTime? expiryOf(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    try {
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      final exp = payload is Map ? payload['exp'] : null;
      return exp is num
          ? DateTime.fromMillisecondsSinceEpoch((exp * 1000).round())
          : null;
    } on FormatException {
      return null;
    }
  }
}
