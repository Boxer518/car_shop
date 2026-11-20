import '../auth/access.dart';
import '../catalog/collection_spec.dart';
import '../domain/pricing.dart';
import '../domain/schedule.dart';

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
final _phonePattern = RegExp(r'^\+?[0-9]{10,15}$');
final _vinPattern = RegExp(r'^[A-HJ-NPR-Z0-9]{17}$');
final _datePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');

String? validateField(
  FieldSpec field,
  String raw, {
  AppRole? role,
  DateTime? otherDate,
  bool otherIsStart = false,
}) {
  final value = raw.trim();
  if (field.computed) {
    return null;
  }
  if (field.required && value.isEmpty) {
    return 'Заполните поле «${field.label}»';
  }
  if (value.isEmpty) {
    return null;
  }
  if (field.minLength != null && value.length < field.minLength!) {
    return 'Минимум ${field.minLength} символов';
  }
  if (field.maxLength != null && value.length > field.maxLength!) {
    return 'Максимум ${field.maxLength} символов';
  }
  return switch (field.kind) {
    FieldKind.email =>
      _emailPattern.hasMatch(value) ? null : 'Некорректный email',
    FieldKind.phone =>
      _phonePattern.hasMatch(value) ? null : 'Телефон: от 10 цифр, можно с +',
    FieldKind.vin =>
      _vinPattern.hasMatch(value.toUpperCase())
          ? null
          : 'VIN состоит из 17 символов без I, O и Q',
    FieldKind.number => _number(field, value, role),
    FieldKind.date =>
      _datePattern.hasMatch(value) && parseSalonDate(value) != null
          ? null
          : 'Дата в формате ГГГГ-ММ-ДД',
    FieldKind.dateTime => _dateTime(value, otherDate, otherIsStart),
    FieldKind.text ||
    FieldKind.longText ||
    FieldKind.select ||
    FieldKind.relation ||
    FieldKind.multi => null,
  };
}

String? _number(FieldSpec field, String value, AppRole? role) {
  final number = int.tryParse(value);
  if (number == null) {
    return 'Укажите целое число';
  }
  if (field.key == 'discountPercent' && role != null) {
    final cap = roleCap(role);
    if (number < 0 || number > cap) {
      return 'Скидка для этой роли не больше $cap%';
    }
    return null;
  }
  if (field.min != null && number < field.min!) {
    return 'Минимум ${field.min}';
  }
  if (field.max != null && number > field.max!) {
    return 'Максимум ${field.max}';
  }
  return null;
}

String? _dateTime(String value, DateTime? other, bool otherIsStart) {
  final parsed = parseSalonDate(value);
  if (parsed == null) {
    return 'Дата и время: ГГГГ-ММ-ДД ЧЧ:ММ';
  }
  if (other == null) {
    return null;
  }
  final start = otherIsStart ? other : parsed;
  final end = otherIsStart ? parsed : other;
  return driveError(start: start, end: end, existing: const []);
}

String? validatePassword(String value, {String? confirm}) {
  if (value.length < 8 || value.length > 72) {
    return 'Пароль от 8 до 72 символов';
  }
  if (confirm != null && confirm != value) {
    return 'Пароли не совпадают';
  }
  return null;
}
