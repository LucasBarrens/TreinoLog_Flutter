import 'package:intl/intl.dart';

class FormattingUtil {
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _timeFormat = DateFormat('HH:mm');

  static String formatWeight(double weight) {
    if (weight == 0) return '0';
    if (weight == weight.toInt()) {
      return weight.toInt().toString();
    }
    return weight
        .toStringAsFixed(2)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  static double parseWeight(String text) {
    final sanitized = text.replaceAll(',', '.');
    return double.tryParse(sanitized) ?? 0;
  }

  static String formatDate(DateTime date) {
    return _dateFormat.format(date);
  }

  static String formatTime(DateTime date) {
    return _timeFormat.format(date);
  }
}
