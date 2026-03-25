import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:craft_bridge/core/theme/app_theme.dart';
import 'package:craft_bridge/providers/auth_provider.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Home'),
        actions: [
          Consumer<ThemeProvider>(
            builder: (_, themeProvider, __) => IconButton(
              icon: Icon(
                themeProvider.isDarkMode
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
              ),
              tooltip: themeProvider.isDarkMode
                  ? 'Switch to light mode'
                  : 'Switch to dark mode',
              onPressed: () => context.read<ThemeProvider>().toggleTheme(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () => context.read<AuthProvider>().signOut(),
          ),
        ],
      ),
      body: const Center(
        child: Text('AdminHomeScreen shell — full implementation in PR48'),
      ),
    );
  }
}
