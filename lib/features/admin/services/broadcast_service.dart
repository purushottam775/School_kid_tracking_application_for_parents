import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/models/broadcast_model.dart';
import '../../../core/services/notification_service.dart';

class BroadcastService {
  final _col = FirebaseFirestore.instance.collection('broadcasts');

  // ── Send a new broadcast ────────────────────────────────────────────────────
  Future<void> sendBroadcast(BroadcastModel broadcast) async {
    await _col.add(broadcast.toMap());
    // Show local system notification immediately on the sender's device too
    await NotificationService.instance.showBroadcast(
      title: broadcast.title,
      body: broadcast.message,
    );
  }

  // ── Stream all broadcasts (newest first) ───────────────────────────────────
  Stream<List<BroadcastModel>> streamAll() {
    return _col
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => BroadcastModel.fromFirestore(d)).toList());
  }

  // ── Stream broadcasts visible to a parent's bus ───────────────────────────
  /// Returns global broadcasts + any targeted to the given busId + targeted to the given parentUid
  Stream<List<BroadcastModel>> streamForParent(String busId, String parentUid) {
    // Firestore doesn't support OR-queries across two fields natively,
    // so we combine two streams on the Dart side.
    return _col
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) {
      final all = s.docs.map((d) => BroadcastModel.fromFirestore(d)).toList();
      return all
          .where((b) =>
              (b.targetBusId == null || b.targetBusId == busId) &&
              (b.targetParentId == null || b.targetParentId == parentUid))
          .toList();
    });
  }

  // ── Delete a broadcast ─────────────────────────────────────────────────────
  Future<void> delete(String broadcastId) async {
    await _col.doc(broadcastId).delete();
  }
}
