import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../auth/models/user_model.dart';
import '../services/user_service.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen>
    with SingleTickerProviderStateMixin {
  final UserService _service = UserService();
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Color _roleColor(UserRole r) {
    switch (r) {
      case UserRole.parent:
        return AppColors.parentColor;
      case UserRole.driver:
        return AppColors.driverColor;
      case UserRole.admin:
        return AppColors.adminColor;
    }
  }

  IconData _roleIcon(UserRole r) {
    switch (r) {
      case UserRole.parent:
        return Icons.family_restroom_rounded;
      case UserRole.driver:
        return Icons.drive_eta_rounded;
      case UserRole.admin:
        return Icons.shield_rounded;
    }
  }

  void _showEditDialog(UserModel user) {
    final nameCtrl = TextEditingController(text: user.name);
    final phoneCtrl = TextEditingController(text: user.phone);
    UserRole selectedRole = user.role;
    bool loading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setD) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceElevated,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Edit User',
              style: GoogleFonts.outfit(
                  color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              CustomTextField(
                  controller: nameCtrl,
                  label: 'Full Name',
                  prefixIcon: Icons.person_outline),
              const SizedBox(height: 12),
              CustomTextField(
                  controller: phoneCtrl,
                  label: 'Phone',
                  prefixIcon: Icons.phone_outlined),
              const SizedBox(height: 12),
              DropdownButtonFormField<UserRole>(
                initialValue: selectedRole,
                dropdownColor: AppColors.surfaceElevated,
                decoration: InputDecoration(
                  labelText: 'Role',
                  labelStyle:
                      GoogleFonts.outfit(color: AppColors.textSecondary),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border)),
                ),
                style: GoogleFonts.outfit(color: AppColors.textPrimary),
                items: UserRole.values
                    .map((r) => DropdownMenuItem(
                        value: r,
                        child: Text(r.value,
                            style: GoogleFonts.outfit(
                                color: AppColors.textPrimary))))
                    .toList(),
                onChanged: (v) => setD(() => selectedRole = v!),
              ),
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel',
                    style: GoogleFonts.outfit(color: AppColors.textSecondary))),
            if (loading)
              const Padding(
                  padding: EdgeInsets.all(8),
                  child:
                      CircularProgressIndicator(color: AppColors.primary))
            else
              TextButton(
                onPressed: () async {
                  setD(() => loading = true);
                  try {
                    await _service.updateUser(user.uid,
                        name: nameCtrl.text.trim(),
                        phone: phoneCtrl.text.trim(),
                        role: selectedRole);
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('User updated'),
                          backgroundColor: AppColors.success));
                    }
                  } catch (e) {
                    setD(() => loading = false);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: AppColors.error));
                    }
                  }
                },
                child: Text('Save',
                    style: GoogleFonts.outfit(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700)),
              ),
          ],
        );
      }),
    );
  }

  void _confirmDelete(UserModel user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete User?',
            style: GoogleFonts.outfit(
                color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        content: Text(
            'Remove ${user.name} (${user.role.value}) from Firestore? '
            'Their login account remains until you remove it from Firebase Auth.',
            style: GoogleFonts.outfit(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: GoogleFonts.outfit(color: AppColors.textSecondary))),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _service.deleteUser(user.uid, user.role);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('User removed'),
                      backgroundColor: AppColors.success));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: AppColors.error));
                }
              }
            },
            child: Text('Delete',
                style: GoogleFonts.outfit(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Widget _buildList(UserRole role) {
    return StreamBuilder<List<UserModel>>(
      stream: _service.streamUsersByRole(role),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final users = snap.data ?? [];
        if (users.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_roleIcon(role),
                    size: 48, color: AppColors.textHint),
                const SizedBox(height: 12),
                Text('No ${role.value}s registered yet',
                    style: GoogleFonts.outfit(color: AppColors.textSecondary)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (_, i) {
            final u = users[i];
            final color = _roleColor(u.role);
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6),
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10)),
                  child: Center(
                    child: Text(
                      u.name.isNotEmpty ? u.name[0].toUpperCase() : '?',
                      style: GoogleFonts.outfit(
                          color: color,
                          fontSize: 18,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                title: Text(u.name,
                    style: GoogleFonts.outfit(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                subtitle: Text(u.email,
                    style: GoogleFonts.outfit(
                        color: AppColors.textSecondary, fontSize: 11)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_rounded,
                          color: AppColors.primary, size: 18),
                      onPressed: () => _showEditDialog(u),
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_rounded,
                          color: AppColors.error, size: 18),
                      onPressed: () => _confirmDelete(u),
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Manage Users',
            style: GoogleFonts.outfit(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        bottom: TabBar(
          controller: _tab,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: 'Parents'),
            Tab(text: 'Drivers'),
            Tab(text: 'Admins'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _buildList(UserRole.parent),
          _buildList(UserRole.driver),
          _buildList(UserRole.admin),
        ],
      ),
    );
  }
}
