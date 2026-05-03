import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class RentBadge extends StatelessWidget {
  final bool isRenter;
  final double? fontSize;
  final EdgeInsetsGeometry? padding;

  const RentBadge({
    super.key, 
    required this.isRenter,
    this.fontSize,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    if (!isRenter) return const SizedBox.shrink();

    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.orange, width: 0.5),
      ),
      child: Text(
        'RENT',
        style: TextStyle(
          color: Colors.orange[800],
          fontSize: fontSize ?? 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
