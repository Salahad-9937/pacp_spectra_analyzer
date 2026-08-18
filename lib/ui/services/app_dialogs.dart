import 'package:flutter/material.dart';

import '../../domain/models.dart';
import '../formatting/processing_report_formatter.dart';

class AppDialogs {
  const AppDialogs._();

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              child: SelectableText(message),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  static Future<void> error(
    BuildContext context,
    String title,
    String message,
  ) {
    return show(context, title: title, message: message);
  }

  static Future<void> warning(
    BuildContext context,
    String title,
    String message,
  ) {
    return show(context, title: title, message: message);
  }

  static Future<void> report(
    BuildContext context,
    ProcessingReport report,
    ProcessingReportFormatter formatter,
  ) {
    return show(
      context,
      title: 'Обработка спектров',
      message: formatter.summary(report),
    );
  }
}