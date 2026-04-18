import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/models/trip_model.dart';
import '../../../shared/models/student_model.dart';
import '../../../shared/models/broadcast_model.dart';
import '../../admin/services/broadcast_service.dart';

class TripService {
  final _trips = FirebaseFirestore.instance.collection('trips');
  final _broadcasts = BroadcastService();

  Future<void> _sendAutoNotification({
    required String title,
    required String message,
    required String? targetBusId,
    String? targetBusNumber,
    String? targetParentId,
    required String driverName,
  }) async {
    await _broadcasts.sendBroadcast(BroadcastModel(
      id: '',
      title: title,
      message: message,
      targetBusId: targetBusId,
      targetBusNumber: targetBusNumber,
      targetParentId: targetParentId,
      sentByName: driverName,
      createdAt: DateTime.now(),
    ));
  }

  // ── Check if driver has an active trip today ───────────────────────────────
  Stream<TripModel?> streamActiveTrip(String driverId) {
    return _trips
        .where('driverId', isEqualTo: driverId)
        .where('status', whereIn: [
          TripStatus.morningPickup.value,
          TripStatus.atSchool.value,
          TripStatus.returnTrip.value,
        ])
        .snapshots()
        .map((snap) {
          if (snap.docs.isEmpty) return null;
          final trips = snap.docs.map((d) => TripModel.fromFirestore(d)).toList();
          trips.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return trips.first;
        });
  }

  // ── Parent: stream the active trip for their child's bus ──────────────────
  Stream<TripModel?> streamActiveTripForBus(String busId) {
    return _trips
        .where('busId', isEqualTo: busId)
        .where('status', whereIn: [
          TripStatus.morningPickup.value,
          TripStatus.atSchool.value,
          TripStatus.returnTrip.value,
        ])
        .snapshots()
        .map((snap) {
          if (snap.docs.isEmpty) return null;
          final trips = snap.docs.map((d) => TripModel.fromFirestore(d)).toList();
          trips.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return trips.first;
        });
  }

  // ── Start morning trip ────────────────────────────────────────────────────
  Future<String> startMorningTrip({
    required String driverId,
    required String driverName,
    required String busId,
    required String busNumber,
    required List<StudentModel> students,
  }) async {
    final entries = students
        .map((s) => TripStudentEntry(
              studentId: s.id,
              studentName: s.name,
              parentId: s.parentId,
              status: StudentTripStatus.waiting,
            ))
        .toList();

    final trip = TripModel(
      id: '',
      driverId: driverId,
      driverName: driverName,
      busId: busId,
      busNumber: busNumber,
      status: TripStatus.morningPickup,
      students: entries,
      startedAt: DateTime.now(),
      createdAt: DateTime.now(),
    );

    final doc = await _trips.add(trip.toMap());

    // Send global notification
    await _sendAutoNotification(
      title: 'Morning Trip Started',
      message: 'Bus $busNumber is starting the morning trip.',
      targetBusId: busId,
      targetBusNumber: busNumber,
      driverName: driverName,
    );

    return doc.id;
  }

  // ── Mark individual student as picked up ─────────────────────────────────
  Future<void> markStudentPickedUp(TripModel trip, String studentId) async {
    final updated = trip.students.map((s) {
      if (s.studentId == studentId) {
        return s.copyWith(status: StudentTripStatus.pickedUp);
      }
      return s;
    }).toList();

    await _trips.doc(trip.id).update({
      'students': updated.map((s) => s.toMap()).toList(),
    });

    final student = trip.students.firstWhere((s) => s.studentId == studentId);
    await _sendAutoNotification(
      title: 'Student Picked Up',
      message: '${student.studentName} has been picked up.',
      targetBusId: trip.busId,
      targetBusNumber: trip.busNumber,
      targetParentId: student.parentId,
      driverName: trip.driverName,
    );
  }

