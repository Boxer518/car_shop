class DriveInterval {
  const DriveInterval({
    required this.start,
    required this.end,
    this.id = '',
    this.status = 'planned',
    this.deleted = false,
  });

  final DateTime start;
  final DateTime end;
  final String id;
  final String status;
  final bool deleted;
}

String? driveError({
  required DateTime? start,
  required DateTime? end,
  required List<DriveInterval> existing,
  String? selfId,
}) {
  if (start == null || end == null || !end.isAfter(start)) {
    return 'Окончание должно быть позже начала';
  }
  final minutes = end.difference(start).inMinutes;
  if (minutes < 30 || minutes > 180) {
    return 'Тест-драйв длится от 30 минут до 3 часов';
  }
  for (final other in existing) {
    if (other.deleted || other.status == 'cancelled' || other.id == selfId) {
      continue;
    }
    if (start.isBefore(other.end) && other.start.isBefore(end)) {
      return 'Автомобиль уже занят в этот интервал';
    }
  }
  return null;
}

DateTime? parseSalonDate(String raw) {
  final value = raw.trim();
  if (value.isEmpty) {
    return null;
  }
  return DateTime.tryParse(value.replaceFirst(' ', 'T'));
}

String formatSalonDate(DateTime value) {
  final utc = value.toUtc();
  String two(int number) => number.toString().padLeft(2, '0');
  final date = '${utc.year}-${two(utc.month)}-${two(utc.day)}';
  final time = '${two(utc.hour)}:${two(utc.minute)}:${two(utc.second)}';
  return '$date $time.000Z';
}
