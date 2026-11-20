import '../auth/access.dart';
import '../catalog/collection_spec.dart';
import '../core/api_exception.dart';
import '../domain/pricing.dart';
import '../domain/schedule.dart';
import '../models/list_query.dart';
import '../models/page_result.dart';
import '../models/quote.dart';
import '../models/salon_record.dart';
import '../models/session_user.dart';
import 'salon_api.dart';

class MemorySalonApi implements SalonApi {
  MemorySalonApi({DateTime? now}) : now = now ?? DateTime.utc(2026, 11, 20) {
    _seed();
  }

  final DateTime now;
  final Map<String, List<Map<String, dynamic>>> _rows = {};
  final Map<String, String> _passwords = {};
  SessionUser? actor;
  var _seq = 100;

  @override
  void bind(SessionUser? user) {
    actor = user;
  }

  void _seed() {
    _rows.addAll({
      'brands': [
        {
          'id': 'brand_toyota',
          'name': 'Toyota',
          'country': 'Япония',
          'deleted': false,
        },
        {
          'id': 'brand_bmw',
          'name': 'BMW',
          'country': 'Германия',
          'deleted': false,
        },
        {
          'id': 'brand_hyundai',
          'name': 'Hyundai',
          'country': 'Корея',
          'deleted': false,
        },
      ],
      'models': [
        {
          'id': 'model_camry',
          'brand': 'brand_toyota',
          'name': 'Camry',
          'bodyType': 'sedan',
          'seats': 5,
          'deleted': false,
        },
        {
          'id': 'model_x5',
          'brand': 'brand_bmw',
          'name': 'X5',
          'bodyType': 'suv',
          'seats': 5,
          'deleted': false,
        },
        {
          'id': 'model_solaris',
          'brand': 'brand_hyundai',
          'name': 'Solaris',
          'bodyType': 'sedan',
          'seats': 5,
          'deleted': false,
        },
      ],
      'options': [
        {
          'id': 'opt_heat',
          'name': 'Подогрев',
          'price': 45000,
          'deleted': false,
        },
        {
          'id': 'opt_camera',
          'name': 'Камера',
          'price': 35000,
          'deleted': false,
        },
        {
          'id': 'opt_leather',
          'name': 'Кожа',
          'price': 120000,
          'deleted': false,
        },
      ],
      'cars': [
        {
          'id': 'car_camry',
          'model': 'model_camry',
          'vin': 'JTNBE46K503123456',
          'year': 2022,
          'price': 3200000,
          'mileage': 45000,
          'color': 'белый',
          'status': 'in_stock',
          'options': ['opt_heat', 'opt_camera'],
          'deleted': false,
        },
        {
          'id': 'car_x5',
          'model': 'model_x5',
          'vin': 'WBAJB1C50JB234567',
          'year': 2024,
          'price': 8900000,
          'mileage': 12000,
          'color': 'чёрный',
          'status': 'in_stock',
          'options': ['opt_leather', 'opt_camera'],
          'deleted': false,
        },
        {
          'id': 'car_solaris',
          'model': 'model_solaris',
          'vin': 'Z94CT41DBJR345678',
          'year': 2018,
          'price': 1100000,
          'mileage': 140000,
          'color': 'серый',
          'status': 'sold',
          'options': ['opt_heat'],
          'deleted': false,
        },
      ],
      'passports': [
        {
          'id': 'pts_1',
          'car': 'car_camry',
          'number': '77УН123456',
          'issuedOn': '2022-03-01',
          'issuedBy': 'ГИБДД Москва',
          'deleted': false,
        },
        {
          'id': 'pts_2',
          'car': 'car_x5',
          'number': '77УН654321',
          'issuedOn': '2024-01-15',
          'issuedBy': 'ГИБДД Москва',
          'deleted': false,
        },
        {
          'id': 'pts_3',
          'car': 'car_solaris',
          'number': '50УН111222',
          'issuedOn': '2018-06-20',
          'issuedBy': 'ГИБДД Московская область',
          'deleted': false,
        },
      ],
      'customers': [
        {
          'id': 'cust_ivanova',
          'fullName': 'Иванова Мария',
          'phone': '+79001112233',
          'email': 'maria@salon.local',
          'user': '',
          'deleted': false,
        },
        {
          'id': 'cust_buyer',
          'fullName': 'Смирнов Павел',
          'phone': '+79004445566',
          'email': 'buyer@salon.local',
          'user': 'user_buyer',
          'deleted': false,
        },
      ],
      'deals': [
        {
          'id': 'deal_1',
          'car': 'car_solaris',
          'customer': 'cust_ivanova',
          'manager': 'user_manager',
          'basePrice': 1100000,
          'optionsTotal': 45000,
          'discountPercent': 0,
          'automaticPercent': 8,
          'finalPrice': 1053400,
          'note': 'Скидка за возраст и пробег',
          'deleted': false,
        },
      ],
      'test_drives': [
        {
          'id': 'drive_1',
          'car': 'car_camry',
          'customer': 'cust_buyer',
          'startsAt': '2026-11-21 12:00:00.000Z',
          'endsAt': '2026-11-21 13:00:00.000Z',
          'status': 'planned',
          'deleted': false,
        },
      ],
      'users': [
        {
          'id': 'user_director',
          'email': 'director@salon.local',
          'fullName': 'Орлова Анна',
          'phone': '+79000000001',
          'role': 'director',
          'customer': '',
        },
        {
          'id': 'user_manager',
          'email': 'manager@salon.local',
          'fullName': 'Кузнецов Илья',
          'phone': '+79000000002',
          'role': 'manager',
          'customer': '',
        },
        {
          'id': 'user_buyer',
          'email': 'buyer@salon.local',
          'fullName': 'Смирнов Павел',
          'phone': '+79004445566',
          'role': 'buyer',
          'customer': 'cust_buyer',
        },
      ],
    });
    _passwords.addAll({
      'director@salon.local': 'director123',
      'manager@salon.local': 'manager123',
      'buyer@salon.local': 'buyer123',
    });
  }