  // ── Mark all students as reached school ──────────────────────────────────
  Future<void> markReachedSchool(TripModel trip) async {
    final updated = trip.students.map((s) {
      return s.copyWith(status: StudentTripStatus.droppedAtSchool);
    }).toList();

    await _trips.doc(trip.id).update({
      'status': TripStatus.atSchool.value,
      'reachedSchoolAt': Timestamp.fromDate(DateTime.now()),
      'students': updated.map((s) => s.toMap()).toList(),
    });

    await _sendAutoNotification(
      title: 'Reached School',
      message: 'Bus ${trip.busNumber} has reached the school.',
      targetBusId: trip.busId,
      targetBusNumber: trip.busNumber,
      driverName: trip.driverName,
    );
  }

  // ── Start return trip ─────────────────────────────────────────────────────
  Future<void> startReturnTrip(TripModel trip) async {
    final updated = trip.students.map((s) {
      return s.copyWith(status: StudentTripStatus.boardedReturn);
    }).toList();

    await _trips.doc(trip.id).update({
      'status': TripStatus.returnTrip.value,
      'returnStartedAt': Timestamp.fromDate(DateTime.now()),
      'students': updated.map((s) => s.toMap()).toList(),
    });

    await _sendAutoNotification(
      title: 'Return Trip Started',
      message: 'Bus ${trip.busNumber} is starting the return trip.',
      targetBusId: trip.busId,
      targetBusNumber: trip.busNumber,
      driverName: trip.driverName,
    );
  }

  // ── Mark individual student dropped home ─────────────────────────────────
  Future<void> markStudentDroppedHome(TripModel trip, String studentId) async {
    final updated = trip.students.map((s) {
      if (s.studentId == studentId) {
        return s.copyWith(status: StudentTripStatus.droppedHome);
      }
      return s;
    }).toList();

    await _trips.doc(trip.id).update({
      'students': updated.map((s) => s.toMap()).toList(),
    });

    final student = trip.students.firstWhere((s) => s.studentId == studentId);
    await _sendAutoNotification(
      title: 'Student Dropped Home',
      message: '${student.studentName} has been dropped home.',
      targetBusId: trip.busId,
      targetBusNumber: trip.busNumber,
      targetParentId: student.parentId,
      driverName: trip.driverName,
    );
  }

  // ── End trip ──────────────────────────────────────────────────────────────
  Future<void> endTrip(String tripId) async {
    await _trips.doc(tripId).update({
      'status': TripStatus.completed.value,
      'completedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // ── Update live GPS location ───────────────────────────────────────────────
  Future<void> updateLocation(String tripId, double lat, double lng) async {
    await _trips.doc(tripId).update({
      'lat': lat,
      'lng': lng,
      'locationUpdatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // ── Parent: stream completed trips for a bus (history) ───────────────────
  Stream<List<TripModel>> streamCompletedTripsForBus(String busId) {
    return _trips
        .where('busId', isEqualTo: busId)
        .where('status', isEqualTo: TripStatus.completed.value)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((d) => TripModel.fromFirestore(d)).toList();
      // Sort locally to avoid needing a Firestore Composite Index
      list.sort((a, b) {
        final aDate = a.completedAt ?? a.createdAt;
        final bDate = b.completedAt ?? b.createdAt;
        return bDate.compareTo(aDate); // descending
      });
      return list.take(10).toList();
    });
  }

  // ── Driver: stream their own completed trips (history) ───────────────────
  Stream<List<TripModel>> streamCompletedTripsForDriver(String driverId) {
    return _trips
        .where('driverId', isEqualTo: driverId)
        .where('status', isEqualTo: TripStatus.completed.value)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((d) => TripModel.fromFirestore(d)).toList();
      // Sort locally to avoid needing a Firestore Composite Index
      list.sort((a, b) {
        final aDate = a.completedAt ?? a.createdAt;
        final bDate = b.completedAt ?? b.createdAt;
        return bDate.compareTo(aDate); // descending
      });
      return list.take(10).toList();
    });
  }
}
