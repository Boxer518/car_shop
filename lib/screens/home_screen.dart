import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../auth/access.dart';
import '../auth/auth_notifier.dart';
import '../widgets/salon_scaffold.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = _auth(context);
    final role = auth?.role;
    return SalonScaffold(
      title: 'Автосалон',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Каталог автомобилей',
            style: Theme.of(context).textTheme.headlineSmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(_text(role)),
          const SizedBox(height: 16),
          const Text(
            'Скидка считается сама: 5% при пробеге от 100 000 км и ещё 3%, если автомобилю 5 лет и больше. Менеджер добавляет до 15%, директор — до 25%.',
          ),
        ],
      ),
    );
  }

  String _text(AppRole? role) {
    return switch (role) {
      AppRole.buyer => 'Вам открыты каталог и свои записи на тест-драйв.',
      AppRole.manager => 'Вам открыты сделки и расписание тест-драйвов.',
      AppRole.director => 'Вам открыты отчёт по продажам и учётные записи.',
      null => 'Войдите, чтобы работать с каталогом.',
    };
  }

  AuthNotifier? _auth(BuildContext context) {
    try {
      return context.watch<AuthNotifier>();
    } on ProviderNotFoundException {
      return null;
    }
  }
}
