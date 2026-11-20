import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../auth/access.dart';
import '../auth/auth_notifier.dart';

class SalonScaffold extends StatelessWidget {
  const SalonScaffold({
    required this.title,
    required this.body,
    this.floatingActionButton,
    super.key,
  });

  final String title;
  final Widget body;
  final Widget? floatingActionButton;

  static const _sections = <(String, String, IconData)>[
    ('/', 'Главная', Icons.home_outlined),
    ('/cars', 'Автомобили', Icons.directions_car_outlined),
    ('/brands', 'Марки', Icons.factory_outlined),
    ('/models', 'Модели', Icons.account_tree_outlined),
    ('/options', 'Опции', Icons.tune),
    ('/customers', 'Клиенты', Icons.people_outline),
    ('/passports', 'ПТС', Icons.article_outlined),
    ('/deals', 'Сделки', Icons.handshake_outlined),
    ('/drives', 'Тест-драйвы', Icons.schedule),
    ('/my-drives', 'Мои записи', Icons.event_available),
    ('/admin/report', 'Отчёт', Icons.bar_chart),
    ('/admin/users', 'Сотрудники', Icons.admin_panel_settings_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = _auth(context);
    final role = auth?.role;
    final sections = role == null
        ? _sections
        : _sections.where((item) => roleAllows(role, item.$1)).toList();
    final path = GoRouter.of(context).routeInformationProvider.value.uri.path;
    final current = _current(path, sections);
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 768;
    final expanded = width >= 1280;
    final page = Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: width >= 1920 ? 1200 : double.infinity,
        ),
        child: body,
      ),
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          if (auth?.user != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: Text(
                  '${auth!.user!.displayName} · ${roleLabel(auth.user!.role)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          if (auth?.user != null)
            TextButton(
              onPressed: () => context.read<AuthNotifier>().logout(),
              child: const Text('Выйти'),
            ),
        ],
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: compact ? _bottom(context, sections, current) : null,
      body: compact
          ? page
          : Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _side(context, sections, current, expanded),
                const VerticalDivider(width: 1),
                Expanded(child: page),
              ],
            ),
    );
  }

  Widget _side(
    BuildContext context,
    List<(String, String, IconData)> sections,
    String current,
    bool expanded,
  ) {
    return SizedBox(
      width: expanded ? 240 : 72,
      child: ListView(
        children: [
          for (final item in sections)
            expanded
                ? ListTile(
                    selected: item.$1 == current,
                    leading: Icon(item.$3),
                    title: Text(
                      item.$2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => context.go(item.$1),
                  )
                : IconButton(
                    tooltip: item.$2,
                    isSelected: item.$1 == current,
                    onPressed: () => context.go(item.$1),
                    icon: Icon(item.$3),
                  ),
        ],
      ),
    );
  }

  Widget _bottom(
    BuildContext context,
    List<(String, String, IconData)> sections,
    String current,
  ) {
    final overflow = sections.length > 4;
    final visible = overflow ? sections.take(3).toList() : sections;
    final hidden = overflow
        ? sections.skip(3).toList()
        : const <(String, String, IconData)>[];
    final hiddenSelected = hidden.any((item) => item.$1 == current);
    return NavigationBar(
      selectedIndex: hiddenSelected ? visible.length : _index(visible, current),
      onDestinationSelected: (index) async {
        if (overflow && index == visible.length) {
          final selected = await showModalBottomSheet<String>(
            context: context,
            showDragHandle: true,
            constraints: const BoxConstraints(maxWidth: 480),
            builder: (context) {
              return SafeArea(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final item in hidden)
                      ListTile(
                        leading: Icon(item.$3),
                        title: Text(item.$2),
                        onTap: () => Navigator.of(context).pop(item.$1),
                      ),
                  ],
                ),
              );
            },
          );
          if (selected != null && context.mounted) {
            context.go(selected);
          }
          return;
        }
        context.go(visible[index].$1);
      },
      destinations: [
        for (final item in visible)
          NavigationDestination(icon: Icon(item.$3), label: item.$2),
        if (overflow)
          const NavigationDestination(
            icon: Icon(Icons.more_horiz),
            label: 'Ещё',
          ),
      ],
    );
  }

  AuthNotifier? _auth(BuildContext context) {
    try {
      return context.watch<AuthNotifier>();
    } on ProviderNotFoundException {
      return null;
    }
  }

  String _current(String path, List<(String, String, IconData)> sections) {
    var best = sections.first.$1;
    for (final item in sections) {
      if (item.$1 != '/' &&
          path.startsWith(item.$1) &&
          item.$1.length >= best.length) {
        best = item.$1;
      }
    }
    return best;
  }

  int _index(List<(String, String, IconData)> sections, String current) {
    final index = sections.indexWhere((item) => item.$1 == current);
    return index < 0 ? 0 : index;
  }
}
