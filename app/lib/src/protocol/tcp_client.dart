import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../config.dart';

class DetectionResult {
  const DetectionResult({
    required this.detected,
    required this.labels,
    required this.message,
  });

  final bool detected;
  final List<String> labels;
  final String message;

  factory DetectionResult.fromJson(Map<String, dynamic> json) {
    final labels = List<String>.from(json['labels'] ?? const []);
    final message = (json['message'] as String?) ?? 'Nada Detectado';
    return DetectionResult(
      detected: json['detected'] == true || labels.isNotEmpty,
      labels: labels.isNotEmpty
          ? labels
          : message
              .split('\n')
              .where((line) => line.trim().isNotEmpty)
              .toList(),
      message: message,
    );
  }

  factory DetectionResult.fromPayload(Uint8List bytes) {
    final text = utf8.decode(bytes).trim();
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) {
        return DetectionResult.fromJson(decoded);
      }
      if (decoded is Map) {
        return DetectionResult.fromJson(Map<String, dynamic>.from(decoded));
      }
    } on FormatException {
      // resposta em texto simples
    }

    if (text.isEmpty || text == 'Nada Detectado') {
      return const DetectionResult(
        detected: false,
        labels: ['Nada Detectado'],
        message: 'Nada Detectado',
      );
    }

    final lines = text
        .split(RegExp(r'\r?\n'))
        .where((line) => line.trim().isNotEmpty)
        .toList();
    return DetectionResult(detected: true, labels: lines, message: text);
  }
}

class TcpClient {
  Future<DetectionResult> sendImage({
    required String host,
    required int port,
    required Uint8List jpeg,
  }) async {
    final socket = await Socket.connect(
      host,
      port,
      timeout: AppConfig.connectTimeout,
    );

    try {
      socket.add(_pack(jpeg));
      await socket.flush();
      final responseBytes = await _readMessage(socket).timeout(
        AppConfig.responseTimeout,
      );
      return DetectionResult.fromPayload(responseBytes);
    } finally {
      await socket.close();
    }
  }

  Uint8List _pack(Uint8List payload) {
    final header = ByteData(4)..setUint32(0, payload.length, Endian.big);
    return Uint8List.fromList([...header.buffer.asUint8List(), ...payload]);
  }

  Future<Uint8List> _readMessage(Socket socket) async {
    final chunks = <int>[];
    await for (final data in socket) {
      chunks.addAll(data);
      if (chunks.length >= 4) {
        final size = ByteData.sublistView(
          Uint8List.fromList(chunks.take(4).toList()),
        ).getUint32(0, Endian.big);
        if (size <= 0) {
          throw const SocketException('Tamanho de resposta inválido');
        }
        if (chunks.length >= 4 + size) {
          return Uint8List.fromList(chunks.sublist(4, 4 + size));
        }
      }
    }
    throw const SocketException('Resposta incompleta do servidor');
  }
}
