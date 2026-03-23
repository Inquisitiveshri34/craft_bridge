import 'package:flutter/material.dart';
import 'package:craft_bridge/core/theme/app_theme.dart';
import 'package:craft_bridge/core/constants/app_constants.dart';

void main() => runApp(const CraftBridgeApp());

class CraftBridgeApp extends StatelessWidget {
  const CraftBridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const CraftBridgeHome(),
    );
  }
}

class CraftBridgeHome extends StatefulWidget {
  const CraftBridgeHome({super.key});

  @override
  State<CraftBridgeHome> createState() => _CraftBridgeHomeState();
}

class _CraftBridgeHomeState extends State<CraftBridgeHome> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppConstants.appName,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              AppConstants.appTagline,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
