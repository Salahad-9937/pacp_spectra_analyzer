import 'package:flutter/material.dart';

import '../theme.dart';
import 'panel_card.dart';

class InfoPanel extends StatelessWidget {
  const InfoPanel({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return PanelCard(
      title: 'Информация',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: SelectableText(
          text,
          style: const TextStyle(
            fontSize: 13,
            height: 1.55,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }
}