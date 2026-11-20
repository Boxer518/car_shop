import 'package:dio/dio.dart';

import '../catalog/collection_spec.dart';
import '../core/api_exception.dart';
import '../domain/schedule.dart';
import '../models/list_query.dart';
import '../models/page_result.dart';
import '../models/quote.dart';
import '../models/salon_record.dart';
import '../models/session_user.dart';
import 'salon_api.dart';

class PbSalonApi implements SalonApi {
  PbSalonApi(this._dio);

  final Dio _dio;
  SessionUser? actor;

  @override
  void bind(SessionUser? user) {
    actor = user;
  }

  @override
  Future<AuthSession> login(String email, String password) {
    return guard(() async {
      final response = await _dio.post<dynamic>(
        '/api/collections/users/auth-with-password',
        data: {'identity': email.trim(), 'password': password},
      );
      return _session(response.data);
    });
  }

  @override
  Future<AuthSession> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) {
    return guard(() async {
      await _dio.post<dynamic>(
        '/api/collections/users/records',
        data: {
          'email': email.trim(),
          'password': password,
          'passwordConfirm': password,
          'fullName': fullName.trim(),
          'phone': phone.trim(),
          'role': 'buyer',
        },
      );
      return login(email, password);
    });
  }

  @override
  Future<AuthSession> refresh(String token) {
    return guard(() async {
      final response = await _dio.post<dynamic>(
        '/api/collections/users/auth-refresh',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          extra: {'skipRetry': true, 'authRetried': true},
        ),
      );
      return _session(response.data);
    });
  }

  @override
  Future<PageResult<SalonRecord>> list(
    String collection,
    ListQuery query, {
    List<String> searchKeys = const [],
    List<FilterSpec> filters = const [],
    Map<String, String> locked = const {},
    bool trackDeleted = true,
  }) {
    return guard(() async {
      final filter = _filter(query, searchKeys, filters, locked, trackDeleted);
      final response = await _dio.get<dynamic>(
        '/api/collections/$collection/records',
        queryParameters: {
          'page': query.page,
          'perPage': query.size,
          'sort': query.descending ? '-${query.sort}' : query.sort,
          if (filter.isNotEmpty) 'filter': filter,
        },
      );
      final data = response.data as Map;
      final items = (data['items'] as List)
          .map((item) => SalonRecord(Map<String, dynamic>.from(item as Map)))
          .toList();
      return PageResult(
        items: items,
        page: (data['page'] as num).round(),
        size: (data['perPage'] as num).round(),
        total: (data['totalItems'] as num).round(),
      );
    });
  }

  @override
  Future<SalonRecord> read(String collection, String id) {
    return guard(() async {
      final response = await _dio.get<dynamic>(
        '/api/collections/$collection/records/$id',
      );
      return SalonRecord(Map<String, dynamic>.from(response.data as Map));
    });
  }

  @override
  Future<SalonRecord> create(String collection, Map<String, dynamic> body) {
    return guard(() async {
      final response = await _dio.post<dynamic>(
        '/api/collections/$collection/records',
        data: body,
      );
      return SalonRecord(Map<String, dynamic>.from(response.data as Map));
    });
  }

  @override
  Future<SalonRecord> update(
    String collection,
    String id,
    Map<String, dynamic> body,
  ) {
    return guard(() async {
      final response = await _dio.patch<dynamic>(
        '/api/collections/$collection/records/$id',
        data: body,
      );
      return SalonRecord(Map<String, dynamic>.from(response.data as Map));
    });
  }

  @override
  Future<void> hardDelete(String collection, String id) {
    return guard(() async {
      await _dio.delete<dynamic>('/api/collections/$collection/records/$id');
    });
  }

  @override
  Future<void> softDelete(String collection, List<String> ids) async {
    for (final id in ids) {
      await update(collection, id, {'deleted': true});
    }
  }

  @override
  Future<void> restore(String collection, List<String> ids) async {
    for (final id in ids) {
      await update(collection, id, {'deleted': false});
    }
  }

  @override
  Future<PriceQuote> quote({
    required String carId,
    required int discountPercent,
  }) {
    return guard(() async {
      final response = await _dio.post<dynamic>(
        '/api/salon/quote',
        data: {'car': carId, 'discountPercent': discountPercent},
      );
      return PriceQuote.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    });
  }

  @override
  Future<SalonReport> report() {
    return guard(() async {
      final response = await _dio.get<dynamic>('/api/salon/report');
      return SalonReport.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    });
  }

  @override
  Future<List<DriveInterval>> drivesOf(String carId) async {
    final page = await list(
      'test_drives',
      const ListQuery(size: 50, sort: 'startsAt'),
      filters: [
        const FilterSpec(
          key: 'car',
          label: 'Автомобиль',
          kind: FilterKind.relation,
          field: 'car',
        ),
      ],
      locked: {'car': carId},
    );
    return [
      for (final row in page.items)
        DriveInterval(
          id: row.id,
          start: parseSalonDate(row.text('startsAt')) ?? DateTime.now().toUtc(),
          end: parseSalonDate(row.text('endsAt')) ?? DateTime.now().toUtc(),
          status: row.text('status'),
          deleted: row.deleted,
        ),
    ];
  }

  AuthSession _session(dynamic data) {
    final map = data as Map;
    final record = Map<String, dynamic>.from(map['record'] as Map);
    final user = SessionUser.fromRecord(record);
    actor = user;
    return AuthSession(token: '${map['token']}', user: user);
  }

  String _filter(
    ListQuery query,
    List<String> searchKeys,
    List<FilterSpec> filters,
    Map<String, String> locked,
    bool trackDeleted,
  ) {
    final parts = <String>[];
    if (trackDeleted && !query.includeDeleted) {
      parts.add('deleted = false');
    }
    locked.forEach((key, value) {
      parts.add('$key = "${_escape(value)}"');
    });
    if (query.search.isNotEmpty && searchKeys.isNotEmpty) {
      final needle = _escape(query.search);
      parts.add(
        '(${searchKeys.map((key) => '$key ~ "$needle"').join(' || ')})',
      );
    }
    for (final filter in filters) {
      final raw = query.filters[filter.key];
      if (raw != null && raw.isNotEmpty) {
        parts.add(filter.toPocketBase(raw));
      }
    }
    if (parts.isEmpty) {
      return '';
    }
    return parts.join(' && ');
  }

  String _escape(String value) =>
      value.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
}
