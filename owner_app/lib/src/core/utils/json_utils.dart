DateTime? dateTimeFrom(dynamic value) {
  final text = stringFrom(value);

  if (text.isEmpty) {
    return null;
  }

  return DateTime.tryParse(text);
}

double doubleFrom(dynamic value, {double fallback = 0}) {
  if (value is num) {
    return value.toDouble();
  }

  final parsed = double.tryParse(stringFrom(value));
  return parsed ?? fallback;
}

bool boolFrom(dynamic value, {bool fallback = false}) {
  if (value is bool) {
    return value;
  }

  final normalized = stringFrom(value).trim().toLowerCase();

  if (normalized == 'true') {
    return true;
  }

  if (normalized == 'false') {
    return false;
  }

  return fallback;
}

Map<String, dynamic> mapFrom(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }

  return const <String, dynamic>{};
}

List<Map<String, dynamic>> mapListFrom(dynamic value) {
  if (value is! List) {
    return const <Map<String, dynamic>>[];
  }

  return value.map((item) => mapFrom(item)).toList(growable: false);
}

String stringFrom(dynamic value, {String fallback = ''}) {
  if (value == null) {
    return fallback;
  }

  final text = value.toString();
  return text == 'null' ? fallback : text;
}

