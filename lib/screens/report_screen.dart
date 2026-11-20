import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../core/api_exception.dart';
import '../domain/pricing.dart';
import '../models/quote.dart';
import '../repositories/salon_api.dart';
import '../state/load_status.dart';
import '../widgets/salon_scaffold.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  LoadStatus _status = LoadStatus.loading;
  String _error = 'Не удалось загрузить данные';
  SalonReport? _report;

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
      _report = await context.read<SalonApi>().report();
      _status = LoadStatus.ready;
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
    final report = _report;
    final empty =
        report != null &&
        report.dealsCount == 0 &&
        report.carsInStock == 0 &&
        report.carsSold == 0 &&
        report.plannedDrives == 0;
    return SalonScaffold(
      title: 'Отчёт',
      body: switch (_status) {
        LoadStatus.loading => const Center(
          child: CircularProgressIndicator(key: Key('catalog-loading')),
        ),
        LoadStatus.error => _message(_error, const Text('Повторить')),
        LoadStatus.ready when empty => const Center(
          child: Text('Ничего не найдено'),
        ),
        LoadStatus.ready when report == null => const Center(
          child: Text('Ничего не найдено'),
        ),
        LoadStatus.ready => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Сделок: ${report!.dealsCount} на ${formatMoney(report.dealsSum)}',
            ),
            Text(
              'В наличии: ${report.carsInStock}, бронь: ${report.carsReserved}, продано: ${report.carsSold}',
            ),
            Text('Запланировано тест-драйвов: ${report.plannedDrives}'),
            const SizedBox(height: 16),
            Text(
              'Продажи по маркам',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final row in report.byBrand) _bar(context, row, report),
          ],
        ),
      },
    );
  }

  Widget _message(String text, Widget action) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: _load, child: action),
        ],
      ),
    );
  }

  Widget _bar(BuildContext context, BrandSlice row, SalonReport report) {
    final maxSum = report.byBrand.fold<int>(
      0,
      (max, item) => item.sum > max ? item.sum : max,
    );
    final factor = maxSum == 0 ? 0.0 : row.sum / maxSum;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${row.brand}: ${row.count} · ${formatMoney(row.sum)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: factor.clamp(0, 1),
              minHeight: 14,
            ),
          ),
        ],
      ),
    );
  }
}
