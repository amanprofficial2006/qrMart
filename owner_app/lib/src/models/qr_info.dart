import '../core/utils/json_utils.dart';

class QrInfo {
  const QrInfo({
    required this.qrUrl,
    required this.qrDataUrl,
  });

  final String qrUrl;
  final String qrDataUrl;

  factory QrInfo.fromJson(Map<String, dynamic> json) {
    return QrInfo(
      qrUrl: stringFrom(json['qrUrl']),
      qrDataUrl: stringFrom(json['qrDataUrl']),
    );
  }
}

