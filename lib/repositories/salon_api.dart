import '../catalog/collection_spec.dart';
import '../domain/schedule.dart';
import '../models/list_query.dart';
import '../models/page_result.dart';
import '../models/quote.dart';
import '../models/salon_record.dart';
import '../models/session_user.dart';

abstract class SalonApi {
  void bind(SessionUser? user);

  Future<AuthSession> login(String email, String password);

  Future<AuthSession> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  });

  Future<AuthSession> refresh(String token);

  Future<PageResult<SalonRecord>> list(
    String collection,
    ListQuery query, {
    List<String> searchKeys = const [],
    List<FilterSpec> filters = const [],
    Map<String, String> locked = const {},
    bool trackDeleted = true,
  });

  Future<SalonRecord> read(String collection, String id);

  Future<SalonRecord> create(String collection, Map<String, dynamic> body);

  Future<SalonRecord> update(
    String collection,
    String id,
    Map<String, dynamic> body,
  );

  Future<void> hardDelete(String collection, String id);

  Future<void> softDelete(String collection, List<String> ids);

  Future<void> restore(String collection, List<String> ids);

  Future<PriceQuote> quote({
    required String carId,
    required int discountPercent,
  });

  Future<SalonReport> report();

  Future<List<DriveInterval>> drivesOf(String carId);
}
