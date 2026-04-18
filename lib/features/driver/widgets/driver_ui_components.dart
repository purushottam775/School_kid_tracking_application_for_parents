import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const StatusBadge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.outfit(
                fontSize: 11, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class DriverActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final LinearGradient gradient;
  final Color glowColor;
  final VoidCallback? onPressed;
  final String? disabledLabel;
  final bool isLoading;

  const DriverActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.gradient,
    required this.glowColor,
    this.onPressed,
    this.disabledLabel,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: onPressed != null ? gradient : null,
              color: onPressed == null ? AppColors.surfaceElevated : null,
              borderRadius: BorderRadius.circular(12),
              boxShadow: onPressed != null
                  ? [
                      BoxShadow(
                        color: glowColor.withValues(alpha: 0.3),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : null,
            ),
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : onPressed,
              icon: isLoading && onPressed != null
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Icon(icon, size: 20),
              label: Text(
                label,
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                disabledBackgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
        Builder(
          builder: (context) {
            final dl = disabledLabel;
            if (dl != null) {
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  dl,
                  style: GoogleFonts.outfit(
                      fontSize: 11, color: AppColors.textHint),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class EmptyStateWidget extends StatelessWidget {
  final String msg;

  const EmptyStateWidget(this.msg, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.group_outlined, color: AppColors.textHint, size: 40),
          const SizedBox(height: 10),
          Text(msg,
              style: GoogleFonts.outfit(
                  color: AppColors.textSecondary, fontSize: 14)),
        ],
      ),
    );
  }
}
