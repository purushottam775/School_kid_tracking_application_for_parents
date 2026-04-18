import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/bus_model.dart';
import '../../../shared/models/student_model.dart';
import '../../../shared/models/trip_model.dart';
import '../../parent/services/student_service.dart';
import '../services/trip_service.dart';
import 'trip_student_tile.dart';

class DriverStudentsTab extends StatelessWidget {
  final BusModel bus;
  final TripModel? trip;
  final Future<void> Function(Future<void> Function()) doAction;

  const DriverStudentsTab({
    super.key,
    required this.bus,
    required this.trip,
    required this.doAction,
  });

  @override
  Widget build(BuildContext context) {
    if (trip == null) {
      // Pre-trip: show assigned students from Firestore
      return StreamBuilder<List<StudentModel>>(
        stream: StudentService().streamStudentsForBus(bus.id),
        builder: (context, snap) {
          final students = snap.data ?? [];
          if (students.isEmpty) {
            return _emptyStudents(
                'No students assigned to this bus yet.\nAsk your Admin to assign students.');
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            itemCount: students.length,
            itemBuilder: (_, i) => _preStudentTile(students[i]),
          );
        },
      );
    }

    // Active trip
    final currentTrip = trip!;
    if (currentTrip.students.isEmpty) {
      return _emptyStudents('No students on this trip.');
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      itemCount: currentTrip.students.length,
      itemBuilder: (_, i) {
        final entry = currentTrip.students[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: TripStudentTile(
            entry: entry,
            tripStatus: currentTrip.status,
            onPickedUp: () => doAction(() =>
                TripService().markStudentPickedUp(currentTrip, entry.studentId)),
            onDroppedHome: () => doAction(() =>
                TripService().markStudentDroppedHome(currentTrip, entry.studentId)),
          ),
        );
      },
    );
  }

  Widget _preStudentTile(StudentModel student) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
              gradient: AppColors.parentGradient,
              borderRadius: BorderRadius.circular(10)),
          child: Center(
            child: Text(
              student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
              style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(student.name,
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontSize: 14)),
              Text(student.className,
                  style: GoogleFonts.outfit(
                      color: AppColors.textSecondary, fontSize: 11)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
              color: AppColors.textHint.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8)),
          child: Text('Pre-trip',
              style: GoogleFonts.outfit(
                  color: AppColors.textHint, fontSize: 10)),
        ),
      ]),
    );
  }

  Widget _emptyStudents(String msg) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.people_outline_rounded,
              color: AppColors.textHint, size: 52),
          const SizedBox(height: 12),
          Text(msg,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
