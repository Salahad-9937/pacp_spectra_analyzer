import 'package:flutter/material.dart';

import 'ui/main_page.dart';
import 'ui/theme.dart';

void main() {
  runApp(const SpectrumApp());
}

class SpectrumApp extends StatelessWidget {
  const SpectrumApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Просмотр и обработка спектров',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      home: const SpectrumDesktopPage(),
    );
  }
}