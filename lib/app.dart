import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'auth/auth_notifier.dart';
import 'repositories/memory_salon_api.dart';
import 'repositories/salon_api.dart';
import 'router.dart';

class SalonApp extends StatelessWidget {
  SalonApp({SalonApi? api, AuthNotifier? auth, super.key})
    : api = api ?? MemorySalonApi(),
      auth = auth,
      router = buildRouter(auth);

  final SalonApi api;
  final AuthNotifier? auth;
  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<SalonApi>.value(value: api),
        if (auth != null)
          ChangeNotifierProvider<AuthNotifier>.value(value: auth!),
      ],
      child: MaterialApp.router(
        title: 'Автосалон',
        routerConfig: router,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B3A4B)),
          useMaterial3: true,
        ),
      ),
    );
  }
}
