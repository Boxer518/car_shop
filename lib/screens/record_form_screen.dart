import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../auth/auth_notifier.dart';
import '../catalog/collection_spec.dart';
import '../core/api_exception.dart';
import '../domain/pricing.dart';
import '../domain/schedule.dart';
import '../models/list_query.dart';
import '../models/quote.dart';
import '../models/salon_record.dart';
import '../repositories/salon_api.dart';
import '../validation/validators.dart';
import '../widgets/salon_scaffold.dart';

class RecordFormScreen extends StatefulWidget {
  const RecordFormScreen({required this.spec, this.id, super.key});

  final CollectionSpec spec;
  final String? id;

  @override
  State<RecordFormScreen> createState() => _RecordFormScreenState();
}

class _RecordFormScreenState extends State<RecordFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _values = <String, String>{};
  final _multi = <String, List<String>>{};
  final _server = <String, String>{};
  final _options = <String, List<Choice>>{};
  PriceQuote? _quote;
  var _ready = false;
  var _saving = false;
  String? _formError;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    final api = context.read<SalonApi>();
    final auth = _auth();
    if (widget.spec.drive && widget.id == null) {
      _values['status'] = 'planned';
    }
    if (widget.spec.collection == 'cars' && widget.id == null) {
      _values['status'] = 'in_stock';
    }
    if (widget.spec.deal && widget.id == null) {
      _values['discountPercent'] = '0';
    }
    if (widget.spec.lockCustomer) {
      _values['customer'] = auth?.user?.customerId ?? '';
    }
    if (widget.id != null) {
      final record = await api.read(widget.spec.collection, widget.id!);
      _fill(record);
    }
    await _loadOptions(api);
    if (widget.spec.deal && (_values['car'] ?? '').isNotEmpty) {
      await _loadQuote();
    }
    if (mounted) {
      setState(() => _ready = true);
    }
  }

  void _fill(SalonRecord record) {
    for (final field in widget.spec.fields) {
      if (field.kind == FieldKind.multi) {
        _multi[field.key] = record.ids(field.key);
      } else {
        _values[field.key] = record.text(field.key);
      }
    }
  }

  Future<void> _loadOptions(SalonApi api) async {
    for (final field in widget.spec.fields) {
      final relation = field.relation;
      if (relation == null) {
        continue;
      }
      final page = await api.list(
        relation,
        const ListQuery(size: 50, sort: 'id'),
      );
      _options[field.key] = [
        for (final row in page.items)
          Choice(row.id, switch (relation) {
            'cars' => row.text('vin'),
            'customers' => row.text('fullName'),
            'users' => row.text('fullName'),
            _ => row.text('name'),
          }),
      ];
    }
  }

  Future<void> _loadQuote() async {
    final carId = _values['car'] ?? '';
    if (carId.isEmpty) {
      _quote = null;
      return;
    }
    final discount = int.tryParse(_values['discountPercent'] ?? '') ?? 0;
    try {
      _quote = await context.read<SalonApi>().quote(
        carId: carId,
        discountPercent: discount,
      );
      _server.remove('discountPercent');
    } on ValidationException catch (exception) {
      _quote = null;
      _server.addAll(exception.fields);
    } on ApiException catch (exception) {
      _quote = null;
      _formError = exception.message;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SalonScaffold(
      title: widget.id == null
          ? 'Новая запись: ${widget.spec.singular}'
          : 'Правка: ${widget.spec.singular}',
      body: !_ready
          ? const Center(
              child: CircularProgressIndicator(key: Key('catalog-loading')),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final field in widget.spec.fields)
                          if (!field.hidden && !field.computed)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _field(field),
                            ),
                        if (widget.spec.deal) _quoteCard(),
                        if (widget.spec.drive)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: Text(
                              'Интервал от 30 минут до 3 часов. Один автомобиль не бронируется дважды на одно время.',
                            ),
                          ),
                        if (_formError != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              _formError!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        FilledButton(
                          onPressed: _saving ? null : _save,
                          child: Text(_saving ? 'Сохранение…' : 'Сохранить'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _field(FieldSpec field) {
    final role = _auth()?.role;
    if (field.kind == FieldKind.select || field.kind == FieldKind.relation) {
      final options = field.kind == FieldKind.select
          ? field.choices
          : (_options[field.key] ?? const <Choice>[]);
      final current = _values[field.key];
      final known =
          current != null && options.any((item) => item.value == current);
      return DropdownButtonFormField<String>(
        key: ValueKey('${field.key}-${options.length}-$current'),
        initialValue: known ? current : null,
        decoration: InputDecoration(labelText: field.label),
        items: [
          for (final option in options)
            DropdownMenuItem(
              value: option.value,
              child: Text(option.label, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: (value) async {
          _values[field.key] = value ?? '';
          _server.remove(field.key);
          if (widget.spec.deal &&
              (field.key == 'car' || field.key == 'discountPercent')) {
            await _loadQuote();
          }
          if (mounted) {
            setState(() {});
          }
        },
        validator: (value) =>
            validateField(field, value ?? '', role: role) ?? _server[field.key],
      );
    }
    if (field.kind == FieldKind.multi) {
      final options = _options[field.key] ?? const <Choice>[];
      final selected = _multi[field.key] ?? const <String>[];
      return FormField<List<String>>(
        initialValue: selected,
        validator: (_) => _server[field.key],
        builder: (state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(field.label, style: Theme.of(context).textTheme.titleSmall),
              for (final option in options)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: state.value?.contains(option.value) ?? false,
                  title: Text(
                    option.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onChanged: (checked) {
                    final next = [...?state.value];
                    if (checked ?? false) {
                      next.add(option.value);
                    } else {
                      next.remove(option.value);
                    }
                    _multi[field.key] = next;
                    state.didChange(next);
                  },
                ),
              if (state.hasError)
                Text(
                  state.errorText!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          );
        },
      );
    }
    return TextFormField(
      initialValue: _values[field.key] ?? '',
      maxLength: field.maxLength,
      maxLines: field.kind == FieldKind.longText ? 3 : 1,
      keyboardType: field.kind == FieldKind.number
          ? TextInputType.number
          : TextInputType.text,
      decoration: InputDecoration(
        labelText: field.label,
        hintText: switch (field.kind) {
          FieldKind.date => 'ГГГГ-ММ-ДД',
          FieldKind.dateTime => 'ГГГГ-ММ-ДД ЧЧ:ММ',
          _ => null,
        },
      ),
      onChanged: (value) async {
        _values[field.key] = value;
        _server.remove(field.key);
        if (widget.spec.deal && field.key == 'discountPercent') {
          await _loadQuote();
          if (mounted) {
            setState(() {});
          }
        }
      },
      validator: (value) {
        if (field.key == 'endsAt') {
          return validateField(
                field,
                value ?? '',
                role: role,
                otherDate: parseSalonDate(_values['startsAt'] ?? ''),
                otherIsStart: true,
              ) ??
              _server[field.key];
        }
        return validateField(field, value ?? '', role: role) ??
            _server[field.key];
      },
    );
  }

  Widget _quoteCard() {
    final quote = _quote;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: quote == null
            ? const Text(
                'Выберите автомобиль, чтобы рассчитать цену. Пробег от 100 000 км даёт 5%, возраст от 5 лет — ещё 3%.',
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Цена автомобиля: ${formatMoney(quote.basePrice)}'),
                  Text('Опции: ${formatMoney(quote.optionsTotal)}'),
                  Text('Автоскидка: ${quote.automaticPercent}%'),
                  Text(
                    'Итоговая скидка: ${quote.totalPercent}% из ${quote.cap}%',
                  ),
                  Text('К оплате: ${formatMoney(quote.finalPrice)}'),
                  if (_server['finalPrice'] != null)
                    Text(
                      _server['finalPrice']!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Future<void> _save() async {
    _server.clear();
    _formError = null;
    if (widget.spec.deal) {
      await _loadQuote();
    }
    if (!mounted || _formKey.currentState?.validate() != true) {
      setState(() {});
      return;
    }
    final api = context.read<SalonApi>();
    if (widget.spec.drive) {
      final message = await _driveClash(api);
      if (!mounted) {
        return;
      }
      if (message != null) {
        _server[message.contains('занят') ? 'startsAt' : 'endsAt'] = message;
        _formKey.currentState?.validate();
        setState(() {});
        return;
      }
    }
    setState(() => _saving = true);
    final body = _body();
    try {
      if (widget.id == null) {
        await api.create(widget.spec.collection, body);
      } else {
        await api.update(widget.spec.collection, widget.id!, body);
      }
      if (mounted) {
        context.go(widget.spec.path);
      }
    } on ValidationException catch (exception) {
      _apply(exception.message, exception.fields);
    } on ConflictException catch (exception) {
      _apply(exception.message, exception.fields);
    } on ApiException catch (exception) {
      _formError = exception.message;
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<String?> _driveClash(SalonApi api) async {
    final carId = _values['car'] ?? '';
    if (carId.isEmpty) {
      return null;
    }
    final existing = await api.drivesOf(carId);
    return driveError(
      start: parseSalonDate(_values['startsAt'] ?? ''),
      end: parseSalonDate(_values['endsAt'] ?? ''),
      existing: existing,
      selfId: widget.id,
    );
  }

  Map<String, dynamic> _body() {
    final body = <String, dynamic>{};
    for (final field in widget.spec.fields) {
      if (field.computed) {
        continue;
      }
      if (field.kind == FieldKind.multi) {
        body[field.key] = _multi[field.key] ?? <String>[];
      } else if (field.kind == FieldKind.number) {
        body[field.key] = int.tryParse((_values[field.key] ?? '').trim()) ?? 0;
      } else if (field.kind == FieldKind.vin) {
        body[field.key] = (_values[field.key] ?? '').trim().toUpperCase();
      } else {
        body[field.key] = (_values[field.key] ?? '').trim();
      }
    }
    final quote = _quote;
    if (quote != null) {
      body['basePrice'] = quote.basePrice;
      body['optionsTotal'] = quote.optionsTotal;
      body['automaticPercent'] = quote.automaticPercent;
      body['discountPercent'] =
          int.tryParse(_values['discountPercent'] ?? '') ?? 0;
      body['finalPrice'] = quote.finalPrice;
      body['manager'] = _auth()?.user?.id ?? '';
    }
    return body;
  }

  void _apply(String message, Map<String, String> fields) {
    _server
      ..clear()
      ..addAll(fields);
    _formError = fields.isEmpty ? message : null;
    _formKey.currentState?.validate();
    setState(() {});
  }

  AuthNotifier? _auth() {
    try {
      return context.read<AuthNotifier>();
    } on ProviderNotFoundException {
      return null;
    }
  }
}
