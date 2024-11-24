import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';
import 'auth_state.dart';
import '../../screens/unauthorized_page.dart';

class AuthGuard extends StatelessWidget {
  final Widget child;
  final String? requiredPermission;
  final List<String>? requiredPermissions;
  final bool requireAll;
  final Widget? unauthorizedPage;

  const AuthGuard({
    Key? key,
    required this.child,
    this.requiredPermission,
    this.requiredPermissions,
    this.requireAll = false,
    this.unauthorizedPage,
  })  : assert(
          (requiredPermission == null) != (requiredPermissions == null),
          'Provide either requiredPermission or requiredPermissions, not both or neither',
        ),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final state = authProvider.state;

        if (state.status == AuthStatus.loading) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Loading...',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          );
        }

        if (state.status == AuthStatus.error) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    state.error ?? 'Authentication error',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => authProvider.signOut(),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                    child: const Text('Sign Out'),
                  ),
                ],
              ),
            ),
          );
        }

        if (!state.isAuthenticated) {
          return unauthorizedPage ?? const UnauthorizedPage();
        }

        bool hasRequiredPermissions = true;
        if (requiredPermission != null) {
          hasRequiredPermissions =
              authProvider.hasPermission(requiredPermission!);
        } else if (requiredPermissions != null) {
          hasRequiredPermissions = requireAll
              ? authProvider.hasAllPermissions(requiredPermissions!)
              : authProvider.hasAnyPermission(requiredPermissions!);
        }

        if (!hasRequiredPermissions) {
          return unauthorizedPage ?? const UnauthorizedPage();
        }

        return child;
      },
    );
  }
}

class PermissionAware extends StatelessWidget {
  final Widget child;
  final String? requiredPermission;
  final List<String>? requiredPermissions;
  final bool requireAll;
  final Widget? fallback;

  const PermissionAware({
    Key? key,
    required this.child,
    this.requiredPermission,
    this.requiredPermissions,
    this.requireAll = false,
    this.fallback,
  })  : assert(
          (requiredPermission == null) != (requiredPermissions == null),
          'Provide either requiredPermission or requiredPermissions, not both or neither',
        ),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        bool hasRequiredPermissions = true;
        if (requiredPermission != null) {
          hasRequiredPermissions =
              authProvider.hasPermission(requiredPermission!);
        } else if (requiredPermissions != null) {
          hasRequiredPermissions = requireAll
              ? authProvider.hasAllPermissions(requiredPermissions!)
              : authProvider.hasAnyPermission(requiredPermissions!);
        }

        if (!hasRequiredPermissions) {
          return fallback ?? const SizedBox.shrink();
        }

        return child;
      },
    );
  }
}
