import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/trip_model.dart';

class AdminTripHistoryScreen extends StatefulWidget {
  const AdminTripHistoryScreen({super.key});

  @override
  State<AdminTripHistoryScreen> createState() => _AdminTripHistoryScreenState();
}

class _AdminTripHistoryScreenState extends State<AdminTripHistoryScreen> {
  bool _isLoading = false;
  bool _isSelectionMode = false;
  final Set<String> _selectedTrips = {};

  Stream<List<TripModel>> _streamAllTrips() {
    return FirebaseFirestore.instance
        .collection('trips')
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((d) => TripModel.fromFirestore(d)).toList();
      list.sort((a, b) {
        final aDate = a.completedAt ?? a.createdAt;
        final bDate = b.completedAt ?? b.createdAt;
        return bDate.compareTo(aDate);
      });
      return list;
    });
  }

  Color _statusColor(TripStatus s) {
    switch (s) {
      case TripStatus.morningPickup:
        return AppColors.driverColor;
      case TripStatus.atSchool:
        return AppColors.secondary;
      case TripStatus.returnTrip:
        return AppColors.primary;
      case TripStatus.completed:
        return AppColors.success;
      default:
        return AppColors.textHint;
    }
  }

  IconData _statusIcon(TripStatus s) {
    switch (s) {
      case TripStatus.morningPickup:
        return Icons.directions_bus_rounded;
      case TripStatus.atSchool:
        return Icons.school_rounded;
      case TripStatus.returnTrip:
        return Icons.home_rounded;
      case TripStatus.completed:
        return Icons.check_circle_rounded;
      default:
        return Icons.radio_button_unchecked;
    }
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      _selectedTrips.clear();
    });
  }

  void _toggleTipSelection(String tripId) {
    setState(() {
      if (_selectedTrips.contains(tripId)) {
        _selectedTrips.remove(tripId);
        if (_selectedTrips.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedTrips.add(tripId);
      }
    });
  }

  Future<void> _deleteTrips({required bool deleteAll}) async {
    final title = deleteAll ? 'Clear All History' : 'Delete Selected Trips';
    final content = deleteAll 
        ? 'Are you sure you want to delete ALL trip history? This will be cleared for all drivers and parents immediately.'
        : 'Are you sure you want to delete the ${_selectedTrips.length} selected trip(s)?';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title,
            style: GoogleFonts.outfit(
                color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        content: Text(content,
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

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final batch = FirebaseFirestore.instance.batch();
      
      if (deleteAll) {
        final snapshot = await FirebaseFirestore.instance.collection('trips').get();
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
      } else {
        for (final tripId in _selectedTrips) {
          final docRef = FirebaseFirestore.instance.collection('trips').doc(tripId);
          batch.delete(docRef);
        }
      }
      
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
            content: Text(deleteAll ? 'All trip history cleared.' : 'Selected trips deleted.'),
            backgroundColor: AppColors.success,
          ),
        );
        setState(() {
          _isSelectionMode = false;
          _selectedTrips.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting history: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
                onPressed: _toggleSelectionMode,
              )
            : const BackButton(color: AppColors.textPrimary),
        title: Text(
            _isSelectionMode 
                ? '${_selectedTrips.length} Selected'
                : 'Trip History',
            style: GoogleFonts.outfit(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 20.0),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (_isSelectionMode && _selectedTrips.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_rounded, color: AppColors.error),
              tooltip: 'Delete Selected',
              onPressed: () => _deleteTrips(deleteAll: false),
            )
          else if (!_isSelectionMode)
             IconButton(
               icon: const Icon(Icons.delete_sweep_rounded, color: AppColors.error),
               tooltip: 'Clear All History',
               onPressed: () => _deleteTrips(deleteAll: true),
             ),
        ],
      ),
      body: StreamBuilder<List<TripModel>>(
        stream: _streamAllTrips(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting && !_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final trips = snap.data ?? [];

          if (trips.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.history_rounded,
                      color: AppColors.textHint, size: 56),
                  const SizedBox(height: 14),
                  Text('No trips recorded yet',
                      style: GoogleFonts.outfit(
                          color: AppColors.textSecondary, fontSize: 16)),
                ],
              ),
            );
          }

          // Separate active vs completed
          final active = trips.where((t) => t.status != TripStatus.completed).toList();
          final completed = trips.where((t) => t.status == TripStatus.completed).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (active.isNotEmpty) ...[
                _sectionLabel('🟢 Active Trips (${active.length})'),
                const SizedBox(height: 8),
                ...active.map((t) => _TripTile(
                    trip: t,
                    statusColor: _statusColor(t.status),
                    statusIcon: _statusIcon(t.status),
                    isSelected: _selectedTrips.contains(t.id),
                    isSelectionMode: _isSelectionMode,
                    onTap: () {
                      if (_isSelectionMode) {
                        _toggleTipSelection(t.id);
                      }
                    },
                    onLongPress: () {
                      if (!_isSelectionMode) {
                        setState(() {
                          _isSelectionMode = true;
                          _selectedTrips.add(t.id);
                        });
                      }
                    },
                )),
                const SizedBox(height: 20),
              ],
              _sectionLabel('📋 Completed Trips (${completed.length})'),
              const SizedBox(height: 8),
              if (completed.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('No completed trips yet.',
                      style: GoogleFonts.outfit(color: AppColors.textSecondary)),
                )
              else
                ...completed.map((t) => _TripTile(
                    trip: t,
                    statusColor: _statusColor(t.status),
                    statusIcon: _statusIcon(t.status),
                    isSelected: _selectedTrips.contains(t.id),
                    isSelectionMode: _isSelectionMode,
                    onTap: () {
                      if (_isSelectionMode) {
                        _toggleTipSelection(t.id);
                      }
                    },
                    onLongPress: () {
                      if (!_isSelectionMode) {
                        setState(() {
                          _isSelectionMode = true;
                          _selectedTrips.add(t.id);
                        });
                      }
                    },
                )),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(text,
        style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary));
  }
}

