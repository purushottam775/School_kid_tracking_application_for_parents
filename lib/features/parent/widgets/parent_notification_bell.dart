import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/broadcast_model.dart';
import '../../admin/services/broadcast_service.dart';
import 'parent_notifications_screen.dart';

class ParentNotificationBell extends StatefulWidget {
  final String parentUid;
  final String busId; // Best to provide the busId if possible, or we resolve inside. For bell, we can resolve or stream all and just count global. Let's just stream global for now or pass busId if available.

  const ParentNotificationBell({
    super.key,
    required this.parentUid,
    required this.busId,
  });

  @override
  State<ParentNotificationBell> createState() => _ParentNotificationBellState();
}

class _ParentNotificationBellState extends State<ParentNotificationBell> {
  DateTime? _lastSeen;

  @override
  void initState() {
    super.initState();
    _loadLastSeen();
  }

  Future<void> _loadLastSeen() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt('last_seen_notifications_${widget.parentUid}');
    if (ms != null) {
      setState(() {
        _lastSeen = DateTime.fromMillisecondsSinceEpoch(ms);
      });
    } else {
      setState(() {
        _lastSeen = DateTime.fromMillisecondsSinceEpoch(0); // Very old
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_lastSeen == null) {
      return _buildStaticBell(); // Loading
    }

    return StreamBuilder<List<BroadcastModel>>(
      stream: BroadcastService().streamForParent(widget.busId, widget.parentUid),
      builder: (context, snap) {
        final broadcasts = snap.data ?? [];
        int unreadCount = 0;
        for (var b in broadcasts) {
          if (b.createdAt.isAfter(_lastSeen!)) {
            unreadCount++;
          }
        }

        return GestureDetector(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ParentNotificationsScreen(parentUid: widget.parentUid),
              ),
            );
            // Refresh last seen after coming back
            _loadLastSeen();
          },
          child: Stack(
            children: [
              _buildStaticBell(),
              if (unreadCount > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        unreadCount > 9 ? '9+' : '$unreadCount',
                        style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStaticBell() {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: const Icon(Icons.notifications_outlined,
          color: AppColors.textSecondary, size: 20),
    );
  }
}
