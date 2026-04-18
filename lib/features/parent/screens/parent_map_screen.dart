import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../driver/services/trip_service.dart';
import '../../../shared/models/trip_model.dart';
import '../../../shared/models/student_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../admin/services/school_settings_service.dart';

class ParentMapScreen extends StatefulWidget {
  final String busId;
  final String busNumber;
  final List<StudentModel> students;

  const ParentMapScreen({
    super.key,
    required this.busId,
    required this.busNumber,
    this.students = const [],
  });

  @override
  State<ParentMapScreen> createState() => _ParentMapScreenState();
}

class _ParentMapScreenState extends State<ParentMapScreen> {
  GoogleMapController? _mapController;
  final TripService _tripService = TripService();
  final SchoolSettingsService _settingsService = SchoolSettingsService();
  SchoolSettings _school = const SchoolSettings(name: 'School');
  LatLng? _lastCameraPos;

  @override
  void initState() {
    super.initState();
    _settingsService.stream().listen((s) {
      if (mounted) setState(() => _school = s);
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Set<Marker> _buildMarkers(TripModel? trip) {
    final markers = <Marker>{};

    // 🏫 School marker (set by Admin)
    if (_school.hasLocation) {
      markers.add(Marker(
        markerId: const MarkerId('school'),
        position: LatLng(_school.lat!, _school.lng!),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: '🏫 ${_school.name}',
          snippet: _school.address ?? 'School destination',
        ),
      ));
    }

    // 🏠 Home / pickup markers for each student
    for (final s in widget.students) {
      if (s.pickupLat != null && s.pickupLng != null) {
        markers.add(Marker(
          markerId: MarkerId('home_${s.id}'),
          position: LatLng(s.pickupLat!, s.pickupLng!),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
          infoWindow: InfoWindow(
            title: '🏠 ${s.name}',
            snippet: s.pickupAddress.isNotEmpty ? s.pickupAddress : 'Pickup Location',
          ),
        ));
      }
    }

    // 🚌 Live bus marker
    if (trip?.lat != null && trip?.lng != null) {
      markers.add(Marker(
        markerId: const MarkerId('bus'),
        position: LatLng(trip!.lat!, trip.lng!),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: InfoWindow(
          title: '🚌 Bus ${widget.busNumber}',
          snippet: '${trip.status.label} • Driver: ${trip.driverName}',
        ),
      ));
    }

    return markers;
  }

  Set<Polyline> _buildRoutePolylines(TripModel? trip) {
    if (!_school.hasLocation) return {};

    final polylines = <Polyline>{};
    final schoolPos = LatLng(_school.lat!, _school.lng!);

    // Path between school and child's home
    for (final s in widget.students) {
      if (s.pickupLat != null && s.pickupLng != null) {
        final homePos = LatLng(s.pickupLat!, s.pickupLng!);
        polylines.add(
          Polyline(
            polylineId: PolylineId('route_${s.id}'),
            points: [schoolPos, homePos],
            color: AppColors.primary.withValues(alpha: 0.4),
            width: 3,
            patterns: [PatternItem.dash(20), PatternItem.gap(15)],
            geodesic: true,
          ),
        );
      }
    }

    // Path between live bus and school
    if (trip?.lat != null && trip?.lng != null) {
      final busPos = LatLng(trip!.lat!, trip.lng!);
      polylines.add(
        Polyline(
          polylineId: const PolylineId('bus_to_school'),
          points: [busPos, schoolPos],
          color: AppColors.driverColor.withValues(alpha: 0.6),
          width: 4,
          patterns: [PatternItem.dash(30), PatternItem.gap(15)],
          geodesic: true,
        ),
      );
    }

    return polylines;
  }

  LatLng _getInitialCamera(TripModel? trip) {
    // Priority: live bus → school → home pin → Mumbai fallback
    if (trip?.lat != null && trip?.lng != null) {
      return LatLng(trip!.lat!, trip.lng!);
    }
    if (_school.hasLocation) return LatLng(_school.lat!, _school.lng!);
    for (final s in widget.students) {
      if (s.pickupLat != null && s.pickupLng != null) {
        return LatLng(s.pickupLat!, s.pickupLng!);
      }
    }
    return const LatLng(19.0760, 72.8777);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          '🚌 Bus ${widget.busNumber} — Live Tracking',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: StreamBuilder<TripModel?>(
        stream: _tripService.streamActiveTripForBus(widget.busId),
        builder: (context, snapshot) {
          final trip = snapshot.data;
          final hasLiveLocation = trip?.lat != null && trip?.lng != null;

          // Animate camera to bus when GPS updates
          if (hasLiveLocation && _mapController != null) {
            final newPos = LatLng(trip!.lat!, trip.lng!);
            if (_lastCameraPos == null ||
                (newPos.latitude - _lastCameraPos!.latitude).abs() > 0.0001 ||
                (newPos.longitude - _lastCameraPos!.longitude).abs() > 0.0001) {
              _lastCameraPos = newPos;
              _mapController!.animateCamera(CameraUpdate.newLatLng(newPos));
            }
          }

          final initialPos = _getInitialCamera(trip);

          return Column(
            children: [
              // ── Map (top, flexible) ──────────────────────────────────────
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition:
                          CameraPosition(target: initialPos, zoom: 14),
                      onMapCreated: (ctrl) => _mapController = ctrl,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                      zoomControlsEnabled: false,
                      markers: _buildMarkers(trip),
                      polylines: _buildRoutePolylines(trip),
                    ),
                    // Floating legend top-left
                    Positioned(
                      top: 12,
                      left: 12,
                      child: _buildLegend(trip),
                    ),
                  ],
                ),
              ),

              // ── Per-child status panel (bottom) ─────────────────────────
              Container(
                constraints: const BoxConstraints(maxHeight: 280),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 12)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle + trip header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                      child: Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                    if (trip == null)
                      _buildNoTripPanel()
                    else
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTripHeader(trip, hasLiveLocation),
                              const SizedBox(height: 12),
                              _buildChildrenStatus(trip),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLegend(TripModel? trip) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _legendRow('🚌', 'Bus (live)', AppColors.warning),
          _legendRow('🏫', 'School', AppColors.error),
          _legendRow('🏠', 'Home/Pickup', AppColors.secondary),
        ],
      ),
    );
  }

  Widget _legendRow(String emoji, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 6),
          Text(label,
              style: GoogleFonts.outfit(
                  fontSize: 10, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildNoTripPanel() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.textHint.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.directions_bus_outlined,
                color: AppColors.textHint, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('No Active Trip',
                    style: GoogleFonts.outfit(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
                const SizedBox(height: 3),
                Text('Bus ${widget.busNumber} has not started a trip yet.',
                    style: GoogleFonts.outfit(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripHeader(TripModel trip, bool hasLiveLocation) {
    final (bgColor, fgColor) = _statusColors(trip.status);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: fgColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.directions_bus_rounded, color: fgColor, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bus ${widget.busNumber} • ${trip.driverName}',
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontSize: 14)),
              if (!hasLiveLocation)
                Row(children: [
                  const SizedBox(
                      width: 10,
                      height: 10,
                      child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: AppColors.driverColor)),
                  const SizedBox(width: 5),
                  Text('Getting GPS…',
                      style: GoogleFonts.outfit(
                          fontSize: 10, color: AppColors.textSecondary)),
                ]),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration:
              BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
          child: Text(trip.status.label,
              style: GoogleFonts.outfit(
                  color: fgColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _buildChildrenStatus(TripModel trip) {
    if (widget.students.isEmpty) {
      return Text('No students linked to this bus.',
          style: GoogleFonts.outfit(color: AppColors.textSecondary));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your Children',
            style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        ...widget.students.map((student) {
          // Find this student's entry in the live trip
          final entry = trip.students
              .where((e) => e.studentId == student.id)
              .firstOrNull;
          final status = entry?.status;
          return _buildChildStatusTile(student, status);
        }),
      ],
    );
  }

  Widget _buildChildStatusTile(StudentModel student, StudentTripStatus? status) {
    final (icon, label, color) = _studentStatusInfo(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: AppColors.parentGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
                style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student.name,
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontSize: 13)),
                Text(student.className,
                    style: GoogleFonts.outfit(
                        color: AppColors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 12, color: color),
                const SizedBox(width: 4),
                Text(label,
                    style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  (IconData, String, Color) _studentStatusInfo(StudentTripStatus? status) {
    switch (status) {
      case StudentTripStatus.pickedUp:
        return (Icons.directions_bus_rounded, 'Picked Up', AppColors.driverColor);
      case StudentTripStatus.droppedAtSchool:
        return (Icons.school_rounded, '🏫 At School', AppColors.success);
      case StudentTripStatus.boardedReturn:
        return (Icons.directions_bus_rounded, 'On Way Home', AppColors.primary);
      case StudentTripStatus.droppedHome:
        return (Icons.home_rounded, '🏠 Arrived Home', AppColors.success);
      case StudentTripStatus.waiting:
        return (Icons.schedule_rounded, 'Waiting', AppColors.textHint);
      default:
        return (Icons.schedule_rounded, 'Not Yet', AppColors.textHint);
    }
  }

  (Color, Color) _statusColors(TripStatus status) {
    switch (status) {
      case TripStatus.morningPickup:
        return (AppColors.driverColor.withValues(alpha: 0.15), AppColors.driverColor);
      case TripStatus.atSchool:
        return (AppColors.success.withValues(alpha: 0.15), AppColors.success);
      case TripStatus.returnTrip:
        return (AppColors.primary.withValues(alpha: 0.15), AppColors.primary);
      default:
        return (AppColors.border, AppColors.textSecondary);
    }
  }
}
