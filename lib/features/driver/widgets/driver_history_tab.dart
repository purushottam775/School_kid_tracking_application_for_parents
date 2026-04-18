import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/trip_model.dart';
import '../services/trip_service.dart';

class DriverHistoryTab extends StatelessWidget {
  final String driverId;
  const DriverHistoryTab({super.key, required this.driverId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TripModel>>(
      stream: TripService().streamCompletedTripsForDriver(driverId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final trips = snap.data ?? [];

        if (trips.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.history_rounded,
                    color: AppColors.textHint, size: 52),
                const SizedBox(height: 12),
                Text('No completed trips yet',
                    style: GoogleFonts.outfit(color: AppColors.textSecondary)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          itemCount: trips.length,
          itemBuilder: (_, i) => HistoryTripCard(trip: trips[i]),
        );
      },
    );
  }
}

class HistoryTripCard extends StatefulWidget {
  final TripModel trip;
  const HistoryTripCard({super.key, required this.trip});

  @override
  State<HistoryTripCard> createState() => _HistoryTripCardState();
}

class _HistoryTripCardState extends State<HistoryTripCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    final date = trip.completedAt ?? trip.createdAt;
    final dateStr =
        '${date.day}/${date.month}/${date.year}  ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    final droppedHome = trip.students
        .where((s) => s.status == StudentTripStatus.droppedHome)
        .length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // ── Header row (tap to expand) ────────────────────────────────
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.check_circle_rounded,
                        color: AppColors.success, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bus ${trip.busNumber}',
                            style: GoogleFonts.outfit(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13)),
                        const SizedBox(height: 2),
                        Text(dateStr,
                            style: GoogleFonts.outfit(
                                color: AppColors.textSecondary, fontSize: 11)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$droppedHome/${trip.students.length} home',
                        style: GoogleFonts.outfit(
                            color: AppColors.success,
                            fontSize: 12,
                            fontWeight: FontWeight.w700),
                      ),
                      Icon(
                        _expanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        color: AppColors.textHint,
                        size: 18,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded student detail rows ──────────────────────────────
          if (_expanded && trip.students.isNotEmpty) ...[
            const Divider(height: 1, color: AppColors.divider),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Column(
                children: trip.students.map((s) {
                  final (icon, label, color) = _statusInfo(s.status);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: color.withValues(alpha: 0.25)),
                    ),
                    child: Row(children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          gradient: AppColors.parentGradient,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            s.studentName.isNotEmpty
                                ? s.studentName[0].toUpperCase()
                                : '?',
                            style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(s.studentName,
                            style: GoogleFonts.outfit(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 12)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, size: 11, color: color),
                            const SizedBox(width: 3),
                            Text(label,
                                style: GoogleFonts.outfit(
                                    color: color,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ]),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  (IconData, String, Color) _statusInfo(StudentTripStatus status) {
    switch (status) {
      case StudentTripStatus.droppedHome:
        return (Icons.home_rounded, 'Home', AppColors.success);
      case StudentTripStatus.droppedAtSchool:
        return (Icons.school_rounded, 'At School', AppColors.primary);
      case StudentTripStatus.pickedUp:
        return (Icons.directions_bus_rounded, 'Picked Up', AppColors.driverColor);
      default:
        return (Icons.schedule_rounded, 'Waiting', AppColors.textHint);
    }
  }
}
