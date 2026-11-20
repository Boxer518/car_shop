import 'package:go_router/go_router.dart';

import 'auth/access.dart';
import 'auth/auth_notifier.dart';
import 'catalog/catalog.dart';
import 'models/list_query.dart';
import 'screens/catalog_screen.dart';
import 'screens/forbidden_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/record_details_screen.dart';
import 'screens/record_form_screen.dart';
import 'screens/register_screen.dart';
import 'screens/report_screen.dart';
import 'screens/users_screen.dart';

GoRouter buildRouter(AuthNotifier? auth) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: auth,
    redirect: auth == null
        ? null
        : (context, state) {
            return authRedirect(
              loggedIn: auth.isAuthenticated,
              role: auth.role,
              matchedPath: state.matchedLocation,
              fullUri: state.uri.toString(),
            );
          },
    errorBuilder: (context, state) => const NotFoundScreen(),
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      for (final spec in catalogSpecs)
        GoRoute(
          path: spec.path,
          builder: (context, state) => CatalogScreen(
            spec: spec,
            query: ListQuery.fromParameters(
              state.uri.queryParameters,
              defaultSort: spec.defaultSort,
              allowedSorts: spec.sorts.map((item) => item.value).toSet(),
            ),
          ),
          routes: [
            GoRoute(
              path: 'new',
              builder: (context, state) => RecordFormScreen(spec: spec),
            ),
            GoRoute(
              path: ':id',
              builder: (context, state) => RecordDetailsScreen(
                spec: spec,
                id: state.pathParameters['id']!,
              ),
              routes: [
                GoRoute(
                  path: 'edit',
                  builder: (context, state) => RecordFormScreen(
                    spec: spec,
                    id: state.pathParameters['id'],
                  ),
                ),
              ],
            ),
          ],
        ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forbidden',
        builder: (context, state) => const ForbiddenScreen(),
      ),
      GoRoute(
        path: '/admin/report',
        builder: (context, state) => const ReportScreen(),
      ),
      GoRoute(
        path: '/admin/users',
        builder: (context, state) => const UsersScreen(),
      ),
    ],
  );
}
