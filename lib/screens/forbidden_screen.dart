import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../widgets/salon_scaffold.dart';

class ForbiddenScreen extends StatelessWidget {
  const ForbiddenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SalonScaffold(
      title: 'Доступ закрыт',
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Недостаточно прав',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Этот раздел открыт другой роли.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go('/'),
                child: const Text('На главную'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SalonScaffold(
      title: 'Страница не найдена',
      body: Center(
        child: FilledButton(
          onPressed: () => context.go('/'),
          child: const Text('На главную'),
        ),
      ),
    );
  }
}
