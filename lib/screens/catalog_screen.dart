import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../auth/access.dart';
import '../auth/auth_notifier.dart';
import '../catalog/collection_spec.dart';
import '../core/api_exception.dart';
import '../models/list_query.dart';
import '../repositories/salon_api.dart';
import '../state/catalog_controller.dart';
import '../widgets/catalog_view.dart';
import '../widgets/confirm.dart';
import '../widgets/salon_scaffold.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({required this.spec, required this.query, super.key});

  final CollectionSpec spec;
  final ListQuery query;

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  late final TextEditingController _search;
  late CatalogController _controller;
  final Set<String> _selected = {};
  String? _actionError;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(text: widget.query.search);
    _controller = _build();
    _controller.load(silent: true);
  }

  @override
  void didUpdateWidget(CatalogScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final changed =
        oldWidget.spec.path != widget.spec.path ||
        oldWidget.query.toParameters().toString() !=
            widget.query.toParameters().toString();
    if (!changed) {
      return;
    }
    _search.text = widget.query.search;
    _selected.clear();
    _controller.dispose();
    _controller = _build();
    _controller.load(silent: true);
  }

  @override
  void dispose() {
    _search.dispose();
    _controller.dispose();
    super.dispose();
  }

  CatalogController _build() {
    final auth = _maybeAuth();
    final locked = <String, String>{};
    if (widget.spec.lockCustomer && auth?.user?.customerId.isNotEmpty == true) {
      locked['customer'] = auth!.user!.customerId;
    }
    return CatalogController(
      api: context.read<SalonApi>(),
      spec: widget.spec,
      query: widget.query,
      locked: locked,
    )..addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = _maybeAuth();
    final role = auth?.role;
    final staff = role == AppRole.manager || role == AppRole.director;
    final columns = [
      for (final key in widget.spec.columns)
        (key, widget.spec.field(key)?.label ?? key),
    ];
    return SalonScaffold(
      title: widget.spec.title,
      body: CatalogView(
        status: _controller.status,
        error: _actionError ?? _controller.error,
        onRetry: () {
          _actionError = null;
          _controller.load();
        },
        columns: columns,
        items: [for (final row in _controller.page.items) row.id],
        cell: (id, column) {
          final row = _controller.page.items
              .where((item) => item.id == id)
              .first;
          return _controller.label(column, row);
        },
        canCreate: auth == null || canWrite(role, widget.spec.path),
        onCreate: () => context.go('${widget.spec.path}/new${_suffix()}'),
        onOpen: (id) => context.go('${widget.spec.path}/$id${_suffix()}'),
        selected: _selected,
        onToggle: staff || widget.spec.lockCustomer
            ? (id) => setState(() {
                if (!_selected.add(id)) {
                  _selected.remove(id);
                }
              })
            : null,
        header: _filters(staff),
        footer: _footer(staff),
      ),
    );
  }

  Widget _filters(bool staff) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 220,
            child: TextField(
              controller: _search,
              decoration: const InputDecoration(
                labelText: 'Поиск',
                isDense: true,
              ),
              onSubmitted: (value) =>
                  _open(widget.query.copyWith(search: value.trim(), page: 1)),
            ),
          ),
          FilledButton.tonal(
            onPressed: () => _open(
              widget.query.copyWith(search: _search.text.trim(), page: 1),
            ),
            child: const Text('Найти'),
          ),
          for (final filter in widget.spec.filters) _filterField(filter),
          DropdownButton<String>(
            value: widget.query.sort,
            items: [
              for (final sort in widget.spec.sorts)
                DropdownMenuItem(value: sort.value, child: Text(sort.label)),
            ],
            onChanged: (value) {
              if (value != null) {
                _open(widget.query.copyWith(sort: value, page: 1));
              }
            },
          ),
          IconButton(
            tooltip: widget.query.descending ? 'По убыванию' : 'По возрастанию',
            onPressed: () => _open(
              widget.query.copyWith(
                descending: !widget.query.descending,
                page: 1,
              ),
            ),
            icon: Icon(
              widget.query.descending
                  ? Icons.arrow_downward
                  : Icons.arrow_upward,
            ),
          ),
          DropdownButton<int>(
            value: widget.query.size,
            items: const [
              DropdownMenuItem(value: 10, child: Text('10')),
              DropdownMenuItem(value: 25, child: Text('25')),
              DropdownMenuItem(value: 50, child: Text('50')),
            ],
            onChanged: (value) {
              if (value != null) {
                _open(widget.query.copyWith(size: value, page: 1));
              }
            },
          ),
          if (staff)
            FilterChip(
              label: const Text('Удалённые'),
              selected: widget.query.includeDeleted,
              onSelected: (value) =>
                  _open(widget.query.copyWith(includeDeleted: value, page: 1)),
            ),
        ],
      ),
    );
  }

  Widget _filterField(FilterSpec filter) {
    final current = widget.query.filters[filter.key] ?? '';
    if (filter.choices.isNotEmpty || filter.relation != null) {
      final options = filter.choices.isNotEmpty
          ? filter.choices
          : [
              for (final entry in _controller.names.entries)
                if (entry.key.startsWith('${filter.relation}:'))
                  Choice(entry.key.split(':').last, entry.value),
            ];
      return DropdownButton<String>(
        hint: Text(filter.label),
        value: current.isEmpty ? null : current,
        items: [
          DropdownMenuItem(value: '', child: Text(filter.label)),
          for (final option in options)
            DropdownMenuItem(value: option.value, child: Text(option.label)),
        ],
        onChanged: (value) {
          final next = Map<String, String>.from(widget.query.filters);
          if (value == null || value.isEmpty) {
            next.remove(filter.key);
          } else {
            next[filter.key] = value;
          }
          _open(widget.query.copyWith(filters: next, page: 1));
        },
      );
    }
    return SizedBox(
      width: 160,
      child: TextFormField(
        key: ValueKey('${widget.spec.path}-${filter.key}-$current'),
        initialValue: current,
        decoration: InputDecoration(labelText: filter.label, isDense: true),
        onFieldSubmitted: (value) {
          final next = Map<String, String>.from(widget.query.filters);
          if (value.trim().isEmpty) {
            next.remove(filter.key);
          } else {
            next[filter.key] = value.trim();
          }
          _open(widget.query.copyWith(filters: next, page: 1));
        },
      ),
    );
  }

  Widget _footer(bool staff) {
    final page = _controller.page;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('Стр. ${page.page} из ${page.totalPages}, всего ${page.total}'),
          OutlinedButton(
            onPressed: page.hasPrevious
                ? () => _open(widget.query.copyWith(page: page.page - 1))
                : null,
            child: const Text('Назад'),
          ),
          OutlinedButton(
            onPressed: page.hasNext
                ? () => _open(widget.query.copyWith(page: page.page + 1))
                : null,
            child: const Text('Дальше'),
          ),
          if (_selected.isNotEmpty && (staff || widget.spec.lockCustomer))
            TextButton(
              onPressed: _softDelete,
              child: Text('Удалить выбранные (${_selected.length})'),
            ),
          if (_selected.isNotEmpty && staff && widget.query.includeDeleted)
            TextButton(onPressed: _restore, child: const Text('Восстановить')),
        ],
      ),
    );
  }

  Future<void> _softDelete() async {
    final accepted = await confirmAction(
      context,
      'Скрыть выбранные записи? Их можно восстановить.',
    );
    if (!accepted || !mounted) {
      return;
    }
    await _run(
      () => context.read<SalonApi>().softDelete(
        widget.spec.collection,
        _selected.toList(),
      ),
    );
  }

  Future<void> _restore() async {
    await _run(
      () => context.read<SalonApi>().restore(
        widget.spec.collection,
        _selected.toList(),
      ),
    );
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
      _selected.clear();
      _actionError = null;
      await _controller.load();
    } on ApiException catch (exception) {
      if (mounted) {
        setState(() => _actionError = exception.message);
      }
    }
  }

  void _open(ListQuery next) {
    final location = Uri(
      path: widget.spec.path,
      queryParameters: next.toParameters(),
    ).toString();
    context.go(location);
  }

  String _suffix() {
    final parameters = widget.query.toParameters();
    if (parameters.isEmpty) {
      return '';
    }
    return '?${Uri(queryParameters: parameters).query}';
  }

  AuthNotifier? _maybeAuth() {
    try {
      return context.read<AuthNotifier>();
    } on ProviderNotFoundException {
      return null;
    }
  }
}
