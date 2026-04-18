import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/models/bus_model.dart';

class BusService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = 'buses';

  Future<void> createBus({
    required String busNumber,
    required String driverId,
    required String driverName,
  }) async {
    final docRef = _db.collection(_collection).doc();
    final bus = BusModel(
      id: docRef.id,
      busNumber: busNumber,
      driverId: driverId,
      driverName: driverName,
      createdAt: DateTime.now(),
    );
    await docRef.set(bus.toMap());
  }

  Future<void> updateBus(String busId, {
    String? busNumber,
    String? driverId,
    String? driverName,
  }) async {
    final updates = <String, dynamic>{};
    if (busNumber != null) updates['busNumber'] = busNumber;
    if (driverId != null) updates['driverId'] = driverId;
    if (driverName != null) updates['driverName'] = driverName;

    if (updates.isNotEmpty) {
      await _db.collection(_collection).doc(busId).update(updates);
    }
  }

  Future<void> deleteBus(String busId) async {
    await _db.collection(_collection).doc(busId).delete();
  }

  Stream<List<BusModel>> streamBuses() {
    return _db
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BusModel.fromFirestore(doc))
            .toList());
  }

  Stream<BusModel?> streamBusForDriver(String driverId) {
    return _db
        .collection(_collection)
        .where('driverId', isEqualTo: driverId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return BusModel.fromFirestore(snapshot.docs.first);
    });
  }
}
