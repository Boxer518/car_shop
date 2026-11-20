enum AppRole { buyer, manager, director }

AppRole? parseRole(String? value) {
  return switch (value) {
    'buyer' => AppRole.buyer,
    'manager' => AppRole.manager,
    'director' => AppRole.director,
    _ => null,
  };
}

String roleLabel(AppRole role) {
  return switch (role) {
    AppRole.buyer => 'Покупатель',
    AppRole.manager => 'Менеджер',
    AppRole.director => 'Директор',
  };
}

bool roleAllows(AppRole role, String path) {
  if (path == '/my-drives' || path.startsWith('/my-drives/')) {
    return role == AppRole.buyer;
  }
  if (path == '/deals' || path.startsWith('/deals/')) {
    return role == AppRole.manager;
  }
  if (path == '/drives' || path.startsWith('/drives/')) {
    return role == AppRole.manager;
  }
  if (path == '/admin' || path.startsWith('/admin/')) {
    return role == AppRole.director;
  }
  if (path == '/customers' || path.startsWith('/customers/')) {
    return role != AppRole.buyer;
  }
  if (path == '/passports' || path.startsWith('/passports/')) {
    return role != AppRole.buyer;
  }
  if (path.endsWith('/new') || path.endsWith('/edit')) {
    return role != AppRole.buyer;
  }
  return true;
}

bool canWrite(AppRole? role, String path) {
  if (role == null) {
    return false;
  }
  return roleAllows(role, '$path/new');
}

String? authRedirect({
  required bool loggedIn,
  required AppRole? role,
  required String matchedPath,
  required String fullUri,
}) {
  final public = matchedPath == '/login' || matchedPath == '/register';
  if (!loggedIn && !public) {
    return '/login?from=${Uri.encodeComponent(fullUri)}';
  }
  if (loggedIn && public) {
    return _safeFrom(fullUri) ?? '/';
  }
  if (!loggedIn || role == null || matchedPath == '/forbidden') {
    return null;
  }
  if (!roleAllows(role, matchedPath)) {
    return '/forbidden';
  }
  return null;
}

String? _safeFrom(String fullUri) {
  final from = Uri.parse(fullUri).queryParameters['from'];
  if (from == null || !from.startsWith('/') || from.startsWith('//')) {
    return null;
  }
  final path = Uri.parse(from).path;
  if (path == '/login' || path == '/register' || path == '/forbidden') {
    return null;
  }
  return from;
}
