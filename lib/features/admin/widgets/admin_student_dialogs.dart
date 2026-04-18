import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/student_model.dart';
import '../../../shared/models/bus_model.dart';
import '../../parent/services/student_service.dart';
import '../services/bus_service.dart';
import '../../../shared/widgets/custom_text_field.dart';

class AdminStudentDialogs {
  static void showEditDialog(BuildContext context, StudentService service, StudentModel student) {
    final nameCtrl = TextEditingController(text: student.name);
    final classCtrl = TextEditingController(text: student.className);
    final addressCtrl = TextEditingController(text: student.pickupAddress);
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDlg) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Edit Student',
              style: GoogleFonts.outfit(
                  color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomTextField(
                    controller: nameCtrl,
                    label: 'Student Name',
                    prefixIcon: Icons.child_care_rounded,
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'Name required'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: classCtrl,
                    label: 'Class',
                    prefixIcon: Icons.school_rounded,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Class required' : null,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: addressCtrl,
                    label: 'Pickup Address',
                    prefixIcon: Icons.location_on_outlined,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: GoogleFonts.outfit(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setStateDlg(() => isLoading = true);
                      await service.updateStudent(student.id, {
                        'name': nameCtrl.text.trim(),
                        'className': classCtrl.text.trim(),
                        'pickupAddress': addressCtrl.text.trim(),
                      });
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              child: Text('Save',
                  style: GoogleFonts.outfit(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  static void showAssignBusDialog(BuildContext context, StudentService service, StudentModel student) {
    bool isLoading = false;
    String? selectedBusId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDlg) => AlertDialog(
          backgroundColor: AppColors.surfaceElevated,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Assign Bus',
            style: GoogleFonts.outfit(
                color: AppColors.textPrimary, fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Assign a bus to ${student.name}',
                style: GoogleFonts.outfit(
                    fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              
              StreamBuilder<List<BusModel>>(
                stream: BusService().streamBuses(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const CircularProgressIndicator();
                  final buses = snapshot.data!;
                  
                  if (student.busId.isNotEmpty && selectedBusId == null) {
                    selectedBusId = buses.where((b) => b.id == student.busId).firstOrNull?.id;
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        dropdownColor: AppColors.surfaceElevated,
                        hint: Text('Select Bus', style: GoogleFonts.outfit(color: AppColors.textHint)),
                        value: selectedBusId,
                        icon: const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                        items: buses.map((b) {
                          return DropdownMenuItem<String>(
                            value: b.id,
                            child: Text('${b.busNumber} (${b.driverName})', 
                                style: GoogleFonts.outfit(color: AppColors.textPrimary)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setStateDlg(() => selectedBusId = val);
                        },
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: GoogleFonts.outfit(color: AppColors.textSecondary)),
            ),
            ElevatedButton.icon(
              onPressed: isLoading || selectedBusId == null
                  ? null
                  : () async {
                      setStateDlg(() => isLoading = true);
                      final busDoc = await FirebaseFirestore.instance.collection('buses').doc(selectedBusId).get();
                      final busNumber = busDoc.data()?['busNumber'] ?? 'Unknown';
                      
                      await service.assignBus(
                        student.id,
                        selectedBusId!,
                        busNumber,
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
              icon: const Icon(Icons.check_rounded, size: 18),
              label: Text('Assign',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.driverColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> confirmDelete(BuildContext context, StudentService service, StudentModel student) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete ${student.name}?',
            style: GoogleFonts.outfit(
                color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        content: Text('This action cannot be undone.',
            style: GoogleFonts.outfit(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: GoogleFonts.outfit(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete',
                style: GoogleFonts.outfit(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await service.deleteStudent(student.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${student.name} deleted'),
              backgroundColor: AppColors.error),
        );
      }
    }
  }
}
