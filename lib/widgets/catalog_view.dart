import 'package:material_ui/material_ui.dart';

import '../state/load_status.dart';

class CatalogView extends StatelessWidget {
  const CatalogView({
    required this.status,
    required this.columns,
    required this.items,
    required this.cell,
    this.error = 'Не удалось загрузить данные',
    this.onRetry,
    this.canCreate = false,
    this.onCreate,
    this.header,
    this.footer,
    this.selected = const {},
    this.onToggle,
    this.onOpen,
    super.key,
  });

  final LoadStatus status;
  final List<(String, String)> columns;
  final List<String> items;
  final String Function(String id, String column) cell;
  final String error;
  final VoidCallback? onRetry;
  final bool canCreate;
  final VoidCallback? onCreate;
  final Widget? header;
  final Widget? footer;
  final Set<String> selected;
  final ValueChanged<String>? onToggle;
  final ValueChanged<String>? onOpen;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 1280;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ?header,
        if (canCreate)
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: FilledButton.icon(
                key: const Key('add-record'),
                onPressed: onCreate,
                icon: const Icon(Icons.add),
                label: const Text('Добавить'),
              ),
            ),
          ),
        Expanded(child: _body(context, wide)),
        ?footer,
      ],
    );
  }

  Widget _body(BuildContext context, bool wide) {
    return switch (status) {
      LoadStatus.loading => const _StatusPane(
        child: CircularProgressIndicator(key: Key('catalog-loading')),
      ),
      LoadStatus.error => _StatusPane(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Повторить')),
          ],
        ),
      ),
      LoadStatus.ready when items.isEmpty => const _StatusPane(
        child: Text('Ничего не найдено'),
      ),
      LoadStatus.ready when wide => _table(context),
      LoadStatus.ready => _cards(context),
    };
  }

  Widget _table(BuildContext context) {
    return Scrollbar(
      child: SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: [
              if (onToggle != null) const DataColumn(label: Text('')),
              for (final column in columns) DataColumn(label: Text(column.$2)),
            ],
            rows: [
              for (final id in items)
                DataRow(
                  selected: selected.contains(id),
                  onSelectChanged: onToggle == null
                      ? null
                      : (_) => onToggle!(id),
                  cells: [
                    if (onToggle != null)
                      DataCell(
                        Checkbox(
                          value: selected.contains(id),
                          onChanged: (_) => onToggle!(id),
                        ),
                      ),
                    for (final column in columns)
                      DataCell(
                        Text(
                          cell(id, column.$1),
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: onOpen == null ? null : () => onOpen!(id),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cards(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final columnsCount = width < 768 ? 1 : 2;
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columnsCount,
        mainAxisExtent: 220,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final id = items[index];
        return Card(
          child: InkWell(
            onTap: onOpen == null ? null : () => onOpen!(id),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (onToggle != null)
                    Checkbox(
                      value: selected.contains(id),
                      onChanged: (_) => onToggle!(id),
                    ),
                  for (final column in columns)
                    Text(
                      '${column.$2}: ${cell(id, column.$1)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatusPane extends StatelessWidget {
  const _StatusPane({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(child: child),
          ),
        );
      },
    );
  }
}
