import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../../core/theme/app_colors.dart';

/// Full-screen map to let the parent pin their pickup / home location.
/// Returns a [LatLng] when confirmed, null if cancelled.
class PickupLocationPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;
  final String addressQuery;

  const PickupLocationPickerScreen({
    super.key,
    this.initialLocation,
    this.addressQuery = '',
  });

  @override
  State<PickupLocationPickerScreen> createState() =>
      _PickupLocationPickerScreenState();
}

class _PickupLocationPickerScreenState
    extends State<PickupLocationPickerScreen> {
  GoogleMapController? _mapController;

  static const _defaultLocation = LatLng(19.0760, 72.8777); // Mumbai fallback
  LatLng? _pickedLocation;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _pickedLocation = widget.initialLocation;
    if (_pickedLocation == null) {
      _initializeLocation();
    }
  }

  Future<void> _initializeLocation() async {
    // If user provided an address text, try to geocode it first
    if (widget.addressQuery.isNotEmpty) {
      setState(() => _locating = true);
      try {
        List<Location> locations =
            await locationFromAddress(widget.addressQuery).timeout(
          const Duration(seconds: 5),
          onTimeout: () => throw Exception('Timeout'),
        );

        if (locations.isNotEmpty) {
          final loc = LatLng(locations.first.latitude, locations.first.longitude);
          setState(() {
            _pickedLocation = loc;
            _locating = false;
          });
          _mapController?.animateCamera(
            CameraUpdate.newCameraPosition(CameraPosition(target: loc, zoom: 16)),
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Found location from your typed address!'),
                backgroundColor: AppColors.success,
                duration: Duration(seconds: 2),
              ),
            );
          }
          return; // Geocoding succeeded
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not automatically find address on map. Getting your current GPS location instead...'),
              backgroundColor: AppColors.warning,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    }
    await _goToMyLocation();
  }

  Future<void> _goToMyLocation() async {
    setState(() => _locating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) _showLocationDialog('Location services are disabled. Please enable them in your device settings.');
        return;
      }

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (mounted) _showLocationDialog('Location permissions are denied. Please grant permission in settings to detect your current location.');
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final loc = LatLng(pos.latitude, pos.longitude);
      setState(() => _pickedLocation = loc);
      _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(CameraPosition(target: loc, zoom: 16)));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Using your current GPS location.'),
            backgroundColor: AppColors.primary,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting location: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _showLocationDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: Text('Enable Location', style: GoogleFonts.outfit(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        content: Text(message, style: GoogleFonts.outfit(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close', style: GoogleFonts.outfit(color: AppColors.primary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await Geolocator.openLocationSettings();
            },
            child: Text('Open Settings', style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final initialTarget = _pickedLocation ?? _defaultLocation;

    return Scaffold(
      body: Stack(
        children: [
          // ── Map ─────────────────────────────────────────────────────────
          GoogleMap(
            initialCameraPosition:
                CameraPosition(target: initialTarget, zoom: 15),
            onMapCreated: (ctrl) => _mapController = ctrl,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onTap: (latLng) {
              setState(() => _pickedLocation = latLng);
            },
            markers: _pickedLocation != null
                ? {
                    Marker(
                      markerId: const MarkerId('pickup'),
                      position: _pickedLocation!,
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueViolet),
                      infoWindow: const InfoWindow(title: 'Pickup Location'),
                    ),
                  }
                : {},
          ),

          // ── Top Bar ──────────────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 12)
                  ],
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back_ios_rounded,
                          color: AppColors.textPrimary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Pin Pickup Location',
                              style: GoogleFonts.outfit(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15)),
                          Text('Tap anywhere on the map to set location',
                              style: GoogleFonts.outfit(
                                  color: AppColors.textSecondary, fontSize: 11)),
                        ],
                      ),
                    ),
                    if (_locating)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.primary),
                      )
                    else
                      GestureDetector(
                        onTap: _goToMyLocation,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.my_location_rounded,
                              color: AppColors.primary, size: 20),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // ── Confirm Button ───────────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: _pickedLocation == null
                      ? null
                      : () => Navigator.pop(context, _pickedLocation),
                  icon: const Icon(Icons.check_circle_outline_rounded,
                      color: Colors.white),
                  label: Text(
                    'Confirm Pickup Location',
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
