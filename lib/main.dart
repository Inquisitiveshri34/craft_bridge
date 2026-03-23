import 'package:flutter/material.dart';

void main() => runApp(const CraftBridgeApp());

class CraftBridgeApp extends StatelessWidget {
  const CraftBridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CraftBridge',
      debugShowCheckedModeBanner: false,
      home: const Scaffold(
        body: Center(
          child: Text('Hello CraftBridge'),
        ),
      ),
    );
  }
}
