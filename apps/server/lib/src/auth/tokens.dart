import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

final _random = Random.secure();

/// Gera um token aleatório de 32 bytes em base64url, sem `=` no final.
String generateToken() {
  final bytes = List<int>.generate(32, (_) => _random.nextInt(256));
  return base64Url.encode(bytes).replaceAll('=', '');
}

/// SHA-256 de [token] em hexadecimal: é o que vai para o banco.
///
/// Como o token tem 256 bits aleatórios, um hash rápido basta (não precisa de
/// bcrypt) e permite buscar a sessão pelo índice.
String hashToken(String token) => sha256.convert(utf8.encode(token)).toString();
