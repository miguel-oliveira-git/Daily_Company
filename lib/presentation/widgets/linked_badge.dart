import 'package:flutter/material.dart';

/// Widget customizado para exibir o badge/tag de vínculo
class LinkedBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;

  const LinkedBadge({
    super.key,
    required this.label,
    this.icon = Icons.check_circle,
    this.backgroundColor = const Color(0xFF4CAF50),
    this.textColor = Colors.white,
    this.borderColor = const Color(0xFF4CAF50),
  });

  factory LinkedBadge.linked() => const LinkedBadge(
        label: 'Vinculado',
        icon: Icons.check_circle,
        backgroundColor: Color(0x264CAF50), // Verde com transparência
        textColor: Color(0xFF4CAF50),
        borderColor: Color(0xFF4CAF50),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
