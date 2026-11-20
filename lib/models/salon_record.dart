class SalonRecord {
  SalonRecord(Map<String, dynamic> source)
    : data = Map<String, dynamic>.from(source);

  final Map<String, dynamic> data;

  String get id => '${data['id'] ?? ''}';

  bool get deleted => data['deleted'] == true;

  String text(String key) => data[key]?.toString() ?? '';

  int integer(String key) {
    final value = data[key];
    if (value is num) {
      return value.round();
    }
    return int.tryParse('$value') ?? 0;
  }

  List<String> ids(String key) {
    final value = data[key];
    if (value is List) {
      return value
          .map((item) => '$item')
          .where((item) => item.isNotEmpty)
          .toList();
    }
    if (value == null || '$value'.isEmpty) {
      return const [];
    }
    return ['$value'];
  }
}
