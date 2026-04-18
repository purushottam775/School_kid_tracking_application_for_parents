import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_provider.dart';
import '../models/user_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/custom_text_field.dart';

/// Shown when a Google new-user needs to choose their role
class RoleSelectionScreen extends StatefulWidget {
  final bool isGoogleUser;
  const RoleSelectionScreen({super.key, this.isGoogleUser = false});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  UserRole _selectedRole = UserRole.parent;
  final _phoneCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _proceed() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();

    final success = await auth.completeGoogleSignUp(
      role: _selectedRole,
      phone: _phoneCtrl.text,
    );

    if (!mounted) return;
    if (success) {
      _navigateByRole(_selectedRole);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? AppStrings.errorOccurred),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _navigateByRole(UserRole role) {
    switch (role.value) {
      case 'driver':
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.driverHome, (_) => false);
        break;
      case 'admin':
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.adminDashboard, (_) => false);
        break;
      default:
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.parentHome, (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Center(
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.35),
                          blurRadius: 20,
                        )
                      ],
                    ),
                    child: const Icon(Icons.directions_bus_rounded, size: 38, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  AppStrings.chooseRole,
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.chooseRoleSubtitle,
                  style: GoogleFonts.outfit(fontSize: 14, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 32),

                // Role list
                _buildRoleOption(
                  role: UserRole.parent,
                  icon: Icons.family_restroom_rounded,
                  label: AppStrings.roleParent,
                  desc: AppStrings.parentDesc,
                  color: AppColors.parentColor,
                ),
                const SizedBox(height: 12),
                _buildRoleOption(
                  role: UserRole.driver,
                  icon: Icons.drive_eta_rounded,
                  label: AppStrings.roleDriver,
                  desc: AppStrings.driverDesc,
                  color: AppColors.driverColor,
                ),
                const SizedBox(height: 12),
                _buildRoleOption(
                  role: UserRole.admin,
                  icon: Icons.admin_panel_settings_rounded,
                  label: AppStrings.roleAdmin,
                  desc: AppStrings.adminDesc,
                  color: AppColors.adminColor,
                ),

                if (widget.isGoogleUser) ...[
                  const SizedBox(height: 24),
                  Form(
                    key: _formKey,
                    child: CustomTextField(
                      controller: _phoneCtrl,
                      label: 'Phone Number',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? AppStrings.phoneRequired
                          : null,
                    ),
                  ),
                ] else
                  Form(key: _formKey, child: const SizedBox.shrink()),

                const Spacer(),

                GradientButton(
                  label: 'Continue',
                  isLoading: auth.isLoading,
                  onPressed: _proceed,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleOption({
    required UserRole role,
    required IconData icon,
    required String label,
    required String desc,
    required Color color,
  }) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.12) : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withOpacity(isSelected ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? color : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? color : Colors.transparent,
                border: Border.all(
                  color: isSelected ? color : AppColors.border,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
