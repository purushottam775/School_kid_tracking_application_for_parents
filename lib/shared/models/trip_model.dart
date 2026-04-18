import 'package:cloud_firestore/cloud_firestore.dart';

enum TripStatus { idle, morningPickup, atSchool, returnTrip, completed }

extension TripStatusExt on TripStatus {
  String get value {
    switch (this) {
      case TripStatus.idle:
        return 'idle';
      case TripStatus.morningPickup:
        return 'morning_pickup';
      case TripStatus.atSchool:
        return 'at_school';
      case TripStatus.returnTrip:
        return 'return_trip';
      case TripStatus.completed:
        return 'completed';
    }
  }

  String get label {
    switch (this) {
      case TripStatus.idle:
        return 'Idle';
      case TripStatus.morningPickup:
        return 'Morning Pickup';
      case TripStatus.atSchool:
        return 'At School';
      case TripStatus.returnTrip:
        return 'Return Trip';
      case TripStatus.completed:
        return 'Completed';
    }
  }

  static TripStatus fromString(String val) {
    switch (val) {
      case 'morning_pickup':
        return TripStatus.morningPickup;
      case 'at_school':
        return TripStatus.atSchool;
      case 'return_trip':
        return TripStatus.returnTrip;
      case 'completed':
        return TripStatus.completed;
      default:
        return TripStatus.idle;
    }
  }
}

enum StudentTripStatus { waiting, pickedUp, droppedAtSchool, boardedReturn, droppedHome }

extension StudentTripStatusExt on StudentTripStatus {
  String get value {
    switch (this) {
      case StudentTripStatus.waiting:
        return 'waiting';
      case StudentTripStatus.pickedUp:
        return 'picked_up';
      case StudentTripStatus.droppedAtSchool:
        return 'dropped_at_school';
      case StudentTripStatus.boardedReturn:
        return 'boarded_return';
      case StudentTripStatus.droppedHome:
        return 'dropped_home';
    }
  }

  String get label {
    switch (this) {
      case StudentTripStatus.waiting:
        return 'Waiting';
      case StudentTripStatus.pickedUp:
        return 'Picked Up';
      case StudentTripStatus.droppedAtSchool:
        return 'At School';
      case StudentTripStatus.boardedReturn:
        return 'On the Way';
      case StudentTripStatus.droppedHome:
        return 'Home';
    }
  }

  static StudentTripStatus fromString(String val) {
    switch (val) {
      case 'picked_up':
        return StudentTripStatus.pickedUp;
      case 'dropped_at_school':
        return StudentTripStatus.droppedAtSchool;
      case 'boarded_return':
        return StudentTripStatus.boardedReturn;
      case 'dropped_home':
        return StudentTripStatus.droppedHome;
      default:
        return StudentTripStatus.waiting;
    }
  }
}

class TripStudentEntry {
  final String studentId;
  final String studentName;
  final String parentId;
  final StudentTripStatus status;
  final DateTime? statusUpdatedAt;

  const TripStudentEntry({
    required this.studentId,
    required this.studentName,
    required this.parentId,
    required this.status,
    this.statusUpdatedAt,
  });

  factory TripStudentEntry.fromMap(Map<String, dynamic> map) {
    return TripStudentEntry(
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      parentId: map['parentId'] ?? '',
      status: StudentTripStatusExt.fromString(map['status'] ?? 'waiting'),
      statusUpdatedAt: (map['statusUpdatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'parentId': parentId,
      'status': status.value,
      'statusUpdatedAt': statusUpdatedAt != null
          ? Timestamp.fromDate(statusUpdatedAt!)
          : null,
    };
  }

  TripStudentEntry copyWith({StudentTripStatus? status}) {
    return TripStudentEntry(
      studentId: studentId,
      studentName: studentName,
      parentId: parentId,
      status: status ?? this.status,
      statusUpdatedAt: status != null ? DateTime.now() : statusUpdatedAt,
    );
  }
}

class TripModel {
  final String id;
  final String driverId;
  final String driverName;
  final String busId;
  final String busNumber;
  final TripStatus status;
  final List<TripStudentEntry> students;
  final DateTime? startedAt;
  final DateTime? reachedSchoolAt;
  final DateTime? returnStartedAt;
  final DateTime? completedAt;
  final DateTime createdAt;
  final double? lat;
  final double? lng;
  final DateTime? locationUpdatedAt;

  const TripModel({
    required this.id,
    required this.driverId,
    required this.driverName,
    required this.busId,
    required this.busNumber,
    required this.status,
    required this.students,
    this.startedAt,
    this.reachedSchoolAt,
    this.returnStartedAt,
    this.completedAt,
    required this.createdAt,
    this.lat,
    this.lng,
    this.locationUpdatedAt,
  });

  factory TripModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final studentsList = (data['students'] as List<dynamic>? ?? [])
        .map((s) => TripStudentEntry.fromMap(s as Map<String, dynamic>))
        .toList();

    return TripModel(
      id: doc.id,
      driverId: data['driverId'] ?? '',
      driverName: data['driverName'] ?? '',
      busId: data['busId'] ?? '',
      busNumber: data['busNumber'] ?? '',
      status: TripStatusExt.fromString(data['status'] ?? 'idle'),
      students: studentsList,
      startedAt: (data['startedAt'] as Timestamp?)?.toDate(),
      reachedSchoolAt: (data['reachedSchoolAt'] as Timestamp?)?.toDate(),
      returnStartedAt: (data['returnStartedAt'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lat: (data['lat'] as num?)?.toDouble(),
      lng: (data['lng'] as num?)?.toDouble(),
      locationUpdatedAt: (data['locationUpdatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'driverId': driverId,
      'driverName': driverName,
      'busId': busId,
      'busNumber': busNumber,
      'status': status.value,
      'students': students.map((s) => s.toMap()).toList(),
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'reachedSchoolAt': reachedSchoolAt != null
          ? Timestamp.fromDate(reachedSchoolAt!)
          : null,
      'returnStartedAt': returnStartedAt != null
          ? Timestamp.fromDate(returnStartedAt!)
          : null,
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
