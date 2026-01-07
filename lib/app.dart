import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'main.dart';

class SoulApp extends StatelessWidget {
  const SoulApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Soul Info',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const SoulHomePage(),
    );
  }
}