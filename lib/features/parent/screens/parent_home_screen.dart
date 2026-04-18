import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../auth/services/auth_provider.dart';
import '../services/student_service.dart';
import '../../driver/services/trip_service.dart';
import '../../../shared/models/student_model.dart';
import '../../../shared/models/trip_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../admin/services/broadcast_service.dart';
import '../widgets/parent_notification_bell.dart';
import 'add_edit_student_screen.dart';
import 'parent_map_screen.dart';
import 'parent_notifications_screen.dart';

class ParentHomeScreen extends StatelessWidget {
  const ParentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // ── App Bar ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, ${user?.name.split(' ').first ?? 'Parent'} 👋',
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Track your child\'s journey',
                          style: GoogleFonts.outfit(
                              fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // ── Notification Bell with live badge ──────────────────
                    ParentNotificationBell(
                      parentUid: user?.uid ?? '',
                      busId: hasStudents ? students.first.busId : '',
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => _showLogoutDialog(context, auth),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          gradient: AppColors.parentGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            (user?.name.isNotEmpty == true)
                                ? user!.name[0].toUpperCase()
                                : 'P',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Content ────────────────────────────────────────────────
              Expanded(
                child: StreamBuilder<List<StudentModel>>(
                  stream: StudentService()
                      .streamStudentsForParent(user?.uid ?? ''),
                  builder: (context, snapshot) {
                    final students = snapshot.data ?? [];
                    final hasStudents = students.isNotEmpty;

                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          // My Children section
                          _buildSectionHeader(
                            context,
                            title: 'My Children',
                            action: hasStudents ? 'Add More' : null,
                            onAction: () => _openAddStudent(context),
                          ),
                          const SizedBox(height: 12),

                          if (!hasStudents) ...[
                            _buildAddFirstChildCard(context),
                          ] else ...[
                            ...students.map(
                              (s) => Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: _StudentCard(
                                  student: s,
                                  onEdit: () => _openEditStudent(context, s),
                                  onDelete: () =>
                                      _confirmDelete(context, s),
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 20),

                          // Quick Actions
                          _buildSectionTitle('Quick Actions'),
                          const SizedBox(height: 12),
                          _buildQuickActions(context),
                          const SizedBox(height: 20),

                      // Timeline / Trip History — per bus
                      if (students.isNotEmpty)
                        _TripHistorySection(students: students),
                      const SizedBox(height: 32),

                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),

      // FAB
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddStudent(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('Add Child',
            style: GoogleFonts.outfit(
                color: Colors.white, fontWeight: FontWeight.w600)),
        elevation: 0,
      ),
    );
  }

  // ── Actions ─────────────────────────────────────────────────────────────

  void _openAddStudent(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddEditStudentScreen()),
    );
  }

  void _openEditStudent(BuildContext context, StudentModel student) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => AddEditStudentScreen(student: student)),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, StudentModel student) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Remove ${student.name}?',
            style: GoogleFonts.outfit(
                color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        content: Text(
            'This will permanently remove ${student.name} from your profile.',
            style: GoogleFonts.outfit(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: GoogleFonts.outfit(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Remove',
                style: GoogleFonts.outfit(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await StudentService().deleteStudent(student.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${student.name} removed'),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  // ── Widgets ─────────────────────────────────────────────────────────────

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    String? action,
    VoidCallback? onAction,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Row(
              children: [
                Text(
                  action,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Icon(Icons.add_circle_rounded,
                    color: AppColors.primary, size: 16),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAddFirstChildCard(BuildContext context) {
    return GestureDetector(
      onTap: () => _openAddStudent(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1C2333), Color(0xFF1C2B45)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 20,
            )
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: AppColors.parentGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.child_care_rounded,
                  color: Colors.white, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              'Add Your Child',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Add your child\'s details to start tracking\ntheir school bus in real-time.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                  fontSize: 13, color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 20),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
              decoration: BoxDecoration(
                gradient: AppColors.parentGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '+ Add Child Now',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
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

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      (Icons.add_circle_outline_rounded, 'Add Child', AppColors.parentColor,
          () => _openAddStudent(context)),
      (Icons.map_rounded, 'Live Map', AppColors.secondary, () {}),
      (Icons.notifications_rounded, 'Alerts', AppColors.warning, () {}),
      (Icons.history_rounded, 'History', AppColors.textSecondary, () {}),
    ];

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: actions.map((a) {
        return GestureDetector(
          onTap: a.$4,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(a.$1, color: a.$3, size: 24),
                const SizedBox(height: 6),
                Text(
                  a.$2,
                  style: GoogleFonts.outfit(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }



  void _showLogoutDialog(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Sign Out',
            style: GoogleFonts.outfit(
                color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to sign out?',
            style: GoogleFonts.outfit(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.outfit(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await auth.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                    context, AppRoutes.welcome, (_) => false);
              }
            },
            child: Text('Sign Out',
                style: GoogleFonts.outfit(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── Student Card Widget ────────────────────────────

class _StudentCard extends StatelessWidget {
  final StudentModel student;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _StudentCard({
    required this.student,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Top: name + class + menu
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: AppColors.parentGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      student.name.isNotEmpty
                          ? student.name[0].toUpperCase()
                          : '👦',
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        student.className,
                        style: GoogleFonts.outfit(
                            fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  color: AppColors.surfaceElevated,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  icon: const Icon(Icons.more_vert_rounded,
                      color: AppColors.textSecondary),
                  onSelected: (val) {
                    if (val == 'edit') onEdit();
                    if (val == 'delete') onDelete();
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(children: [
                        const Icon(Icons.edit_outlined,
                            size: 18, color: AppColors.primary),
                        const SizedBox(width: 10),
                        Text('Edit',
                            style:
                                GoogleFonts.outfit(color: AppColors.textPrimary)),
                      ]),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        const Icon(Icons.delete_outline_rounded,
                            size: 18, color: AppColors.error),
                        const SizedBox(width: 10),
                        Text('Remove',
                            style: GoogleFonts.outfit(color: AppColors.error)),
                      ]),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.divider),

          // Bus + Address info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _infoChip(
                  Icons.location_on_outlined,
                  student.pickupAddress.isNotEmpty
                      ? student.pickupAddress
                      : 'No address set',
                  AppColors.accent,
                ),
                const Spacer(),
                student.busNumber.isNotEmpty
                    ? _infoChip(Icons.directions_bus_rounded,
                        'Bus ${student.busNumber}', AppColors.driverColor)
                    : _infoChip(Icons.directions_bus_outlined,
                        'No bus assigned', AppColors.textHint),
              ],
            ),
          ),

          // Live Trip Status Bar
          _LiveTripStatusBar(student: student),

          // Track Bus button — only if bus is assigned
          if (student.busId.isNotEmpty)
            _buildTrackBusButton(context),
        ],
      ),
    );
  }

  Widget _buildTrackBusButton(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(18),
        ),
      ),
      child: TextButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ParentMapScreen(
                busId: student.busId,
                busNumber: student.busNumber,
                students: [student], // pass for home pin
              ),
            ),
          );
        },
        icon: const Icon(Icons.map_rounded,
            color: AppColors.driverColor, size: 18),
        label: Text(
          'Track Bus ${student.busNumber} Live',
          style: GoogleFonts.outfit(
              color: AppColors.driverColor,
              fontSize: 13,
              fontWeight: FontWeight.w700),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 120),
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
                fontSize: 11, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────── Live Trip Status Bar ────────────────────────────────

class _LiveTripStatusBar extends StatelessWidget {
  final StudentModel student;
  const _LiveTripStatusBar({required this.student});

  @override
  Widget build(BuildContext context) {
    if (student.busId.isEmpty) return _buildBanner(null, null);

    return StreamBuilder<TripModel?>(
      stream: TripService().streamActiveTripForBus(student.busId),
      builder: (context, snap) {
        final trip = snap.data;
        if (trip == null) return _buildBanner(null, null);

        final entry = trip.students
            .where((e) => e.studentId == student.id)
            .firstOrNull;

        return _buildBanner(entry?.status, trip.status);
      },
    );
  }

  Widget _buildBanner(StudentTripStatus? studentStatus, TripStatus? tripStatus) {
    final (icon, label, color, bgColor) = _statusInfo(studentStatus, tripStatus);

    return Container(
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(18),
        ),
        border: Border(top: BorderSide(color: color.withValues(alpha: 0.25))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color),
            ),
          ),
          // Show pulsing dot for active trip
          if (tripStatus != null && tripStatus != TripStatus.completed)
            Row(children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text('Live',
                  style: GoogleFonts.outfit(
                      fontSize: 10,
                      color: color,
                      fontWeight: FontWeight.w700)),
            ]),
        ],
      ),
    );
  }

  (IconData, String, Color, Color) _statusInfo(
      StudentTripStatus? studentStatus, TripStatus? tripStatus) {
    if (studentStatus == null && tripStatus == null) {
      return (
        Icons.home_outlined,
        'No active trip right now',
        AppColors.textHint,
        AppColors.surfaceElevated,
      );
    }

    switch (studentStatus) {
      case StudentTripStatus.waiting:
        return (
          Icons.schedule_rounded,
          'Bus is coming to pick up your child',
          AppColors.driverColor,
          AppColors.driverColor.withValues(alpha: 0.07),
        );
      case StudentTripStatus.pickedUp:
        return (
          Icons.directions_bus_rounded,
          '🚌 Your child is on the bus, heading to school',
          AppColors.driverColor,
          AppColors.driverColor.withValues(alpha: 0.07),
        );
      case StudentTripStatus.droppedAtSchool:
        return (
          Icons.school_rounded,
          '🏫 Your child has arrived at school',
          AppColors.success,
          AppColors.success.withValues(alpha: 0.07),
        );
      case StudentTripStatus.boardedReturn:
        return (
          Icons.directions_bus_rounded,
          '🚌 Your child is on the bus, heading home',
          AppColors.primary,
          AppColors.primary.withValues(alpha: 0.07),
        );
      case StudentTripStatus.droppedHome:
        return (
          Icons.home_rounded,
          '🏠 Your child has arrived home safely!',
          AppColors.success,
          AppColors.success.withValues(alpha: 0.07),
        );
      default:
        // Trip is active but student not yet in it
        return (
          Icons.schedule_rounded,
          'Trip in progress — waiting for driver update',
          AppColors.textHint,
          AppColors.surfaceElevated,
        );
    }
  }
}


// ------------------------ Trip History Section -------------------------------


class _TripHistorySection extends StatelessWidget {
  final List<StudentModel> students;
  const _TripHistorySection({required this.students});

  @override
  Widget build(BuildContext context) {
    final busIds = students
        .where((s) => s.busId.isNotEmpty)
        .map((s) => s.busId)
        .toSet()
        .toList();

    if (busIds.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            'Trip History',
            style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary),
          ),
        ),
        const SizedBox(height: 10),
        ...busIds.map((busId) {
          final busNumber =
              students.firstWhere((s) => s.busId == busId).busNumber;
          return _BusTripHistory(busId: busId, busNumber: busNumber);
        }),
      ],
    );
  }
}

