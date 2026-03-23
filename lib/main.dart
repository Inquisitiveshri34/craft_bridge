import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:craft_bridge/firebase_options.dart';
import 'package:craft_bridge/core/theme/app_theme.dart';
import 'package:craft_bridge/core/constants/app_constants.dart';
import 'package:craft_bridge/providers/auth_provider.dart';
import 'package:craft_bridge/providers/product_provider.dart';
import 'package:craft_bridge/providers/order_provider.dart';
import 'package:craft_bridge/providers/cart_provider.dart';
import 'package:craft_bridge/screens/shared/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const CraftBridgeApp());
}

class CraftBridgeApp extends StatelessWidget {
  const CraftBridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
