import '../auth/access.dart';

int automaticPercent(int year, int mileage, {DateTime? now}) {
  final current = (now ?? DateTime.now()).toUtc().year;
  var percent = 0;
  if (mileage >= 100000) {
    percent += 5;
  }
  if (current - year >= 5) {
    percent += 3;
  }
  return percent;
}

int roleCap(AppRole role) => role == AppRole.director ? 25 : 15;

int totalDiscount({
  required int automatic,
  required int manual,
  required int cap,
}) {
  final sum = automatic + manual;
  final bounded = sum < 0 ? 0 : sum;
  return bounded > cap ? cap : bounded;
}

int finalPrice({
  required int base,
  required int optionsTotal,
  required int automatic,
  required int manual,
  required int cap,
}) {
  final total = totalDiscount(automatic: automatic, manual: manual, cap: cap);
  return (((base + optionsTotal) * (100 - total)) / 100).round();
}

String formatMoney(int value) {
  final negative = value < 0;
  final digits = (negative ? -value : value).toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) {
      buffer.write(' ');
    }
    buffer.write(digits[index]);
  }
  return '${negative ? '-' : ''}$buffer ₽';
}
