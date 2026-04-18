import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../../core/theme/app_colors.dart';
import '../services/school_settings_service.dart';

/// Admin screen where the admin pins the school location on the map
/// and sets the school name. This is stored in Firestore and used by
/// parents to see the school destination on the tracking map.
class AdminSchoolSettingsScreen extends StatefulWidget {
  const AdminSchoolSettingsScreen({super.key});

  @override
  State<AdminSchoolSettingsScreen> createState() =>
      _AdminSchoolSettingsScreenState();
}

class _AdminSchoolSettingsScreenState
    extends State<AdminSchoolSettingsScreen> {
  final _service = SchoolSettingsService();
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  GoogleMapController? _mapController;

  LatLng? _pinned;
  bool _loading = true;
  bool _saving = false;

  static const _defaultPos = LatLng(19.0760, 72.8777);

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final s = await _service.fetch();
    setState(() {
      _nameCtrl.text = s.name == 'School' ? '' : s.name;
      _addressCtrl.text = s.address ?? '';
      if (s.hasLocation) _pinned = LatLng(s.lat!, s.lng!);
      _loading = false;
    });
  }

  Future<void> _goToMyLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Location permissions denied. Please enable in settings.'),
            backgroundColor: AppColors.error,
          ));
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.high));
      final loc = LatLng(pos.latitude, pos.longitude);
      setState(() => _pinned = loc);
      _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(CameraPosition(target: loc, zoom: 16)));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Using your current GPS location.'),
          backgroundColor: AppColors.success,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error getting location: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  Future<void> _searchAddress() async {
    final query = _addressCtrl.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please enter an address to search'),
          backgroundColor: AppColors.warning));
      return;
    }
    
    // Close keyboard
    FocusScope.of(context).unfocus();

    try {
      List<Location> locations = await locationFromAddress(query).timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw Exception('Timeout'),
      );
      
      if (locations.isNotEmpty) {
        final loc = LatLng(locations.first.latitude, locations.first.longitude);
        setState(() => _pinned = loc);
        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(CameraPosition(target: loc, zoom: 16)),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Location found from address!'),
            backgroundColor: AppColors.success,
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not find location automatically from this address.'),
          backgroundColor: AppColors.warning,
        ));
      }
    }
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please enter a school name'),
          backgroundColor: AppColors.error));
      return;
    }
    if (_pinned == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please tap the map to pin the school location'),
          backgroundColor: AppColors.warning));
      return;
    }
    setState(() => _saving = true);
    try {
      await _service.save(SchoolSettings(
        name: name,
        lat: _pinned!.latitude,
        lng: _pinned!.longitude,
        address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('School location saved! 🏫'),
            backgroundColor: AppColors.success));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    final initial = _pinned ?? _defaultPos;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('School Location',
            style: GoogleFonts.outfit(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child:
                      CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
            )
          else
            TextButton(
              onPressed: _save,
              child: Text('Save',
                  style: GoogleFonts.outfit(
                      color: AppColors.primary, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Fields ─────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(children: [
              TextField(
                controller: _nameCtrl,
                style: GoogleFonts.outfit(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'School Name',
                  labelStyle: GoogleFonts.outfit(color: AppColors.textSecondary),
                  prefixIcon: const Icon(Icons.school_rounded,
                      color: AppColors.adminColor, size: 20),
                  filled: true,
                  fillColor: AppColors.surfaceElevated,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _addressCtrl,
                style: GoogleFonts.outfit(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Address (optional)',
                  labelStyle: GoogleFonts.outfit(color: AppColors.textSecondary),
                  prefixIcon: const Icon(Icons.location_on_outlined,
                      color: AppColors.textSecondary, size: 20),
                  filled: true,
                  fillColor: AppColors.surfaceElevated,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _searchAddress,
                      icon: const Icon(Icons.search_rounded, size: 18),
                      label: Text('Search Map', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _goToMyLocation,
                      icon: const Icon(Icons.my_location_rounded, size: 18),
                      label: Text('Auto Detect', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.adminColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.adminColor.withValues(alpha: 0.2)),
                ),
                child: Row(children: [
                  const Icon(Icons.info_outline_rounded,
                      color: AppColors.adminColor, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tap anywhere on the map below to pin the school location. '
                      'Parents will see this as the school destination on their tracking map.',
                      style: GoogleFonts.outfit(
                          color: AppColors.adminColor, fontSize: 11),
                    ),
                  ),
                ]),
              ),
            ]),
          ),

          // ── Map ────────────────────────────────────────────────────────────
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition:
                      CameraPosition(target: initial, zoom: 15),
                  onMapCreated: (ctrl) => _mapController = ctrl,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  onTap: (latLng) {
                    setState(() => _pinned = latLng);
                  },
                  markers: _pinned != null
                      ? {
                          Marker(
                            markerId: const MarkerId('school'),
                            position: _pinned!,
                            icon: BitmapDescriptor.defaultMarkerWithHue(
                                BitmapDescriptor.hueRed),
                            infoWindow: InfoWindow(
                              title: _nameCtrl.text.isNotEmpty
                                  ? _nameCtrl.text
                                  : '🏫 School',
                              snippet: 'Tap to confirm',
                            ),
                          ),
                        }
                      : {},
                ),

                // My Location FAB
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton.small(
                    onPressed: _goToMyLocation,
                    backgroundColor: AppColors.surface,
                    child: const Icon(Icons.my_location_rounded,
                        color: AppColors.primary),
                  ),
                ),

                // Pinned status
                if (_pinned != null)
                  Positioned(
                    top: 12,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 8)
                        ],
                      ),
                      child: Row(children: [
                        const Icon(Icons.location_on_rounded,
                            color: AppColors.error, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          '📍 Pinned: ${_pinned!.latitude.toStringAsFixed(4)}, '
                          '${_pinned!.longitude.toStringAsFixed(4)}',
                          style: GoogleFonts.outfit(
                              color: AppColors.textPrimary, fontSize: 11),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => setState(() => _pinned = null),
                          child: const Icon(Icons.close_rounded,
                              color: AppColors.textHint, size: 16),
                        ),
                      ]),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
