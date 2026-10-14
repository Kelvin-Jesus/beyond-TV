/// Mensagem recebida fora do formato esperado pelo protocolo.
class ProtocolException implements Exception {
  const ProtocolException(this.message);

  final String message;

  @override
  String toString() => 'ProtocolException: $message';
}
