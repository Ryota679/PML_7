import 'package:flutter/material.dart';
// Mungkin ada import untuk GoRouter atau Home Screen Anda
import 'package:kantin_app/src/features/auth/presentation/screens/login_screen.dart'; // Contoh

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aplikasi Kantin',
      theme: ThemeData( // Anda bisa memanggil tema dari core/theme
        primarySwatch: Colors.blue,
      ),
      // Di sini Anda akan mengatur GoRouter atau home screen awal
      home: const LoginScreen(), // Ganti dengan screen awal yang sesuai
    );
  }
}