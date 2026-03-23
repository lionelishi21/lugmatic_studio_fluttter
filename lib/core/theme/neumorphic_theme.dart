import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class NeumorphicTheme {
  static const Color backgroundColor = AppColors.background;
  static const Color surfaceColor = AppColors.card;
  static const Color cardColor = AppColors.card;

  static const Color primaryAccent = AppColors.primary;
  static const Color secondaryAccent = AppColors.secondary;

  static const Color textPrimary = AppColors.foreground;
  static const Color textSecondary = AppColors.mutedForeground;

  static const Color lightShadow = Color(0x0DFFFFFF);
  static const Color darkShadow = Color(0x99000000);

  static List<BoxShadow> get neumorphicShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.4),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];

  static BoxDecoration cardDecoration({
    BorderRadius? borderRadius,
    Color? color,
  }) {
    return BoxDecoration(
      color: color ?? AppColors.glassBg,
      borderRadius: borderRadius ?? BorderRadius.circular(24),
      border: Border.all(color: AppColors.border, width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.4),
          blurRadius: 40,
          offset: const Offset(0, 20),
        ),
      ],
    );
  }

  static BoxDecoration neumorphicDecoration({
    Color? color,
    BorderRadius? borderRadius,
    bool isPressed = false,
  }) {
    return BoxDecoration(
      color: color ?? surfaceColor,
      borderRadius: borderRadius ?? BorderRadius.circular(20),
      border: Border.all(color: AppColors.border, width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(isPressed ? 0.2 : 0.4),
          blurRadius: isPressed ? 6 : 16,
          offset: Offset(0, isPressed ? 2 : 8),
        ),
      ],
    );
  }

  static InputDecoration cardInputDecoration({
    required String label,
    required String hint,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(
        color: AppColors.mutedForeground,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      hintStyle: const TextStyle(
        color: AppColors.mutedForeground,
        fontSize: 14,
      ),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: AppColors.mutedForeground, size: 18)
          : null,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.input,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
            color: AppColors.primary.withOpacity(0.5), width: 1.5),
      ),
    );
  }

  static InputDecoration neumorphicInputDecoration({
    required String label,
    required String hint,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) =>
      cardInputDecoration(
          label: label,
          hint: hint,
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon);
}
