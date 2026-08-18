import 'package:flutter/material.dart';

class CompactCheckboxTile extends StatelessWidget {
  const CompactCheckboxTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: CheckboxListTile(
        value: value,
        onChanged: enabled
            ? (checked) {
                onChanged(checked ?? false);
              }
            : null,
        title: Text(title),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero,
        dense: true,
      ),
    );
  }
}