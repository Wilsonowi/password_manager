import 'package:flutter/material.dart';
import 'package:password_manager/screens/main_screen.dart';
import 'screens/lock_screen.dart';
import '../services/encryption_service.dart';

void main() {
  // Initialize the encryption service
  EncryptionService();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KeySafe',
      debugShowCheckedModeBanner: false,
      home: const MainScreen(),
    );
  }
}
