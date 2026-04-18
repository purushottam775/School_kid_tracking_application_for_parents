import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/bus_model.dart';
import '../../auth/models/user_model.dart';
import '../services/bus_service.dart';
import '../services/user_service.dart';
import '../../../shared/widgets/custom_text_field.dart';

class AdminBusesScreen extends StatefulWidget {
  const AdminBusesScreen({super.key});

  @override
  State<AdminBusesScreen> createState() => _AdminBusesScreenState();
}

class _AdminBusesScreenState extends State<AdminBusesScreen> {
  final BusService _busService = BusService();
  final UserService _userService = UserService();

  void _showAddEditBusDialog([BusModel? bus]) {
    final busNumberCtrl = TextEditingController(text: bus?.busNumber);
    String? selectedDriverUid;
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDlg) {
          return AlertDialog(
            backgroundColor: AppColors.surfaceElevated,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(bus == null ? 'Add New Bus' : 'Edit Bus',
                style: GoogleFonts.outfit(
                    color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomTextField(
                    controller: busNumberCtrl,
                    label: 'Bus Number (e.g. BUS-01)',
                    prefixIcon: Icons.directions_bus_outlined,
                  ),
                  const SizedBox(height: 16),
                  
                  // Driver Dropdown
                  StreamBuilder<List<UserModel>>(
                    stream: _userService.streamUsersByRole(UserRole.driver),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const CircularProgressIndicator();
                      }
                      
                      final drivers = snapshot.data!;
                      
                      // Pre-select if editing
                      if (bus != null && selectedDriverUid == null) {
                        selectedDriverUid = drivers.where((d) => d.uid == bus.driverId).firstOrNull?.uid;
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
                            hint: Text('Assign Driver', style: GoogleFonts.outfit(color: AppColors.textHint)),
                            value: selectedDriverUid,
                            icon: const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                            items: drivers.map((d) {
                              return DropdownMenuItem<String>(
                                value: d.uid,
                                child: Text('${d.name} (${d.phone.isNotEmpty ? d.phone : "No Phone"})', 
                                    style: GoogleFonts.outfit(color: AppColors.textPrimary)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setStateDlg(() => selectedDriverUid = val);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel', style: GoogleFonts.outfit(color: AppColors.textSecondary)),
              ),
              ElevatedButton.icon(
                onPressed: isLoading
                    ? null
                    : () async {
                        final busNum = busNumberCtrl.text.trim();
                        if (busNum.isEmpty || selectedDriverUid == null) return;
                        
                        setStateDlg(() => isLoading = true);
                        try {
                          final driverDoc = await FirebaseFirestore.instance.collection('users').doc(selectedDriverUid).get();
                          final driverName = driverDoc.data()?['name'] ?? 'Unknown Driver';
                        
                          if (bus == null) {
                            await _busService.createBus(
                              busNumber: busNum,
                              driverId: selectedDriverUid!,
                              driverName: driverName,
                            );
                          } else {
                            await _busService.updateBus(
                              bus.id,
                              busNumber: busNum,
                              driverId: selectedDriverUid!,
                              driverName: driverName,
                            );
                          }
                          if (ctx.mounted) Navigator.pop(ctx);
                        } finally {
                          if (ctx.mounted) setStateDlg(() => isLoading = false);
                        }
                      },
                icon: isLoading 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_rounded, size: 18),
                label: Text(bus == null ? 'Create' : 'Save', 
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.adminColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, BusModel bus) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete ${bus.busNumber}?',
            style: GoogleFonts.outfit(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        content: Text('This will remove the bus from the fleet.',
            style: GoogleFonts.outfit(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.outfit(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: GoogleFonts.outfit(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _busService.deleteBus(bus.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${bus.busNumber} deleted'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Manage Fleet', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditBusDialog(),
        icon: const Icon(Icons.add),
        label: Text('Add Bus', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.adminColor,
      ),
      body: StreamBuilder<List<BusModel>>(
        stream: _busService.streamBuses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }
          
          final buses = snapshot.data ?? [];
          if (buses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.directions_bus_outlined, size: 64, color: AppColors.border),
                  const SizedBox(height: 16),
                  Text('No buses in the fleet yet.', style: GoogleFonts.outfit(fontSize: 16, color: AppColors.textSecondary)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: buses.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final bus = buses[index];
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.adminColor.withValues(alpha: 0.3)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.adminColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.directions_bus_rounded, color: AppColors.adminColor),
                  ),
                  title: Text(bus.busNumber, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(bus.driverName, style: GoogleFonts.outfit(fontSize: 14, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  trailing: PopupMenuButton<String>(
                    color: AppColors.surfaceElevated,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
                    onSelected: (val) {
                      if (val == 'edit') _showAddEditBusDialog(bus);
                      if (val == 'delete') _confirmDelete(context, bus);
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(children: [
                          const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                          const SizedBox(width: 10),
                          Text('Edit', style: GoogleFonts.outfit(color: AppColors.textPrimary)),
                        ]),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(children: [
                          const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                          const SizedBox(width: 10),
                          Text('Remove', style: GoogleFonts.outfit(color: AppColors.error)),
                        ]),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
