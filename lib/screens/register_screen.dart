import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../auth/auth_notifier.dart';
import '../catalog/collection_spec.dart';
import '../core/api_exception.dart';
import '../validation/validators.dart';
import '../widgets/salon_scaffold.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _server = <String, String>{};
  var _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SalonScaffold(
      title: 'Регистрация',
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
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'ФИО'),
                    validator: (value) => validateField(
                      const FieldSpec(
                        key: 'fullName',
                        label: 'ФИО',
                        kind: FieldKind.text,
                        required: true,
                        minLength: 5,
                        maxLength: 120,
                      ),
                      value ?? '',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _email,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      errorText: _server['email'],
                    ),
                    validator: (value) =>
                        validateField(
                          const FieldSpec(
                            key: 'email',
                            label: 'Email',
                            kind: FieldKind.email,
                            required: true,
                          ),
                          value ?? '',
                        ) ??
                        _server['email'],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phone,
                    decoration: const InputDecoration(labelText: 'Телефон'),
                    validator: (value) => validateField(
                      const FieldSpec(
                        key: 'phone',
                        label: 'Телефон',
                        kind: FieldKind.phone,
                        required: true,
                        minLength: 10,
                        maxLength: 16,
                      ),
                      value ?? '',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Пароль'),
                    validator: (value) => validatePassword(value ?? ''),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _confirm,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Повтор пароля',
                    ),
                    validator: (value) =>
                        validatePassword(_password.text, confirm: value ?? ''),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: const Text('Создать учётную запись'),
                  ),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Уже есть вход'),
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
      setState(() {});
      return;
    }
    setState(() => _busy = true);
    try {
      await context.read<AuthNotifier>().register(
        email: _email.text,
        password: _password.text,
        fullName: _name.text,
        phone: _phone.text,
      );
    } on ValidationException catch (exception) {
      _server.addAll(exception.fields);
      _formKey.currentState?.validate();
      setState(() {});
    } on ApiException catch (exception) {
      _server['email'] = exception.message;
      _formKey.currentState?.validate();
      setState(() {});
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }
}
