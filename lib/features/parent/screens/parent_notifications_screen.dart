import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/broadcast_model.dart';
import '../../admin/services/broadcast_service.dart';

/// Parent's in-app notification inbox — shows all broadcasts from school admin.
class ParentNotificationsScreen extends StatefulWidget {
  final String parentUid;
  const ParentNotificationsScreen({super.key, required this.parentUid});

  @override
  State<ParentNotificationsScreen> createState() => _ParentNotificationsScreenState();
}

class _ParentNotificationsScreenState extends State<ParentNotificationsScreen> {
  @override
  void initState() {
    super.initState();
    _markAsSeen();
  }

  Future<void> _markAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_seen_notifications_${widget.parentUid}', DateTime.now().millisecondsSinceEpoch);
  }

  Future<String> _resolveBusId() async {
    final snap = await FirebaseFirestore.instance
        .collection('students')
        .where('parentId', isEqualTo: widget.parentUid)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return '';
    return snap.docs.first.data()['busId'] as String? ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final service = BroadcastService();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Notifications',
            style: GoogleFonts.outfit(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18)),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: FutureBuilder<String>(
        future: _resolveBusId(),
        builder: (context, busSnap) {
          final busId = busSnap.data ?? '';
          return StreamBuilder<List<BroadcastModel>>(
            stream: service.streamForParent(busId, parentUid),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final broadcasts = snap.data ?? [];
              if (broadcasts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.notifications_none_rounded,
                          size: 56, color: AppColors.textHint),
                      const SizedBox(height: 14),
                      Text('No announcements yet',
                          style: GoogleFonts.outfit(
                              color: AppColors.textSecondary, fontSize: 16)),
                      const SizedBox(height: 6),
                      Text('School broadcasts will appear here',
                          style: GoogleFonts.outfit(
                              color: AppColors.textHint, fontSize: 13)),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: broadcasts.length,
                itemBuilder: (_, i) =>
                    _NotificationTile(broadcast: broadcasts[i]),
              );
            },
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final BroadcastModel broadcast;
  const _NotificationTile({required this.broadcast});

  @override
  Widget build(BuildContext context) {
    final date = broadcast.createdAt;
    final now = DateTime.now();
    final diff = now.difference(date);
    final String timeAgo;
    if (diff.inMinutes < 1) {
      timeAgo = 'Just now';
    } else if (diff.inHours < 1) {
      timeAgo = '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      timeAgo = '${diff.inHours}h ago';
    } else {
      timeAgo =
          '${date.day}/${date.month}/${date.year}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: AppColors.adminGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.campaign_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(broadcast.title,
                          style: GoogleFonts.outfit(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                    ),
                    Text(timeAgo,
                        style: GoogleFonts.outfit(
                            color: AppColors.textHint, fontSize: 10)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(broadcast.message,
                    style: GoogleFonts.outfit(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.45)),
                if (broadcast.targetBusNumber != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.driverColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('Bus ${broadcast.targetBusNumber}',
                        style: GoogleFonts.outfit(
                            color: AppColors.driverColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
                const SizedBox(height: 4),
                Text('From: ${broadcast.sentByName}',
                    style: GoogleFonts.outfit(
                        color: AppColors.textHint, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
