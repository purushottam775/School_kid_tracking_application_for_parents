import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/trip_model.dart';

class TripStudentTile extends StatelessWidget {
  final TripStudentEntry entry;
  final TripStatus tripStatus;
  final VoidCallback onPickedUp;
  final VoidCallback onDroppedHome;

  const TripStudentTile({
    super.key,
    required this.entry,
    required this.tripStatus,
    required this.onPickedUp,
    required this.onDroppedHome,
  });

  @override
  Widget build(BuildContext context) {
    final Color statusColor;
    final IconData statusIcon;

    switch (entry.status) {
      case StudentTripStatus.pickedUp:
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle_rounded;
        break;
      case StudentTripStatus.droppedAtSchool:
        statusColor = AppColors.primary;
        statusIcon = Icons.school_rounded;
        break;
      case StudentTripStatus.boardedReturn:
        statusColor = AppColors.accent;
        statusIcon = Icons.directions_bus_rounded;
        break;
      case StudentTripStatus.droppedHome:
        statusColor = AppColors.success;
        statusIcon = Icons.home_rounded;
        break;
      default:
        statusColor = AppColors.textHint;
        statusIcon = Icons.radio_button_unchecked_rounded;
    }

    final bool canPickUp = tripStatus == TripStatus.morningPickup &&
        entry.status == StudentTripStatus.waiting;
    final bool canDrop = tripStatus == TripStatus.returnTrip &&
        entry.status == StudentTripStatus.boardedReturn;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: AppColors.parentGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  entry.studentName.isNotEmpty
                      ? entry.studentName[0].toUpperCase()
                      : '?',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Name + status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.studentName,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(statusIcon, size: 13, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        entry.status.label,
                        style: GoogleFonts.outfit(
                            fontSize: 12, color: statusColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Action button
            if (canPickUp)
              _chipButton(
                label: 'Pick Up',
                color: AppColors.success,
                onTap: onPickedUp,
              )
            else if (canDrop)
              _chipButton(
                label: 'Drop Home',
                color: AppColors.accent,
                onTap: onDroppedHome,
              )
            else
              Icon(statusIcon, color: statusColor, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _chipButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
              fontSize: 12, color: color, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
