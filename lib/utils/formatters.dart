import 'package:intl/intl.dart';

import '../config/app_config.dart';

const _arabicMonths = <String, int>{
  'يناير': 1,
  'فبراير': 2,
  'مارس': 3,
  'أبريل': 4,
  'مايو': 5,
  'يونيو': 6,
  'يوليو': 7,
  'أغسطس': 8,
  'سبتمبر': 9,
  'أكتوبر': 10,
  'نوفمبر': 11,
  'ديسمبر': 12,
};

String _monthName(int month) {
  return _arabicMonths.entries
      .firstWhere(
        (entry) => entry.value == month,
        orElse: () => const MapEntry('', 0),
      )
      .key;
}

String formatDate(DateTime date, {bool withTime = false}) {
  final local = date.toLocal();
  final day = local.day;
  final month = _monthName(local.month);
  final year = local.year;
  if (!withTime) return '$day $month $year';
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day $month $year - $hour:$minute';
}

String timeAgo(DateTime date) {
  final difference = DateTime.now().difference(date.toLocal());
  if (difference.inSeconds < 60) return 'الآن';
  if (difference.inMinutes < 60) return 'منذ ${difference.inMinutes} دقيقة';
  if (difference.inHours < 24) return 'منذ ${difference.inHours} ساعة';
  if (difference.inDays < 7) return 'منذ ${difference.inDays} يوم';
  return formatDate(date, withTime: true);
}

final NumberFormat _numberFormat = NumberFormat('#,##0.###');

String formatPrice(num price) {
  return '${_numberFormat.format(price)} ${AppConfig.currency}';
}