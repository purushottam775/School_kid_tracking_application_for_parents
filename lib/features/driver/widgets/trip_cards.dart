import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/trip_model.dart';
import 'driver_ui_components.dart';

class IdleTripCard extends StatelessWidget {
  final VoidCallback onStartTrip;
  final bool isLoading;

  const IdleTripCard({
    super.key,
    required this.onStartTrip,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D2B1D), Color(0xFF1C2333)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.driverColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StatusBadge(label: 'Idle', color: AppColors.textHint),
          const SizedBox(height: 20),
          Text(
            'Ready to Start?',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Start your morning trip to begin picking up students.',
            style: GoogleFonts.outfit(
                fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          DriverActionButton(
            label: 'Start Morning Trip',
            icon: Icons.play_arrow_rounded,
            gradient: AppColors.driverGradient,
            glowColor: AppColors.driverColor,
            isLoading: isLoading,
            onPressed: onStartTrip,
          ),
        ],
      ),
    );
  }
}

class MorningPickupCard extends StatelessWidget {
  final TripModel trip;
  final VoidCallback onReachedSchool;
  final bool isLoading;

  const MorningPickupCard({
    super.key,
    required this.trip,
    required this.onReachedSchool,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final picked =
        trip.students.where((s) => s.status == StudentTripStatus.pickedUp).length;
    final total = trip.students.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A2E1A), Color(0xFF1C2333)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const StatusBadge(label: 'Morning Pickup', color: AppColors.success),
              const Spacer(),
              Text(
                '$picked/$total picked up',
                style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total > 0 ? picked / total : 0,
              backgroundColor: AppColors.border,
              color: AppColors.success,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 20),
          DriverActionButton(
            label: 'Reached School',
            icon: Icons.school_rounded,
            gradient: const LinearGradient(
                colors: [Color(0xFF4F8EF7), Color(0xFF06B6D4)]),
            glowColor: AppColors.primary,
            isLoading: isLoading,
            onPressed: picked == total ? onReachedSchool : null,
            disabledLabel: picked < total ? 'Pick up all students first' : null,
          ),
        ],
      ),
    );
  }
}

class AtSchoolCard extends StatelessWidget {
  final VoidCallback onStartReturn;
  final bool isLoading;

  const AtSchoolCard({
    super.key,
    required this.onStartReturn,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF1C2333)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StatusBadge(label: 'At School 🎓', color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            'All students are at school.',
            style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap "Start Return Trip" when school is over.',
            style: GoogleFonts.outfit(
                fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          DriverActionButton(
            label: 'Start Return Trip',
            icon: Icons.home_rounded,
            gradient: const LinearGradient(
                colors: [Color(0xFFF97316), Color(0xFFEF4444)]),
            glowColor: AppColors.accent,
            isLoading: isLoading,
            onPressed: onStartReturn,
          ),
        ],
      ),
    );
  }
}

class ReturnTripCard extends StatelessWidget {
  final TripModel trip;
  final VoidCallback onEndTrip;
  final bool isLoading;

  const ReturnTripCard({
    super.key,
    required this.trip,
    required this.onEndTrip,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final dropped =
        trip.students.where((s) => s.status == StudentTripStatus.droppedHome).length;
    final total = trip.students.length;
    final allDropped = dropped == total;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E1A0E), Color(0xFF1C2333)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const StatusBadge(label: 'Return Trip 🏠', color: AppColors.accent),
              const Spacer(),
              Text(
                '$dropped/$total dropped',
                style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total > 0 ? dropped / total : 0,
              backgroundColor: AppColors.border,
              color: AppColors.accent,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 20),
          DriverActionButton(
            label: 'End Trip',
            icon: Icons.stop_circle_rounded,
            gradient: const LinearGradient(
                colors: [Color(0xFFF85149), Color(0xFFB91C1C)]),
            glowColor: AppColors.error,
            isLoading: isLoading,
            onPressed: allDropped ? onEndTrip : null,
            disabledLabel: !allDropped ? 'Drop all students first' : null,
          ),
        ],
      ),
    );
  }
}
