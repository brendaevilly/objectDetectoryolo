import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../config.dart';

Uint8List prepareJpeg(Uint8List source) {
  final decoded = img.decodeImage(source);
  if (decoded == null) {
    throw const FormatException('Não foi possível ler a imagem capturada');
  }

  final resized = decoded.width > AppConfig.maxWidth
      ? img.copyResize(decoded, width: AppConfig.maxWidth)
      : decoded;

  return Uint8List.fromList(
    img.encodeJpg(resized, quality: AppConfig.jpegQuality),
  );
}
