enum FieldKind {
  text,
  longText,
  number,
  email,
  phone,
  vin,
  date,
  dateTime,
  select,
  relation,
  multi,
}

enum FilterKind { contains, equals, min, max, relation }

class Choice {
  const Choice(this.value, this.label);

  final String value;
  final String label;
}

class FieldSpec {
  const FieldSpec({
    required this.key,
    required this.label,
    required this.kind,
    this.required = false,
    this.minLength,
    this.maxLength,
    this.min,
    this.max,
    this.choices = const [],
    this.relation,
    this.computed = false,
    this.hidden = false,
  });

  final String key;
  final String label;
  final FieldKind kind;
  final bool required;
  final int? minLength;
  final int? maxLength;
  final int? min;
  final int? max;
  final List<Choice> choices;
  final String? relation;
  final bool computed;
  final bool hidden;
}

class FilterSpec {
  const FilterSpec({
    required this.key,
    required this.label,
    required this.kind,
    required this.field,
    this.choices = const [],
    this.relation,
  });

  final String key;
  final String label;
  final FilterKind kind;
  final String field;
  final List<Choice> choices;
  final String? relation;

  bool matches(Map<String, dynamic> row, String raw) {
    final value = row[field];
    return switch (kind) {
      FilterKind.contains => '$value'.toLowerCase().contains(raw.toLowerCase()),
      FilterKind.equals => '$value' == raw,
      FilterKind.relation =>
        '$value' == raw ||
            (value is List && value.map((item) => '$item').contains(raw)),
      FilterKind.min => _asInt(value) >= (int.tryParse(raw) ?? 1 << 30),
      FilterKind.max => _asInt(value) <= (int.tryParse(raw) ?? -1),
    };
  }

  String toPocketBase(String raw) {
    final safe = raw.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
    return switch (kind) {
      FilterKind.contains => '$field ~ "$safe"',
      FilterKind.equals || FilterKind.relation => '$field = "$safe"',
      FilterKind.min => '$field >= ${int.tryParse(raw) ?? 0}',
      FilterKind.max => '$field <= ${int.tryParse(raw) ?? 0}',
    };
  }
}

int _asInt(dynamic value) {
  if (value is num) {
    return value.round();
  }
  return int.tryParse('$value') ?? 0;
}

class CollectionSpec {
  const CollectionSpec({
    required this.collection,
    required this.path,
    required this.title,
    required this.singular,
    required this.fields,
    required this.columns,
    required this.filters,
    required this.searchKeys,
    required this.sorts,
    required this.defaultSort,
    this.lockCustomer = false,
    this.deal = false,
    this.drive = false,
  });

  final String collection;
  final String path;
  final String title;
  final String singular;
  final List<FieldSpec> fields;
  final List<String> columns;
  final List<FilterSpec> filters;
  final List<String> searchKeys;
  final List<Choice> sorts;
  final String defaultSort;
  final bool lockCustomer;
  final bool deal;
  final bool drive;

  FieldSpec? field(String key) {
    for (final item in fields) {
      if (item.key == key) {
        return item;
      }
    }
    return null;
  }
}
