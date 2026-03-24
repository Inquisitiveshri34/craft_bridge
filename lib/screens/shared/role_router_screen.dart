import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:craft_bridge/providers/auth_provider.dart';
import 'package:craft_bridge/core/constants/app_constants.dart';
import 'package:craft_bridge/screens/auth/login_screen.dart';
import 'package:craft_bridge/screens/artisan/artisan_home_screen.dart';
import 'package:craft_bridge/screens/buyer/buyer_home_screen.dart';
import 'package:craft_bridge/screens/admin/admin_home_screen.dart';

class RoleRouterScreen extends StatelessWidget {
  const RoleRouterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (!authProvider.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (authProvider.currentUser == null) {
      return const LoginScreen();
    }

    if (authProvider.currentUser!.role == AppConstants.roleAdmin) {
      return const AdminHomeScreen();
    }

    if (authProvider.currentUser!.role == AppConstants.roleArtisan &&
        authProvider.currentUser!.isApproved) {
      return const ArtisanHomeScreen();
    }

    if (authProvider.currentUser!.role == AppConstants.roleArtisan &&
        !authProvider.currentUser!.isApproved) {
      return const _PendingApprovalScreen();
    }

    return const BuyerHomeScreen();
  }
}

class _PendingApprovalScreen extends StatelessWidget {
  const _PendingApprovalScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Approval'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.hourglass_empty_rounded,
                  size: 72,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Account Pending Approval',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your artisan account is under review. You will be able to access your shop once an admin approves your registration.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => context.read<AuthProvider>().signOut(),
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign Out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