  @override
  Future<AuthSession> login(String email, String password) async {
    final user = _findUser(email);
    if (user == null || _passwords[email.trim().toLowerCase()] != password) {
      throw const ValidationException(
        'Неверный email или пароль',
        fields: {'password': 'Неверный email или пароль'},
      );
    }
    final session = _session(user);
    actor = session.user;
    return session;
  }

  @override
  Future<AuthSession> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    final normalized = email.trim().toLowerCase();
    if (_findUser(normalized) != null) {
      throw const ValidationException(
        'Такой email уже зарегистрирован',
        fields: {'email': 'Такой email уже зарегистрирован'},
      );
    }
    final userId = _next();
    final customerId = _next();
    _rows['users']!.add({
      'id': userId,
      'email': normalized,
      'fullName': fullName,
      'phone': phone,
      'role': 'buyer',
      'customer': customerId,
    });
    _rows['customers']!.add({
      'id': customerId,
      'fullName': fullName,
      'phone': phone,
      'email': normalized,
      'user': userId,
      'deleted': false,
    });
    _passwords[normalized] = password;
    return login(normalized, password);
  }

  @override
  Future<AuthSession> refresh(String token) async {
    final id = token.startsWith('memory:') ? token.substring(7) : '';
    final user = _rows['users']!.where((row) => row['id'] == id).firstOrNull;
    if (user == null) {
      throw const UnauthorizedException('Сессия истекла. Войдите снова.');
    }
    final session = _session(user);
    actor = session.user;
    return session;
  }

  @override
  Future<PageResult<SalonRecord>> list(
    String collection,
    ListQuery query, {
    List<String> searchKeys = const [],
    List<FilterSpec> filters = const [],
    Map<String, String> locked = const {},
    bool trackDeleted = true,
  }) async {
    final source = _rows[collection] ?? const <Map<String, dynamic>>[];
    final matched = source.where((row) {
      if (trackDeleted && !query.includeDeleted && row['deleted'] == true) {
        return false;
      }
      for (final entry in locked.entries) {
        if ('${row[entry.key]}' != entry.value) {
          return false;
        }
      }
      if (query.search.isNotEmpty) {
        final haystack = searchKeys
            .map((key) => '${row[key]}')
            .join(' ')
            .toLowerCase();
        if (!haystack.contains(query.search.toLowerCase())) {
          return false;
        }
      }
      for (final filter in filters) {
        final raw = query.filters[filter.key];
        if (raw == null || raw.isEmpty) {
          continue;
        }
        if (!filter.matches(row, raw)) {
          return false;
        }
      }
      return true;
    }).toList();
    matched.sort((left, right) {
      final compared = _compare(left[query.sort], right[query.sort]);
      return query.descending ? -compared : compared;
    });
    final start = (query.page - 1) * query.size;
    final slice = start >= matched.length
        ? <Map<String, dynamic>>[]
        : matched.skip(start).take(query.size);
    return PageResult(
      items: slice.map(SalonRecord.new).toList(),
      page: query.page,
      size: query.size,
      total: matched.length,
    );
  }

  @override
  Future<SalonRecord> read(String collection, String id) async {
    return SalonRecord(Map<String, dynamic>.from(_must(collection, id)));
  }

  @override
  Future<SalonRecord> create(
    String collection,
    Map<String, dynamic> body,
  ) async {
    final row = Map<String, dynamic>.from(body);
    row['id'] = _next();
    row['deleted'] = false;
    if (collection == 'deals') {
      _applyDeal(row, creating: true);
    }
    if (collection == 'test_drives') {
      _applyDrive(row);
    }
    if (collection == 'cars') {
      _uniqueVin('${row['vin']}', '');
    }
    if (collection == 'passports') {
      _uniquePassport('${row['car']}', '');
    }
    _rows.putIfAbsent(collection, () => []).add(row);
    return SalonRecord(Map<String, dynamic>.from(row));
  }

  @override
  Future<SalonRecord> update(
    String collection,
    String id,
    Map<String, dynamic> body,
  ) async {
    final row = _must(collection, id);
    final next = Map<String, dynamic>.from(row)..addAll(body);
    next['id'] = id;
    if (collection == 'deals' && next['deleted'] != true) {
      _applyDeal(next, creating: false);
    }
    if (collection == 'test_drives' &&
        next['deleted'] != true &&
        next['status'] != 'cancelled') {
      _applyDrive(next);
    }
    if (collection == 'cars') {
      _uniqueVin('${next['vin']}', id);
    }
    if (collection == 'passports') {
      _uniquePassport('${next['car']}', id);
    }
    row
      ..clear()
      ..addAll(next);
    return SalonRecord(Map<String, dynamic>.from(row));
  }

  @override
  Future<void> hardDelete(String collection, String id) async {
    _guardDelete(collection, id);
    _rows[collection]?.removeWhere((row) => row['id'] == id);
  }

  @override
  Future<void> softDelete(String collection, List<String> ids) async {
    for (final id in ids) {
      _must(collection, id)['deleted'] = true;
    }
  }

  @override
  Future<void> restore(String collection, List<String> ids) async {
    for (final id in ids) {
      _must(collection, id)['deleted'] = false;
    }
  }

  @override
  Future<PriceQuote> quote({
    required String carId,
    required int discountPercent,
  }) async {
    final car = _must('cars', carId);
    final role = actor?.role ?? AppRole.manager;
    final cap = roleCap(role);
    if (discountPercent < 0 || discountPercent > cap) {
      throw ValidationException(
        'Скидка для этой роли не больше $cap%',
        fields: {'discountPercent': 'Скидка для этой роли не больше $cap%'},
      );
    }
    final optionsTotal = _optionSum(car);
    final automatic = automaticPercent(
      car['year'] as int,
      car['mileage'] as int,
      now: now,
    );
    final total = totalDiscount(
      automatic: automatic,
      manual: discountPercent,
      cap: cap,
    );
    final base = car['price'] as int;
    return PriceQuote(
      basePrice: base,
      optionsTotal: optionsTotal,
      automaticPercent: automatic,
      totalPercent: total,
      finalPrice: finalPrice(
        base: base,
        optionsTotal: optionsTotal,
        automatic: automatic,
        manual: discountPercent,
        cap: cap,
      ),
      cap: cap,
    );
  }

  @override
  Future<SalonReport> report() async {
    if (actor?.role != AppRole.director) {
      throw const ForbiddenException('Отчёт доступен директору');
    }
    final cars = _rows['cars']!.where((row) => row['deleted'] != true);
    final deals = _rows['deals']!
        .where((row) => row['deleted'] != true)
        .toList();
    final drives = _rows['test_drives']!.where(
      (row) => row['deleted'] != true && row['status'] == 'planned',
    );
    final byBrand = <String, BrandSlice>{};
    var sum = 0;
    for (final deal in deals) {
      final price = deal['finalPrice'] as int;
      sum += price;
      final car = _must('cars', '${deal['car']}');
      final model = _must('models', '${car['model']}');
      final brand = _must('brands', '${model['brand']}');
      final name = '${brand['name']}';
      final previous = byBrand[name];
      byBrand[name] = BrandSlice(
        brand: name,
        count: (previous?.count ?? 0) + 1,
        sum: (previous?.sum ?? 0) + price,
      );
    }
    return SalonReport(
      carsInStock: cars.where((row) => row['status'] == 'in_stock').length,
      carsReserved: cars.where((row) => row['status'] == 'reserved').length,
      carsSold: cars.where((row) => row['status'] == 'sold').length,
      dealsCount: deals.length,
      dealsSum: sum,
      plannedDrives: drives.length,
      byBrand: byBrand.values.toList(),
    );
  }

  @override
  Future<List<DriveInterval>> drivesOf(String carId) async {
    return _rows['test_drives']!
        .where((row) => row['car'] == carId)
        .map(
          (row) => DriveInterval(
            id: '${row['id']}',
            start: parseSalonDate('${row['startsAt']}') ?? now,
            end: parseSalonDate('${row['endsAt']}') ?? now,
            status: '${row['status']}',
            deleted: row['deleted'] == true,
          ),
        )
        .toList();
  }

  void _applyDeal(Map<String, dynamic> row, {required bool creating}) {
    final role = actor?.role;
    if (role != AppRole.manager && role != AppRole.director) {
      throw const ForbiddenException('Сделку оформляет менеджер');
    }
    final manual = row['discountPercent'] is num
        ? (row['discountPercent'] as num).round()
        : int.tryParse('${row['discountPercent']}') ?? 0;
    final cap = roleCap(role!);
    if (manual < 0 || manual > cap) {
      throw ValidationException(
        'Скидка для этой роли не больше $cap%',
        fields: {'discountPercent': 'Скидка для этой роли не больше $cap%'},
      );
    }
    final car = _must('cars', '${row['car']}');
    final others = _rows['deals']!.where(
      (item) =>
          item['car'] == car['id'] &&
          item['deleted'] != true &&
          item['id'] != row['id'],
    );
    if (car['status'] == 'sold' && others.isNotEmpty) {
      throw const ConflictException(
        'Автомобиль уже продан',
        fields: {'car': 'Автомобиль уже продан'},
      );
    }
    final priced = _priced(car, manual, cap);
    final sent = row['finalPrice'];
    final sentPrice = sent is num ? sent.round() : int.tryParse('$sent') ?? 0;
    if (sentPrice != 0 && (sentPrice - priced.finalPrice).abs() > 1) {
      throw const ConflictException(
        'Итоговая цена не сходится с правилами салона',
        fields: {'finalPrice': 'Итоговая цена не сходится с правилами салона'},
      );
    }
    row['basePrice'] = priced.basePrice;
    row['optionsTotal'] = priced.optionsTotal;
    row['automaticPercent'] = priced.automaticPercent;
    row['finalPrice'] = priced.finalPrice;
    row['discountPercent'] = manual;
    row['manager'] = row['manager']?.toString().isNotEmpty == true
        ? row['manager']
        : actor!.id;
    if (creating) {
      car['status'] = 'sold';
    }
  }

  void _applyDrive(Map<String, dynamic> row) {
    final start = parseSalonDate('${row['startsAt']}');
    final end = parseSalonDate('${row['endsAt']}');
    final existing = _rows['test_drives']!
        .where((item) => item['car'] == row['car'])
        .map(
          (item) => DriveInterval(
            id: '${item['id']}',
            start: parseSalonDate('${item['startsAt']}') ?? now,
            end: parseSalonDate('${item['endsAt']}') ?? now,
            status: '${item['status']}',
            deleted: item['deleted'] == true,
          ),
        )
        .toList();
    final message = driveError(
      start: start,
      end: end,
      existing: existing,
      selfId: '${row['id'] ?? ''}',
    );
    if (message == null) {
      row['status'] = row['status']?.toString().isNotEmpty == true
          ? row['status']
          : 'planned';
      return;
    }
    if (message.contains('занят')) {
      throw ConflictException(message, fields: {'startsAt': message});
    }
    throw ValidationException(message, fields: {'endsAt': message});
  }

  PriceQuote _priced(Map<String, dynamic> car, int manual, int cap) {
    final optionsTotal = _optionSum(car);
    final automatic = automaticPercent(
      car['year'] as int,
      car['mileage'] as int,
      now: now,
    );
    return PriceQuote(
      basePrice: car['price'] as int,
      optionsTotal: optionsTotal,
      automaticPercent: automatic,
      totalPercent: totalDiscount(
        automatic: automatic,
        manual: manual,
        cap: cap,
      ),
      finalPrice: finalPrice(
        base: car['price'] as int,
        optionsTotal: optionsTotal,
        automatic: automatic,
        manual: manual,
        cap: cap,
      ),
      cap: cap,
    );
  }

  int _optionSum(Map<String, dynamic> car) {
    final ids = car['options'];
    if (ids is! List) {
      return 0;
    }
    var sum = 0;
    for (final id in ids) {
      sum += _must('options', '$id')['price'] as int;
    }
    return sum;
  }

  void _uniqueVin(String vin, String self) {
    final taken = _rows['cars']!.any(
      (row) =>
          row['id'] != self &&
          row['deleted'] != true &&
          '${row['vin']}'.toUpperCase() == vin.toUpperCase(),
    );
    if (taken) {
      throw const ValidationException(
        'Такой VIN уже есть',
        fields: {'vin': 'Такой VIN уже есть'},
      );
    }
  }

  void _uniquePassport(String carId, String self) {
    final taken = _rows['passports']!.any(
      (row) =>
          row['id'] != self && row['deleted'] != true && row['car'] == carId,
    );
    if (taken) {
      throw const ConflictException(
        'У автомобиля уже есть ПТС',
        fields: {'car': 'У автомобиля уже есть ПТС'},
      );
    }
  }

  void _guardDelete(String collection, String id) {
    bool used(String name, bool Function(Map<String, dynamic> row) test) {
      return _rows[name]!.any((row) => row['deleted'] != true && test(row));
    }

    final message = switch (collection) {
      'brands' when used('models', (row) => row['brand'] == id) =>
        'У марки есть модели',
      'models' when used('cars', (row) => row['model'] == id) =>
        'У модели есть автомобили',
      'cars' when used('deals', (row) => row['car'] == id) =>
        'По автомобилю есть сделки',
      'cars' when used('passports', (row) => row['car'] == id) =>
        'У автомобиля есть ПТС',
      'customers' when used('deals', (row) => row['customer'] == id) =>
        'У клиента есть сделки',
      'options'
          when used(
            'cars',
            (row) =>
                row['options'] is List && (row['options'] as List).contains(id),
          ) =>
        'Опция стоит на автомобилях',
      _ => null,
    };
    if (message != null) {
      throw ConflictException(message, fields: {'id': message});
    }
  }

  Map<String, dynamic> _must(String collection, String id) {
    final row = _rows[collection]
        ?.where((item) => item['id'] == id)
        .firstOrNull;
    if (row == null) {
      throw const NotFoundException();
    }
    return row;
  }

  Map<String, dynamic>? _findUser(String email) {
    final normalized = email.trim().toLowerCase();
    return _rows['users']!
        .where((row) => '${row['email']}'.toLowerCase() == normalized)
        .firstOrNull;
  }

  AuthSession _session(Map<String, dynamic> user) {
    final sessionUser = SessionUser.fromRecord(user);
    return AuthSession(token: 'memory:${sessionUser.id}', user: sessionUser);
  }

  String _next() {
    _seq += 1;
    return 'id_$_seq';
  }

  int _compare(dynamic left, dynamic right) {
    if (left is num && right is num) {
      return left.compareTo(right);
    }
    return '$left'.toLowerCase().compareTo('$right'.toLowerCase());
  }
}
