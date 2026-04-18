import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/models/user_model.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Stream all users of a given role ────────────────────────────────────────
  Stream<List<UserModel>> streamUsersByRole(UserRole role) {
    return _db
        .collection('users')
        .where('role', isEqualTo: role.value)
        .snapshots()
        .map((s) => s.docs.map((d) => UserModel.fromFirestore(d)).toList());
  }

  // ── Stream ALL users (any role) ─────────────────────────────────────────────
  Stream<List<UserModel>> streamAllUsers() {
    return _db
        .collection('users')
        .snapshots()
        .map((s) => s.docs.map((d) => UserModel.fromFirestore(d)).toList());
  }

  // ── Update a user's basic info (admin edit) ──────────────────────────────────
  Future<void> updateUser(String uid, {String? name, String? phone, UserRole? role}) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (phone != null) updates['phone'] = phone;
    if (role != null) updates['role'] = role.value;
    if (updates.isNotEmpty) {
      await _db.collection('users').doc(uid).update(updates);
    }
  }

  // ── Deep-delete: removes user + all linked data ──────────────────────────────
  Future<void> deleteUser(String uid, UserRole role) async {
    final batch = _db.batch();

    if (role == UserRole.parent) {
      // Delete all students that belong to this parent
      final students = await _db
          .collection('students')
          .where('parentId', isEqualTo: uid)
          .get();
      for (final doc in students.docs) {
        batch.delete(doc.reference);
      }
    } else if (role == UserRole.driver) {
      // Unlink driver from any buses they are assigned to
      final buses = await _db
          .collection('buses')
          .where('driverId', isEqualTo: uid)
          .get();
      for (final doc in buses.docs) {
        batch.update(doc.reference, {'driverId': '', 'driverName': ''});
      }
    }

    // Delete the user document itself
    batch.delete(_db.collection('users').doc(uid));
    await batch.commit();
  }
}

