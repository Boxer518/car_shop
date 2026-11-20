import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../catalog/catalog.dart';
import '../core/api_exception.dart';
import '../models/list_query.dart';
import '../models/salon_record.dart';
import '../repositories/salon_api.dart';
import '../state/load_status.dart';
import '../widgets/salon_scaffold.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  LoadStatus _status = LoadStatus.loading;
  String _error = 'Не удалось загрузить данные';
  List<SalonRecord> _users = const [];
  final _roles = <String, String>{};

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
      final page = await context.read<SalonApi>().list(
        'users',
        const ListQuery(size: 50, sort: 'fullName'),
        searchKeys: const ['fullName', 'email'],
        trackDeleted: false,
      );
      _users = page.items;
      _roles
        ..clear()
        ..addEntries(
          page.items.map((user) => MapEntry(user.id, user.text('role'))),
        );
      _status = _users.isEmpty ? LoadStatus.ready : LoadStatus.ready;
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
    return SalonScaffold(
      title: 'Сотрудники',
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
        LoadStatus.ready when _users.isEmpty => const Center(
          child: Text('Ничего не найдено'),
        ),
        LoadStatus.ready => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final user in _users)
              ListTile(
                title: Text(
                  user.text('fullName'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  user.text('email'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: DropdownButton<String>(
                  value: _roles[user.id],
                  items: [
                    for (final choice in roleChoices)
                      DropdownMenuItem(
                        value: choice.value,
                        child: Text(choice.label),
                      ),
                  ],
                  onChanged: (value) => _save(user.id, value),
                ),
              ),
          ],
        ),
      },
    );
  }

  Future<void> _save(String id, String? role) async {
    if (role == null) {
      return;
    }
    setState(() => _roles[id] = role);
    try {
      await context.read<SalonApi>().update('users', id, {'role': role});
    } on ApiException catch (exception) {
      if (mounted) {
        setState(() {
          _status = LoadStatus.error;
          _error = exception.message;
        });
      }
    }
  }
}
