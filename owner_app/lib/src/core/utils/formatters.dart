import 'package:intl/intl.dart';

final NumberFormat _currencyFormat = NumberFormat.currency(
  locale: 'en_IN',
  symbol: 'Rs. ',
  decimalDigits: 0,
);

final DateFormat _dateFormat = DateFormat('d MMM, h:mm a');

String formatCurrency(num? value) => _currencyFormat.format(value ?? 0);

String formatDateTime(DateTime? value) {
  if (value == null) {
    return '--';
  }

  return _dateFormat.format(value.toLocal());
}

String statusLabel(String value) {
  if (value.isEmpty) {
    return 'Unknown';
  }

  return value[0].toUpperCase() + value.substring(1);
}

