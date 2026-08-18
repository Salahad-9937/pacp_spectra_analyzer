import 'package:flutter/material.dart';

class ButtonBusyIndicator extends StatelessWidget {
  const ButtonBusyIndicator({
    super.key,
    this.size = 15,
    this.strokeWidth = 2,
  });

  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
      ),
    );
  }
}