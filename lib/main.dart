import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'auth/auth_notifier.dart';
import 'core/api_client.dart';
import 'repositories/pb_salon_api.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  final preferences = await SharedPreferences.getInstance();
  final auth = AuthNotifier(prefs: preferences);
  final dio = buildDio(
    tokenProvider: () => auth.token,
    refresh: () => auth.refresh(),
  );
  final api = PbSalonApi(dio);
  auth.attach(api);
  await auth.restore();
  runApp(SalonApp(api: api, auth: auth));
}
