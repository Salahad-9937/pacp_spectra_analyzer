import 'package:flutter/material.dart';

class LabeledDropdown<T> extends StatelessWidget {
  const LabeledDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    this.onChanged,
    this.isExpanded = true,
  });

  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: DropdownButtonFormField<T>(
        // ValueKey принудительно пересоздаёт FormField при смене value,
        // так как initialValue применяется только при initState.
        key: ValueKey<T?>(value),
        initialValue: value,
        isExpanded: isExpanded,
        decoration: const InputDecoration(
          labelText: null,
          border: OutlineInputBorder(),
          isDense: true,
        ),
        items: items,
        onChanged: onChanged,
      ),
    );
  }
}