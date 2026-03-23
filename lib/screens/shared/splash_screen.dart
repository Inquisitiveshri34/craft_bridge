import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:craft_bridge/providers/auth_provider.dart';
import 'package:craft_bridge/core/constants/app_constants.dart';
import 'package:craft_bridge/screens/shared/role_router_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthAndNavigate();
    });
  }

  void _checkAuthAndNavigate() {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.isInitialized) {
      _navigate();
    } else {
      authProvider.addListener(_onAuthStateChanged);
    }
  }

  void _onAuthStateChanged() {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.isInitialized && !_hasNavigated) {
      authProvider.removeListener(_onAuthStateChanged);
      _navigate();
    }
  }

  void _navigate() {
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const RoleRouterScreen()),
    );
  }

  @override
  void dispose() {
    context.read<AuthProvider>().removeListener(_onAuthStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shopping_bag_outlined,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                AppConstants.appName,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                AppConstants.appTagline,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
              ),
              const SizedBox(height: 48),
              CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
