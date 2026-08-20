import 'package:flutter/material.dart';

import 'screens/auth/splash_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const LabLinkApp());
}

class LabLinkApp extends StatelessWidget {
  const LabLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LabLink',
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}