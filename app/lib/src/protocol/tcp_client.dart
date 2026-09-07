// ignore_for_file: unused_import

import 'dart:io';
import 'dart:typed_data';

class TcpClient {
  Future<String> sendImage({
    required String host,
    required int port,
    required Uint8List jpeg,
  }) async {
    // TODO: Socket.connect + 4 bytes (tamanho) + JPEG; ler resposta
    throw UnimplementedError();
  }
}
