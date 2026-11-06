import 'package:flutter/material.dart';
import 'package:naqsh_office/core/theme/app_theme.dart';
import 'package:naqsh_office/features/auth/auth_repository.dart';
import 'package:naqsh_office/features/auth/login_screen.dart';
import 'package:naqsh_office/features/home/home_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepository = AuthRepository();

    return MaterialApp(
      title: 'NAQSH',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: StreamBuilder(
        stream: authRepository.authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.data != null) {
            return const HomeScreen();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}