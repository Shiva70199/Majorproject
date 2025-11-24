import 'package:flutter/material.dart';

class GlassButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double opacity;

  const GlassButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.padding = const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
    this.borderRadius = 24,
    this.opacity = 0.65,
  });

  @override
  Widget build(BuildContext context) {
    const Color base = Colors.deepPurple;
    return InkWell(
      borderRadius: BorderRadius.circular(borderRadius),
      onTap: onPressed,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: base.withValues(alpha: opacity.clamp(0.0, 1.0)),
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 14,
              offset: const Offset(0, 6),
            )
          ],
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.35)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              base.withValues(
                alpha: (opacity + 0.1).clamp(0.0, 1.0).toDouble(),
              ),
              base.withValues(
                alpha: (opacity - 0.15).clamp(0.0, 1.0).toDouble(),
              ),
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white),
              const SizedBox(width: 10),
            ],
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


