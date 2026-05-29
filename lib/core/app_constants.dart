import 'package:flutter/material.dart';

/// Constantes de cores utilizadas no app Daily Company
class AppColors {
  // Cores principais
  static const Color primaryBlue = Color(0xFF005EB8);
  static const Color lightBlue = Color(0xFF2196F3);
  static const Color backgroundColor = Color(0xFFEFF4FB);

  // Cores funcionais
  static const Color successColor = Color(0xFF4CAF50);
  static const Color errorColor = Color(0xFFE53935);
  static const Color warningColor = Color(0xFFFFC107);
  static const Color infoColor = Color(0xFF2196F3);

  // Cores neutras
  static const Color darkText = Colors.black87;
  static const Color lightText = Colors.grey;
  static const Color borderColor = Color(0xFFB0C6E4);
  static const Color fillColor = Color(0xFFF2F2F2);
}

/// Constantes de espaçamento
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
}

/// Constantes de border radius
class AppBorderRadius {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double circle = 50;
}

/// Constantes de tipografia
class AppTextStyles {
  // Heading styles
  static const TextStyle heading1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.darkText,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.darkText,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.darkText,
  );

  // Body styles
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.darkText,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.darkText,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.lightText,
  );

  // Label styles
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: AppColors.darkText,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: AppColors.darkText,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.bold,
    color: AppColors.darkText,
  );
}

/// Constantes de animação
class AppAnimations {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 400);
  static const Duration slow = Duration(milliseconds: 600);

  static const Curve easingCurve = Curves.easeInOut;
}

/// Constantes de validação
class ValidationConstants {
  static const int minNameLength = 3;
  static const int minPasswordLength = 6;
  static const String emailPattern = r'^[^@]+@[^@]+\.[^@]+';
}
