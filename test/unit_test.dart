import 'package:car_shop/auth/access.dart';
import 'package:car_shop/catalog/catalog.dart';
import 'package:car_shop/core/api_exception.dart';
import 'package:car_shop/domain/pricing.dart';
import 'package:car_shop/domain/schedule.dart';
import 'package:car_shop/models/list_query.dart';
import 'package:car_shop/repositories/memory_salon_api.dart';
import 'package:car_shop/validation/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 11, 20);

  test('пробег от 100000 км даёт 5%', () {
    expect(automaticPercent(2024, 100000, now: now), 5);
  });

  test('возраст от 5 лет даёт ещё 3%', () {
    expect(automaticPercent(2018, 140000, now: now), 8);
  });

  test('потолок менеджера 15%', () {
    expect(roleCap(AppRole.manager), 15);
    expect(
      finalPrice(
        base: 1000000,
        optionsTotal: 0,
        automatic: 8,
        manual: 10,
        cap: 15,
      ),
      850000,
    );
  });

  test('потолок директора 25%', () {
    expect(roleCap(AppRole.director), 25);
    expect(
      finalPrice(
        base: 1000000,
        optionsTotal: 0,
        automatic: 8,
        manual: 20,
        cap: 25,
      ),
      750000,
    );
  });

  test('итог Camry со скидкой 2%', () {
    expect(
      finalPrice(
        base: 3200000,
        optionsTotal: 80000,
        automatic: 0,
        manual: 2,
        cap: 15,
      ),
      3214400,
    );
  });

  test('пересечение интервалов запрещено', () {
    final message = driveError(
      start: DateTime.utc(2026, 11, 21, 12, 30),
      end: DateTime.utc(2026, 11, 21, 13, 30),
      existing: [
        DriveInterval(
          start: DateTime.utc(2026, 11, 21, 12),
          end: DateTime.utc(2026, 11, 21, 13),
        ),
      ],
    );
    expect(message, 'Автомобиль уже занят в этот интервал');
  });

  test('тест-драйв короче 30 минут не проходит', () {
    final message = driveError(
      start: DateTime.utc(2026, 11, 21, 15),
      end: DateTime.utc(2026, 11, 21, 15, 10),
      existing: const [],
    );
    expect(message, 'Тест-драйв длится от 30 минут до 3 часов');
  });

  test('роли открывают разные разделы', () {
    expect(roleAllows(AppRole.buyer, '/my-drives'), isTrue);
    expect(roleAllows(AppRole.manager, '/my-drives'), isFalse);
    expect(roleAllows(AppRole.manager, '/deals'), isTrue);
    expect(roleAllows(AppRole.director, '/deals'), isFalse);
    expect(roleAllows(AppRole.director, '/admin/report'), isTrue);
    expect(roleAllows(AppRole.manager, '/admin/users'), isFalse);
    expect(roleAllows(AppRole.buyer, '/cars/new'), isFalse);
  });

  test('гость уходит на вход, чужой адрес — на отказ', () {
    expect(
      authRedirect(
        loggedIn: false,
        role: null,
        matchedPath: '/cars',
        fullUri: '/cars',
      ),
      '/login?from=%2Fcars',
    );
    expect(
      authRedirect(
        loggedIn: true,
        role: AppRole.manager,
        matchedPath: '/admin/report',
        fullUri: '/admin/report',
      ),
      '/forbidden',
    );
  });

  test('валидация обязательности, VIN и года', () {
    final vin = carsSpec.field('vin')!;
    final year = carsSpec.field('year')!;
    expect(validateField(vin, ''), 'Заполните поле «VIN»');
    expect(validateField(vin, 'JTNBE46K50312345'), 'Минимум 17 символов');
    expect(validateField(vin, 'JTNBE46K503123456'), isNull);
    expect(validateField(year, '1980'), 'Минимум 1990');
    expect(validateField(year, '2022'), isNull);
  });

  test('запрос списка сохраняется в адресе', () {
    const query = ListQuery(
      search: 'camry',
      sort: 'price',
      descending: true,
      page: 2,
      size: 25,
      filters: {'status': 'in_stock', 'yearFrom': '2020'},
    );
    final restored = ListQuery.fromParameters(
      query.toParameters(),
      defaultSort: 'price',
      allowedSorts: {'price', 'year'},
    );
    expect(restored.search, 'camry');
    expect(restored.descending, isTrue);
    expect(restored.page, 2);
    expect(restored.size, 25);
    expect(restored.filters['status'], 'in_stock');
    expect(restored.filters['yearFrom'], '2020');
  });

  test('расчёт сделки Solaris совпадает с правилом', () async {
    final api = MemorySalonApi(now: now);
    await api.login('manager@salon.local', 'manager123');
    final quote = await api.quote(carId: 'car_solaris', discountPercent: 0);
    expect(quote.automaticPercent, 8);
    expect(quote.finalPrice, 1053400);
  });

  test('повторный тест-драйв той же машины даёт конфликт', () async {
    final api = MemorySalonApi(now: now);
    await api.login('manager@salon.local', 'manager123');
    expect(
      () => api.create('test_drives', {
        'car': 'car_camry',
        'customer': 'cust_buyer',
        'startsAt': '2026-11-21 12:30:00.000Z',
        'endsAt': '2026-11-21 13:30:00.000Z',
        'status': 'planned',
      }),
      throwsA(isA<ConflictException>()),
    );
  });

  test('скидка выше потолка роли — ошибка поля', () async {
    final api = MemorySalonApi(now: now);
    await api.login('manager@salon.local', 'manager123');
    expect(
      () => api.quote(carId: 'car_camry', discountPercent: 20),
      throwsA(
        isA<ValidationException>().having(
          (error) => error.fields['discountPercent'],
          'field',
          isNotNull,
        ),
      ),
    );
  });

  test('марку с моделями нельзя удалить физически', () async {
    final api = MemorySalonApi(now: now);
    expect(
      () => api.hardDelete('brands', 'brand_toyota'),
      throwsA(isA<ConflictException>()),
    );
  });

  test('страница каталога режется на сервере памяти', () async {
    final api = MemorySalonApi(now: now);
    final page = await api.list(
      'cars',
      const ListQuery(size: 2, page: 2, sort: 'price'),
    );
    expect(page.total, 3);
    expect(page.items, hasLength(1));
    expect(page.hasPrevious, isTrue);
  });
}
