import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../auth/access.dart';
import '../auth/auth_notifier.dart';
import '../catalog/collection_spec.dart';
import '../core/api_exception.dart';
import '../domain/pricing.dart';
import '../models/salon_record.dart';
import '../repositories/salon_api.dart';
import '../state/load_status.dart';
import '../widgets/confirm.dart';
import '../widgets/salon_scaffold.dart';

class RecordDetailsScreen extends StatefulWidget {
  const RecordDetailsScreen({required this.spec, required this.id, super.key});

  final CollectionSpec spec;
  final String id;

  @override
  State<RecordDetailsScreen> createState() => _RecordDetailsScreenState();
}

class _RecordDetailsScreenState extends State<RecordDetailsScreen> {
  LoadStatus _status = LoadStatus.loading;
  String _error = 'Не удалось загрузить данные';
  SalonRecord? _record;
  final Map<String, String> _names = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_status != LoadStatus.loading) {
      setState(() => _status = LoadStatus.loading);
    }
    try {
      final api = context.read<SalonApi>();
      final record = await api.read(widget.spec.collection, widget.id);
      for (final field in widget.spec.fields) {
        final relation = field.relation;
        if (relation == null) {
          continue;
        }
        for (final id in record.ids(field.key)) {
          try {
            final linked = await api.read(relation, id);
            _names['$relation:$id'] = switch (relation) {
              'cars' => linked.text('vin'),
              'customers' => linked.text('fullName'),
              _ => linked.text('name'),
            };
          } on ApiException {
            _names['$relation:$id'] = id;
          }
        }
      }
      _record = record;
      _status = LoadStatus.ready;
    } on ApiException catch (exception) {
      _status = LoadStatus.error;
      _error = exception.message;
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = _auth();
    final role = auth?.role;
    final record = _record;
    return SalonScaffold(
      title: widget.spec.singular,
      body: switch (_status) {
        LoadStatus.loading => const Center(
          child: CircularProgressIndicator(key: Key('catalog-loading')),
        ),
        LoadStatus.error => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error),
              const SizedBox(height: 12),
              FilledButton(onPressed: _load, child: const Text('Повторить')),
            ],
          ),
        ),
        LoadStatus.ready =>
          record == null
              ? const Center(child: Text('Ничего не найдено'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (final field in widget.spec.fields)
                      if (!field.hidden)
                        ListTile(
                          title: Text(field.label),
                          subtitle: Text(
                            _value(field, record),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    Wrap(
                      spacing: 8,
                      children: [
                        if (auth == null || canWrite(role, widget.spec.path))
                          FilledButton(
                            onPressed: () => context.go(
                              '${widget.spec.path}/${widget.id}/edit',
                            ),
                            child: const Text('Изменить'),
                          ),
                        if (role == AppRole.manager ||
                            role == AppRole.director ||
                            widget.spec.lockCustomer)
                          OutlinedButton(
                            onPressed: () => _soft(record.deleted),
                            child: Text(
                              record.deleted ? 'Восстановить' : 'Скрыть',
                            ),
                          ),
                        if (role == AppRole.director)
                          TextButton(
                            onPressed: _hard,
                            child: const Text('Удалить навсегда'),
                          ),
                      ],
                    ),
                  ],
                ),
      },
    );
  }

  String _value(FieldSpec field, SalonRecord record) {
    if (field.kind == FieldKind.multi || field.kind == FieldKind.relation) {
      final ids = record.ids(field.key);
      if (ids.isEmpty) {
        return '—';
      }
      return ids.map((id) => _names['${field.relation}:$id'] ?? id).join(', ');
    }
    if (field.choices.isNotEmpty) {
      final raw = record.text(field.key);
      for (final choice in field.choices) {
        if (choice.value == raw) {
          return choice.label;
        }
      }
    }
    if (field.kind == FieldKind.number &&
        field.key.toLowerCase().contains('price')) {
      return formatMoney(record.integer(field.key));
    }
    final raw = record.text(field.key);
    return raw.isEmpty ? '—' : raw;
  }

  Future<void> _soft(bool deleted) async {
    final accepted = await confirmAction(
      context,
      deleted
          ? 'Вернуть запись в списки?'
          : 'Скрыть запись? Её можно будет восстановить.',
    );
    if (!accepted || !mounted) {
      return;
    }
    final api = context.read<SalonApi>();
    try {
      if (deleted) {
        await api.restore(widget.spec.collection, [widget.id]);
      } else {
        await api.softDelete(widget.spec.collection, [widget.id]);
      }
      await _load();
    } on ApiException catch (exception) {
      if (mounted) {
        setState(() {
          _status = LoadStatus.error;
          _error = exception.message;
        });
      }
    }
  }

  Future<void> _hard() async {
    final accepted = await confirmAction(
      context,
      'Удалить запись без возможности восстановления?',
    );
    if (!accepted || !mounted) {
      return;
    }
    try {
      await context.read<SalonApi>().hardDelete(
        widget.spec.collection,
        widget.id,
      );
      if (mounted) {
        context.go(widget.spec.path);
      }
    } on ConflictException catch (exception) {
      if (mounted) {
        setState(() {
          _status = LoadStatus.error;
          _error = exception.message;
        });
      }
    } on ApiException catch (exception) {
      if (mounted) {
        setState(() {
          _status = LoadStatus.error;
          _error = exception.message;
        });
      }
    }
  }

  AuthNotifier? _auth() {
    try {
      return context.read<AuthNotifier>();
    } on ProviderNotFoundException {
      return null;
    }
  }
}
