import '../auth/access.dart';

class SessionUser {
  const SessionUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.phone = '',
    this.customerId = '',
  });

  final String id;
  final String email;
  final String fullName;
  final String phone;
  final AppRole role;
  final String customerId;

  String get displayName => fullName.isEmpty ? email : fullName;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'phone': phone,
      'role': role.name,
      'customer': customerId,
    };
  }

  String encode() {
    return [
      id,
      Uri.encodeComponent(email),
      Uri.encodeComponent(fullName),
      Uri.encodeComponent(phone),
      role.name,
      customerId,
    ].join('|');
  }

  static SessionUser? decode(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final parts = raw.split('|');
    if (parts.length < 6) {
      return null;
    }
    final role = parseRole(parts[4]);
    if (role == null) {
      return null;
    }
    return SessionUser(
      id: parts[0],
      email: Uri.decodeComponent(parts[1]),
      fullName: Uri.decodeComponent(parts[2]),
      phone: Uri.decodeComponent(parts[3]),
      role: role,
      customerId: parts[5],
    );
  }

  factory SessionUser.fromRecord(Map<String, dynamic> json) {
    final role = parseRole('${json['role']}') ?? AppRole.buyer;
    return SessionUser(
      id: '${json['id'] ?? ''}',
      email: '${json['email'] ?? ''}',
      fullName: '${json['fullName'] ?? json['name'] ?? ''}',
      phone: '${json['phone'] ?? ''}',
      role: role,
      customerId: '${json['customer'] ?? ''}',
    );
  }
}

class AuthSession {
  const AuthSession({required this.token, required this.user});

  final String token;
  final SessionUser user;
}
