import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';

class CraftingMposApp extends StatelessWidget {
  const CraftingMposApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CraftingMPOS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const DashboardScreen(),
    );
  }
}
