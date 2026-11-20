import 'package:flutter/foundation.dart';

import '../catalog/collection_spec.dart';
import '../core/api_exception.dart';
import '../models/list_query.dart';
import '../models/page_result.dart';
import '../models/salon_record.dart';
import '../repositories/salon_api.dart';
import '../state/load_status.dart';

class CatalogController extends ChangeNotifier {
  CatalogController({
    required this.api,
    required this.spec,
    required this.query,
    this.locked = const {},
  });

  final SalonApi api;
  final CollectionSpec spec;
  ListQuery query;
  final Map<String, String> locked;

  LoadStatus status = LoadStatus.loading;
  String error = 'Не удалось загрузить данные';
  PageResult<SalonRecord> page = PageResult<SalonRecord>.empty();
  final Map<String, String> names = {};

  Future<void> load({bool silent = false}) async {
    status = LoadStatus.loading;
    if (!silent) {
      notifyListeners();
    }
    try {
      page = await api.list(
        spec.collection,
        query,
        searchKeys: spec.searchKeys,
        filters: spec.filters,
        locked: locked,
      );
      await _names();
      status = LoadStatus.ready;
    } on ApiException catch (exception) {
      status = LoadStatus.error;
      error = exception.message.isEmpty
          ? 'Не удалось загрузить данные'
          : exception.message;
    }
    notifyListeners();
  }

  String label(String key, SalonRecord record) {
    final field = spec.field(key);
    final raw = record.text(key);
    if (field?.choices.isNotEmpty == true) {
      for (final choice in field!.choices) {
        if (choice.value == raw) {
          return choice.label;
        }
      }
    }
    if (field?.kind == FieldKind.relation) {
      return names['${field!.relation}:$raw'] ?? raw;
    }
    if (field?.kind == FieldKind.multi) {
      final ids = record.ids(key);
      if (ids.isEmpty) {
        return '—';
      }
      return ids.map((id) => names['${field!.relation}:$id'] ?? id).join(', ');
    }
    if (field?.kind == FieldKind.number &&
        key.toLowerCase().contains('price')) {
      return raw;
    }
    return raw.isEmpty ? '—' : raw;
  }

  Future<void> _names() async {
    final relations = <String>{
      for (final field in spec.fields)
        if (field.relation != null) field.relation!,
      for (final filter in spec.filters)
        if (filter.relation != null) filter.relation!,
    };
    for (final collection in relations) {
      final listed = await api.list(
        collection,
        const ListQuery(size: 50, sort: 'id'),
        searchKeys: const [],
        filters: const [],
      );
      for (final row in listed.items) {
        names['$collection:${row.id}'] = _title(collection, row);
      }
    }
  }

  String _title(String collection, SalonRecord row) {
    return switch (collection) {
      'cars' => row.text('vin'),
      'customers' => row.text('fullName'),
      'passports' => row.text('number'),
      'users' => row.text('fullName'),
      _ => row.text('name').isEmpty ? row.id : row.text('name'),
    };
  }
}
