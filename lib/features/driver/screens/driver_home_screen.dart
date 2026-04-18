import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../auth/services/auth_provider.dart';
import '../services/trip_service.dart';
import '../services/location_service.dart';
import '../../parent/services/student_service.dart';
import '../../../shared/models/trip_model.dart';
import '../../../shared/models/bus_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../admin/services/bus_service.dart';
import '../../../core/constants/app_routes.dart';
import '../widgets/trip_cards.dart';
import '../widgets/driver_map_view.dart';
import '../widgets/driver_history_tab.dart';
import '../widgets/driver_students_tab.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> with SingleTickerProviderStateMixin {
  final TripService _tripService = TripService();
  final StudentService _studentService = StudentService();
  final BusService _busService = BusService();
  final LocationService _locationService = LocationService();
  bool _isActionLoading = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _doAction(Future<void> Function() action) async {
    if (_isActionLoading) return;
    setState(() => _isActionLoading = true);
    try {
      await action();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    if (user == null) return const SizedBox();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ────────────────────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Driver Panel 🚌',
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          user.name,
                          style: GoogleFonts.outfit(
                              fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _showLogoutDialog(context, auth),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          gradient: AppColors.driverGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            user.name.isNotEmpty
                                ? user.name[0].toUpperCase()
                                : 'D',
                            style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Body ──────────────────────────────────────────────────
              Expanded(
                child: StreamBuilder<BusModel?>(
                  stream: _busService.streamBusForDriver(user.uid),
                  builder: (context, busSnap) {
                    if (busSnap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final bus = busSnap.data;
                    if (bus == null) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.directions_bus_outlined,
                                  size: 64, color: AppColors.textHint),
                              const SizedBox(height: 16),
                              Text('No Bus Assigned',
                                  style: GoogleFonts.outfit(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary)),
                              const SizedBox(height: 8),
                              Text(
                                'You have not been assigned a bus by the Admin.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(
                                    color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return StreamBuilder<TripModel?>(
                      stream: _tripService.streamActiveTrip(user.uid),
                      builder: (context, tripSnap) {
                        final trip = tripSnap.data;
                        final hasTrip = trip != null;

                        // Auto-resume GPS tracking if the app was reloaded
                        if (hasTrip && !_locationService.isTracking) {
                          _locationService.startTracking(trip.id);
                        }

                        return Column(
                          children: [
                            // ── Pinned Trip Status Card ──────────────
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                              child: _buildTripCard(user, bus, trip),
                            ),
                            const SizedBox(height: 12),

                            // ── Tab Bar ───────────────────────────────
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 20),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: TabBar(
                                controller: _tabController,
                                indicatorSize: TabBarIndicatorSize.tab,
                                dividerColor: Colors.transparent,
                                indicator: BoxDecoration(
                                  gradient: AppColors.driverGradient,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                labelColor: Colors.white,
                                unselectedLabelColor: AppColors.textSecondary,
                                labelStyle: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w700, fontSize: 13),
                                tabs: const [
                                  Tab(icon: Icon(Icons.map_rounded, size: 18), text: 'Map'),
                                  Tab(icon: Icon(Icons.people_rounded, size: 18), text: 'Students'),
                                  Tab(icon: Icon(Icons.history_rounded, size: 18), text: 'History'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // ── Tab Content ───────────────────────────
                            Expanded(
                              child: TabBarView(
                                controller: _tabController,
                                children: [
                                  // ── TAB 1: MAP ──────────────────────
                                  _buildMapTab(trip),

                                  // ── TAB 2: STUDENTS ─────────────────
                                  DriverStudentsTab(
                                    bus: bus,
                                    trip: trip,
                                    doAction: _doAction,
                                  ),

                                  // ── TAB 3: HISTORY ──────────────────
                                  DriverHistoryTab(driverId: user.uid),
                                ],
                              ),
                            ),
                          ],
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

  // ── Trip Status Card ─────────────────────────────────────────────────────

  Widget _buildTripCard(dynamic user, BusModel bus, TripModel? trip) {
    if (trip == null) {
      return IdleTripCard(
        isLoading: _isActionLoading,
        onStartTrip: () => _startMorningTrip(user, bus),
      );
    }

    switch (trip.status) {
      case TripStatus.morningPickup:
        return MorningPickupCard(
          trip: trip,
          isLoading: _isActionLoading,
          onReachedSchool: () => _doAction(() => _tripService.markReachedSchool(trip)),
        );
      case TripStatus.atSchool:
        return AtSchoolCard(
          isLoading: _isActionLoading,
          onStartReturn: () => _doAction(() => _tripService.startReturnTrip(trip)),
        );
      case TripStatus.returnTrip:
        return ReturnTripCard(
          trip: trip,
          isLoading: _isActionLoading,
          onEndTrip: () => _doAction(() async {
            await _tripService.endTrip(trip.id);
            _locationService.stopTracking();
          }),
        );
      default:
        return IdleTripCard(
          isLoading: _isActionLoading,
          onStartTrip: () => _startMorningTrip(user, bus),
        );
    }
  }

  // ── TAB 1: Full-screen Map ──────────────────────────────────────────────────
  Widget _buildMapTab(TripModel? trip) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: DriverMapView(trip: trip),
      ),
    );
  }

  // ── Start Morning Trip action ─────────────────────────────────────────────
  Future<void> _startMorningTrip(dynamic user, BusModel bus) async {
    final students = await _studentService
        .streamStudentsForBus(bus.id)
        .first;

    if (!mounted) return;

    if (students.isEmpty) {
      // ignore: use_build_context_synchronously
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surfaceElevated,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('No Students Assigned',
              style: GoogleFonts.outfit(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700)),
          content: Text(
              'No students are assigned to your bus yet. Ask your Admin to assign students.',
              style: GoogleFonts.outfit(color: AppColors.textSecondary)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel',
                  style: GoogleFonts.outfit(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Start Anyway',
                  style: GoogleFonts.outfit(color: AppColors.driverColor)),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    await _doAction(() async {
      final tripId = await _tripService.startMorningTrip(
        driverId: user.uid,
        driverName: user.name,
        busId: bus.id,
        busNumber: bus.busNumber,
        students: students,
      );
      // Start GPS tracking immediately
      await _locationService.startTracking(tripId);
    });
  }

  void _showLogoutDialog(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Sign Out',
            style: GoogleFonts.outfit(
                color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        content: Text('Are you sure?',
            style: GoogleFonts.outfit(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style:
                      GoogleFonts.outfit(color: AppColors.textSecondary))),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await auth.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                    context, AppRoutes.welcome, (_) => false);
              }
            },
            child: Text('Sign Out',
                style: GoogleFonts.outfit(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
