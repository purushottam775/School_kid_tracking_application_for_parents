import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/models/student_model.dart';
import '../../parent/services/student_service.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/admin_student_tile.dart';
import '../widgets/admin_student_dialogs.dart';

class AdminStudentsScreen extends StatefulWidget {
  const AdminStudentsScreen({super.key});

  @override
  State<AdminStudentsScreen> createState() => _AdminStudentsScreenState();
}

class _AdminStudentsScreenState extends State<AdminStudentsScreen> {
  final StudentService _service = StudentService();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(Icons.arrow_back_ios_rounded,
                            color: AppColors.textPrimary, size: 18),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'All Students',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'View, edit & assign buses',
                          style: GoogleFonts.outfit(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                  style: GoogleFonts.outfit(
                      color: AppColors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search students...',
                    hintStyle: GoogleFonts.outfit(color: AppColors.textHint),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppColors.textHint, size: 20),
                    filled: true,
                    fillColor: AppColors.surfaceElevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Student list
              Expanded(
                child: StreamBuilder<List<StudentModel>>(
                  stream: _service.streamAllStudents(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary),
                      );
                    }

                    final all = snapshot.data ?? [];
                    final filtered = _searchQuery.isEmpty
                        ? all
                        : all
                            .where((s) =>
                                s.name.toLowerCase().contains(_searchQuery) ||
                                s.className.toLowerCase().contains(_searchQuery) ||
                                s.parentName.toLowerCase().contains(_searchQuery))
                            .toList();

                    if (filtered.isEmpty) {
                      return _buildEmpty(_searchQuery.isNotEmpty);
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        return AdminStudentTile(
                          student: filtered[i],
                          onEdit: () => AdminStudentDialogs.showEditDialog(
                              context, _service, filtered[i]),
                          onDelete: () => AdminStudentDialogs.confirmDelete(
                              context, _service, filtered[i]),
                          onAssignBus: () =>
                              AdminStudentDialogs.showAssignBusDialog(
                                  context, _service, filtered[i]),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(bool isSearch) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.group_outlined,
              color: AppColors.textHint, size: 48),
          const SizedBox(height: 12),
          Text(
            isSearch ? 'No students found' : 'No students yet',
            style: GoogleFonts.outfit(
                color: AppColors.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            isSearch
                ? 'Try a different search'
                : 'Students will appear here when parents add them',
            style:
                GoogleFonts.outfit(color: AppColors.textHint, fontSize: 12),
          ),
        ],
      ),
    );
  }

}