class _BusTripHistory extends StatelessWidget {
  final String busId;
  final String busNumber;
  const _BusTripHistory({required this.busId, required this.busNumber});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TripModel>>(
      stream: TripService().streamCompletedTripsForBus(busId),
      builder: (context, snap) {
        final trips = snap.data ?? [];

        if (trips.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(children: [
              const Icon(Icons.history_rounded,
                  color: AppColors.textHint, size: 32),
              const SizedBox(width: 14),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Bus $busNumber',
                    style: GoogleFonts.outfit(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700)),
                Text('No completed trips yet',
                    style: GoogleFonts.outfit(
                        color: AppColors.textSecondary, fontSize: 12)),
              ]),
            ]),
          );
        }

        return Column(
          children: trips.map((t) => _TripHistoryTile(trip: t)).toList(),
        );
      },
    );
  }
}

class _TripHistoryTile extends StatelessWidget {
  final TripModel trip;
  const _TripHistoryTile({required this.trip});

  @override
  Widget build(BuildContext context) {
    final date = trip.completedAt ?? trip.createdAt;
    final dateStr =
        '${date.day}/${date.month}/${date.year}  ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    final pickedCount = trip.students
        .where((s) =>
            s.status == StudentTripStatus.droppedAtSchool ||
            s.status == StudentTripStatus.droppedHome ||
            s.status == StudentTripStatus.boardedReturn ||
            s.status == StudentTripStatus.pickedUp)
        .length;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
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
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Bus ${trip.busNumber} � Completed',
                style: GoogleFonts.outfit(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
            const SizedBox(height: 2),
            Text(dateStr,
                style: GoogleFonts.outfit(
                    color: AppColors.textSecondary, fontSize: 11)),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('$pickedCount/${trip.students.length}',
              style: GoogleFonts.outfit(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }
}
