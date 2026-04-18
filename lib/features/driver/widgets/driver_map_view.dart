import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../shared/models/trip_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../admin/services/school_settings_service.dart';

class DriverMapView extends StatefulWidget {
  final TripModel? trip;
  const DriverMapView({super.key, required this.trip});

  @override
  State<DriverMapView> createState() => _DriverMapViewState();
}

class _DriverMapViewState extends State<DriverMapView> {
  GoogleMapController? _mapController;
  final SchoolSettingsService _settingsService = SchoolSettingsService();
  SchoolSettings _school = const SchoolSettings(name: 'School');

  // Fallback to Mumbai (will be overridden when school loads)
  static const _fallback = LatLng(19.0760, 72.8777);

  @override
  void initState() {
    super.initState();
    _settingsService.stream().listen((s) {
      if (!mounted) return;
      setState(() => _school = s);
      // When school location first arrives, jump camera there if no live GPS yet
      if (s.hasLocation &&
          widget.trip?.lat == null &&
          _mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
              CameraPosition(target: LatLng(s.lat!, s.lng!), zoom: 15)),
        );
      }
    });
  }

  @override
  void didUpdateWidget(covariant DriverMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Track the bus live when GPS coordinates update
    if (widget.trip?.lat != null && widget.trip?.lng != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(LatLng(widget.trip!.lat!, widget.trip!.lng!)),
      );
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};

    // 🏫 School marker
    if (_school.hasLocation) {
      markers.add(Marker(
        markerId: const MarkerId('school'),
        position: LatLng(_school.lat!, _school.lng!),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: '🏫 ${_school.name}',
          snippet: _school.address ?? 'School Destination',
        ),
      ));
    }

    // 🚌 Driver's live position (from trip GPS)
    final lat = widget.trip?.lat;
    final lng = widget.trip?.lng;
    if (lat != null && lng != null) {
      markers.add(Marker(
        markerId: const MarkerId('driver'),
        position: LatLng(lat, lng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: const InfoWindow(title: '🚌 You (Driver)'),
      ));
    }

    return markers;
  }

  LatLng _initialCamera() {
    // Priority: live GPS → school → fallback
    final lat = widget.trip?.lat;
    final lng = widget.trip?.lng;
    if (lat != null && lng != null) return LatLng(lat, lng);
    if (_school.hasLocation) return LatLng(_school.lat!, _school.lng!);
    return _fallback;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.hardEdge,
      child: GoogleMap(
        initialCameraPosition: CameraPosition(target: _initialCamera(), zoom: 15),
        onMapCreated: (ctrl) {
          _mapController = ctrl;
          // Jump to school/bus immediately when map is ready
          final target = _initialCamera();
          ctrl.animateCamera(
            CameraUpdate.newCameraPosition(
                CameraPosition(target: target, zoom: 15)),
          );
        },
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        zoomControlsEnabled: false,
        markers: _buildMarkers(),
      ),
    );
  }
}
