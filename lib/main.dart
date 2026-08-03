import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import Riverpod
import 'core/theme/app_theme.dart';
import 'features/auth/views/login_view.dart';

void main() {
  // ProviderScope stores the state of all your providers
  runApp(const ProviderScope(child: HomeCareApp()));
}

class HomeCareApp extends StatelessWidget {
  const HomeCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HomeCare',
      theme: AppTheme.lightTheme,
      home: const LoginView(),
    );
  }
}