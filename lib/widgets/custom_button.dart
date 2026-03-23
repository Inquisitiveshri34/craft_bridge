import 'package:flutter/material.dart';

enum ButtonVariant { primary, secondary }

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final ButtonVariant variant;
  final IconData? icon;
  final double? width;

  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.variant = ButtonVariant.primary,
    this.icon,
    this.width,
  });

  Widget _buildChild() {
    if (isLoading) {
      return const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }
    return Text(label);
  }

  @override
  Widget build(BuildContext context) {
    final buttonWidth = width ?? double.infinity;

    if (variant == ButtonVariant.primary) {
      if (icon != null && !isLoading) {
        return SizedBox(
          width: buttonWidth,
          child: ElevatedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon),
            label: Text(label),
          ),
        );
      } else {
        return SizedBox(
          width: buttonWidth,
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            child: _buildChild(),
          ),
        );
      }
    } else {
      if (icon != null && !isLoading) {
        return SizedBox(
          width: buttonWidth,
          child: OutlinedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon),
            label: Text(label),
          ),
        );
      } else {
        return SizedBox(
          width: buttonWidth,
          child: OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            child: _buildChild(),
          ),
        );
      }
    }
  }
}
