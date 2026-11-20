import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../auth/auth_notifier.dart';
import '../catalog/collection_spec.dart';
import '../core/api_exception.dart';
import '../validation/validators.dart';
import '../widgets/salon_scaffold.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _server = <String, String>{};
  var _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notice = context.watch<AuthNotifier>().notice;
    return SalonScaffold(
      title: 'Вход',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (notice != null) Text(notice),
                  TextFormField(
                    controller: _email,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (value) => validateField(
                      const FieldSpec(
                        key: 'email',
                        label: 'Email',
                        kind: FieldKind.email,
                        required: true,
                      ),
                      value ?? '',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _password,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Пароль',
                      errorText: _server['password'],
                    ),
                    validator: (value) =>
                        validatePassword(value ?? '') ?? _server['password'],
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: const Text('Войти'),
                  ),
                  TextButton(
                    onPressed: () => context.go('/register'),
                    child: const Text('Регистрация'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    _server.clear();
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    setState(() => _busy = true);
    try {
      await context.read<AuthNotifier>().login(_email.text, _password.text);
    } on ValidationException catch (exception) {
      _server.addAll(exception.fields);
      _formKey.currentState?.validate();
    } on ApiException catch (exception) {
      _server['password'] = exception.message;
      _formKey.currentState?.validate();
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }
}
