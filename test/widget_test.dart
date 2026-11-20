import 'package:car_shop/app.dart';
import 'package:car_shop/auth/auth_notifier.dart';
import 'package:car_shop/repositories/memory_salon_api.dart';
import 'package:car_shop/state/load_status.dart';
import 'package:car_shop/widgets/catalog_view.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('каталог показывает загрузку', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CatalogView(
          status: LoadStatus.loading,
          columns: [('name', 'Название')],
          items: [],
          cell: _blank,
        ),
      ),
    );
    expect(find.byKey(const Key('catalog-loading')), findsOneWidget);
  });

  testWidgets('пустой каталог сообщает, что ничего нет', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CatalogView(
          status: LoadStatus.ready,
          columns: [('name', 'Название')],
          items: [],
          cell: _blank,
        ),
      ),
    );
    expect(find.text('Ничего не найдено'), findsOneWidget);
  });

  testWidgets('ошибка предлагает повтор', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: CatalogView(
          status: LoadStatus.error,
          columns: const [('name', 'Название')],
          items: const [],
          cell: _blank,
          onRetry: () => taps += 1,
        ),
      ),
    );
    expect(find.text('Не удалось загрузить данные'), findsOneWidget);
    await tester.tap(find.text('Повторить'));
    expect(taps, 1);
  });

  testWidgets('широкий экран показывает таблицу', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        home: CatalogView(
          status: LoadStatus.ready,
          columns: [('vin', 'VIN')],
          items: ['car_camry'],
          cell: _vin,
        ),
      ),
    );
    expect(find.byType(DataTable), findsOneWidget);
    expect(find.text('JTNBE46K503123456'), findsOneWidget);
  });

  testWidgets('узкий экран показывает карточки', (tester) async {
    tester.view.physicalSize = const Size(420, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CatalogView(
            status: LoadStatus.ready,
            columns: [('vin', 'VIN')],
            items: ['car_camry'],
            cell: _vin,
          ),
        ),
      ),
    );
    expect(find.byType(DataTable), findsNothing);
    expect(find.textContaining('JTNBE46K503123456'), findsOneWidget);
  });

  testWidgets('пустая форма автомобиля показывает ошибку VIN', (tester) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final app = SalonApp();
    await tester.pumpWidget(app);
    app.router.go('/cars/new');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    final save = find.text('Сохранить');
    await tester.ensureVisible(save);
    await tester.pump();
    await tester.tap(save);
    await tester.pump();
    expect(find.text('Заполните поле «VIN»'), findsOneWidget);
  });

  testWidgets('покупатель не видит кнопку добавления автомобиля', (
    tester,
  ) async {
    final api = MemorySalonApi();
    final auth = AuthNotifier(api: api);
    auth.attach(api);
    final session = await api.login('buyer@salon.local', 'buyer123');
    auth.signInForTest(session.user, token: session.token);
    final app = SalonApp(api: api, auth: auth);
    await tester.pumpWidget(app);
    app.router.go('/cars');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byKey(const Key('add-record')), findsNothing);
    expect(find.text('Автомобили'), findsWidgets);
  });

  testWidgets('менеджер не открывает отчёт директора', (tester) async {
    final api = MemorySalonApi();
    final auth = AuthNotifier(api: api);
    auth.attach(api);
    final session = await api.login('manager@salon.local', 'manager123');
    auth.signInForTest(session.user, token: session.token);
    final app = SalonApp(api: api, auth: auth);
    await tester.pumpWidget(app);
    app.router.go('/admin/report');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Недостаточно прав'), findsOneWidget);
  });
}

String _blank(String id, String column) => '';

String _vin(String id, String column) => 'JTNBE46K503123456';
