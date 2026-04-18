import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../auth/services/auth_provider.dart';
import '../services/student_service.dart';
import '../../../shared/models/student_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/gradient_button.dart';
import 'pickup_location_picker_screen.dart';

class AddEditStudentScreen extends StatefulWidget {
  final StudentModel? student; // null = add mode, non-null = edit mode

  const AddEditStudentScreen({super.key, this.student});

  @override
  State<AddEditStudentScreen> createState() => _AddEditStudentScreenState();
}

class _AddEditStudentScreenState extends State<AddEditStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _classCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _service = StudentService();

  bool _isLoading = false;
  bool get _isEditMode => widget.student != null;
  LatLng? _pickedLocation; // GPS pin for pickup address

  // Class options
  final List<String> _classes = [
    'Nursery', 'LKG', 'UKG',
    'Class 1', 'Class 2', 'Class 3', 'Class 4', 'Class 5',
    'Class 6', 'Class 7', 'Class 8', 'Class 9', 'Class 10',
    'Class 11', 'Class 12',
  ];
  String _selectedClass = 'Class 1';

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _nameCtrl.text = widget.student!.name;
      _classCtrl.text = widget.student!.className;
      _addressCtrl.text = widget.student!.pickupAddress;
      _selectedClass = _classes.contains(widget.student!.className)
          ? widget.student!.className
          : 'Class 1';
      // Restore previously pinned location
      if (widget.student!.pickupLat != null &&
          widget.student!.pickupLng != null) {
        _pickedLocation = LatLng(
            widget.student!.pickupLat!, widget.student!.pickupLng!);
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _classCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final auth = context.read<AuthProvider>();
      final user = auth.currentUser!;

      if (_isEditMode) {
        await _service.updateStudent(widget.student!.id, {
          'name': _nameCtrl.text.trim(),
          'className': _selectedClass,
          'pickupAddress': _addressCtrl.text.trim(),
          if (_pickedLocation != null) 'pickupLat': _pickedLocation!.latitude,
          if (_pickedLocation != null) 'pickupLng': _pickedLocation!.longitude,
        });
        if (mounted) {
          _showSnack('Student updated successfully!', AppColors.success);
          Navigator.pop(context, true);
        }
      } else {
        final newStudent = StudentModel(
          id: '',
          name: _nameCtrl.text.trim(),
          className: _selectedClass,
          parentId: user.uid,
          parentName: user.name,
          pickupAddress: _addressCtrl.text.trim(),
          pickupLat: _pickedLocation?.latitude,
          pickupLng: _pickedLocation?.longitude,
          createdAt: DateTime.now(),
        );
        await _service.addStudent(newStudent);
        if (mounted) {
          _showSnack('Child added successfully! 🎉', AppColors.success);
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) _showSnack('Error: ${e.toString()}', AppColors.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

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
                    Text(
                      _isEditMode ? 'Edit Child' : 'Add Your Child',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),

                      // Avatar placeholder
                      Center(
                        child: Stack(
                          children: [
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                gradient: AppColors.parentGradient,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.parentColor.withValues(alpha: 0.3),
                                    blurRadius: 20,
                                  )
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  _nameCtrl.text.isNotEmpty
                                      ? _nameCtrl.text[0].toUpperCase()
                                      : '👦',
                                  style: GoogleFonts.outfit(
                                    fontSize: 38,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: AppColors.background, width: 2),
                                ),
                                child: const Icon(Icons.camera_alt_rounded,
                                    size: 14, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionLabel('Child Information'),
                            const SizedBox(height: 12),

                            // Name
                            CustomTextField(
                              controller: _nameCtrl,
                              label: "Child's Full Name",
                              prefixIcon: Icons.child_care_rounded,
                              textCapitalization: TextCapitalization.words,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? "Child's name is required"
                                  : null,
                            ),
                            const SizedBox(height: 14),

                            // Class dropdown
                            _buildClassDropdown(),
                            const SizedBox(height: 24),

                            _sectionLabel('Pickup Location'),
                            const SizedBox(height: 12),

                            // Pickup address
                            CustomTextField(
                              controller: _addressCtrl,
                              label: 'Home / Pickup Address',
                              prefixIcon: Icons.location_on_outlined,
                              maxLines: 2,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Pickup address is required'
                                  : null,
                            ),
                            const SizedBox(height: 12),

                            // Map pin button / preview
                            _buildMapPinSection(context),

                            if (_isEditMode && widget.student!.busNumber.isNotEmpty)
                              _buildBusInfoChip(),

                            const SizedBox(height: 32),

                            GradientButton(
                              label: _isEditMode ? 'Save Changes' : 'Add Child',
                              isLoading: _isLoading,
                              onPressed: _save,
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.outfit(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }

  Future<void> _openMapPicker(BuildContext context) async {
    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => PickupLocationPickerScreen(
          initialLocation: _pickedLocation,
          addressQuery: _addressCtrl.text.trim(),
        ),
      ),
    );
    if (result != null) {
      setState(() => _pickedLocation = result);
    }
  }

  Widget _buildMapPinSection(BuildContext context) {
    if (_pickedLocation == null) {
      // Show a "Pin on Map" button
      return GestureDetector(
        onTap: () => _openMapPicker(context),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.add_location_alt_outlined,
                  color: AppColors.primary, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pin Pickup Location on Map',
                        style: GoogleFonts.outfit(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                    Text('Tap to open map and pin exact location',
                        style: GoogleFonts.outfit(
                            color: AppColors.textSecondary, fontSize: 11)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  color: AppColors.primary, size: 14),
            ],
          ),
        ),
      );
    }

    // Show a mini-map preview with the pinned location
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 160,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                  target: _pickedLocation!, zoom: 15),
              markers: {
                Marker(
                  markerId: const MarkerId('pickup'),
                  position: _pickedLocation!,
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueViolet),
                ),
              },
              zoomControlsEnabled: false,
              scrollGesturesEnabled: false,
              tiltGesturesEnabled: false,
              rotateGesturesEnabled: false,
              myLocationButtonEnabled: false,
            ),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _openMapPicker(context),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.edit_location_alt_rounded,
                    color: AppColors.driverColor, size: 18),
                const SizedBox(width: 8),
                Text('Change Pin Location',
                    style: GoogleFonts.outfit(
                        color: AppColors.driverColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
                const Spacer(),
                Text(
                  '${_pickedLocation!.latitude.toStringAsFixed(4)}, '
                  '${_pickedLocation!.longitude.toStringAsFixed(4)}',
                  style: GoogleFonts.outfit(
                      color: AppColors.textHint, fontSize: 10),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClassDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedClass,
          isExpanded: true,
          dropdownColor: AppColors.surfaceElevated,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.textHint),
          items: _classes.map((c) {
            return DropdownMenuItem(
              value: c,
              child: Row(
                children: [
                  const Icon(Icons.school_rounded,
                      color: AppColors.textHint, size: 18),
                  const SizedBox(width: 10),
                  Text(c,
                      style: GoogleFonts.outfit(
                          color: AppColors.textPrimary, fontSize: 14)),
                ],
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _selectedClass = val);
          },
        ),
      ),
    );
  }

  Widget _buildBusInfoChip() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.driverColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.driverColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.directions_bus_rounded,
                color: AppColors.driverColor, size: 20),
            const SizedBox(width: 10),
            Text(
              'Assigned Bus: ${widget.student!.busNumber}',
              style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: AppColors.driverColor,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
