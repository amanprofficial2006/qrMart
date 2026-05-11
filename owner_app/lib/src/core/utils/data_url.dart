import 'dart:convert';
import 'dart:typed_data';

Uint8List? decodeDataUrl(String value) {
  if (!value.startsWith('data:')) {
    return null;
  }

  final commaIndex = value.indexOf(',');

  if (commaIndex < 0 || commaIndex >= value.length - 1) {
    return null;
  }

  try {
    return base64Decode(value.substring(commaIndex + 1));
  } catch (_) {
    return null;
  }
}

