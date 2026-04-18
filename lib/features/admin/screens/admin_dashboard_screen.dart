import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/services/auth_provider.dart';
import '../../auth/models/user_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import 'admin_students_screen.dart';
import 'admin_users_screen.dart';
import 'admin_trip_history_screen.dart';
import 'admin_school_settings_screen.dart';
import 'admin_broadcast_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  // ── Live stat streams ────────────────────────────────────────────────────────
  static Stream<int> _studentCount() => FirebaseFirestore.instance
      .collection('students')
      .snapshots()
      .map((s) => s.size);

  static Stream<int> _busCount() => FirebaseFirestore.instance
      .collection('buses')
      .snapshots()
      .map((s) => s.size);

  static Stream<int> _driverCount() => FirebaseFirestore.instance
      .collection('users')
      .where('role', isEqualTo: UserRole.driver.value)
      .snapshots()
      .map((s) => s.size);

  static Stream<int> _parentCount() => FirebaseFirestore.instance
      .collection('users')
      .where('role', isEqualTo: UserRole.parent.value)
      .snapshots()
      .map((s) => s.size);

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
              // ── Header ──────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Admin Dashboard 🛡️',
                        style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    Text(user?.name ?? 'Administrator',
                        style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: AppColors.textSecondary)),
                  ]),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _showLogoutDialog(context, auth),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                          gradient: AppColors.adminGradient,
                          borderRadius: BorderRadius.circular(12)),
                      child: Center(
                        child: Text(
                          user?.name.isNotEmpty == true
                              ? user!.name[0].toUpperCase()
                              : 'A',
                          style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ]),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(children: [
                    // ── Live Stats Grid ────────────────────────────────────
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.5,
                      children: [
                        _LiveStatCard(
                            stream: _studentCount(),
                            label: 'Total Students',
                            icon: Icons.child_care_rounded,
                            color: AppColors.parentColor),
                        _LiveStatCard(
                            stream: _busCount(),
                            label: 'Total Buses',
                            icon: Icons.directions_bus_rounded,
                            color: AppColors.driverColor),
                        _LiveStatCard(
                            stream: _parentCount(),
                            label: 'Total Parents',
                            icon: Icons.family_restroom_rounded,
                            color: AppColors.secondary),
                        _LiveStatCard(
                            stream: _driverCount(),
                            label: 'Total Drivers',
                            icon: Icons.drive_eta_rounded,
                            color: AppColors.adminColor),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── Section title ──────────────────────────────────────
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Management',
                          style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                    ),
                    const SizedBox(height: 12),

                    // ── Management tiles ───────────────────────────────────
                    _buildManagementTiles(context),
                    const SizedBox(height: 32),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildManagementTiles(BuildContext context) {
    final tiles = [
      (
        Icons.group_rounded,
        'Students',
        'View & manage students',
        AppColors.parentColor,
        () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AdminStudentsScreen()))
      ),
      (
        Icons.directions_bus_rounded,
        'Buses',
        'Manage buses & drivers',
        AppColors.driverColor,
        () => Navigator.pushNamed(context, AppRoutes.adminBuses)
      ),
      (
        Icons.people_rounded,
        'Users',
        'Manage parents, drivers & admins',
        AppColors.secondary,
        () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AdminUsersScreen()))
      ),
      (
        Icons.school_rounded,
        'School Location',
        'Pin school destination on map',
        AppColors.adminColor,
        () => Navigator.push(context,
            MaterialPageRoute(
                builder: (_) => const AdminSchoolSettingsScreen()))
      ),
      (
        Icons.history_rounded,
        'Trip History',
        'All trips across all buses',
        AppColors.success,
        () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AdminTripHistoryScreen()))
      ),
      (
        Icons.campaign_rounded,
        'Broadcast',
        'Send notification to all parents',
        AppColors.adminColor,
        () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AdminBroadcastScreen()))
      ),
    ];

    return Column(
      children: tiles.map((t) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            onTap: t.$5,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.border),
            ),
            tileColor: AppColors.surfaceElevated,
            leading: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                  color: t.$4.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(t.$1, color: t.$4, size: 20),
            ),
            title: Text(t.$2,
                style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            subtitle: Text(t.$3,
                style: GoogleFonts.outfit(
                    fontSize: 12, color: AppColors.textSecondary)),
            trailing: const Icon(Icons.chevron_right,
                color: AppColors.textHint, size: 18),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Sign Out',
            style: GoogleFonts.outfit(
                color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        content: Text('Are you sure?',
            style: GoogleFonts.outfit(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: GoogleFonts.outfit(color: AppColors.textSecondary))),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await auth.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                    context, AppRoutes.welcome, (_) => false);
              }
            },
            child:
                Text('Sign Out', style: GoogleFonts.outfit(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

// ── Live stat card ────────────────────────────────────────────────────────────

class _LiveStatCard extends StatelessWidget {
  final Stream<int> stream;
  final String label;
  final IconData icon;
  final Color color;

  const _LiveStatCard({
    required this.stream,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 24),
          StreamBuilder<int>(
            stream: stream,
            builder: (context, snap) {
              final value = snap.data ?? 0;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value.toString(),
                      style: GoogleFonts.outfit(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary)),
                  Text(label,
                      style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: AppColors.textSecondary)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