class _TripTile extends StatelessWidget {
  final TripModel trip;
  final Color statusColor;
  final IconData statusIcon;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _TripTile({
    required this.trip, 
    required this.statusColor, 
    required this.statusIcon,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final date = trip.completedAt ?? trip.createdAt;
    final dateStr =
        '${date.day}/${date.month}/${date.year}  ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    final pickedCount = trip.students
        .where((s) =>
            s.status == StudentTripStatus.droppedAtSchool ||
            s.status == StudentTripStatus.droppedHome ||
            s.status == StudentTripStatus.boardedReturn ||
            s.status == StudentTripStatus.pickedUp)
        .length;

    final bgColor = isSelected 
        ? AppColors.error.withValues(alpha: 0.1) 
        : AppColors.surfaceElevated;
    final borderColor = isSelected 
        ? AppColors.error 
        : AppColors.border;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: isSelected ? 1.5 : 1.0),
        ),
        child: Row(
          children: [
            if (isSelectionMode) ...[
              Icon(
                isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                color: isSelected ? AppColors.error : AppColors.textHint,
                size: 22,
              ),
              const SizedBox(width: 14),
            ],
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(statusIcon, color: statusColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bus ${trip.busNumber}  •  ${trip.driverName}',
                      style: GoogleFonts.outfit(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(dateStr,
                      style: GoogleFonts.outfit(
                          color: AppColors.textSecondary, fontSize: 11)),
                ],
              ),
            ),
            if (!isSelectionMode)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(trip.status.label,
                        style: GoogleFonts.outfit(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 4),
                  Text('$pickedCount/${trip.students.length} students',
                      style: GoogleFonts.outfit(
                          color: AppColors.textHint, fontSize: 10)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
