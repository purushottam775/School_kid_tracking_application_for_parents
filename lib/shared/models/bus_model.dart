import 'package:cloud_firestore/cloud_firestore.dart';

class BusModel {
  final String id;
  final String busNumber;
  final String driverId;
  final String driverName;
  final DateTime createdAt;

  const BusModel({
    required this.id,
    required this.busNumber,
    required this.driverId,
    required this.driverName,
    required this.createdAt,
  });

  factory BusModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BusModel(
      id: doc.id,
      busNumber: data['busNumber'] ?? '',
      driverId: data['driverId'] ?? '',
      driverName: data['driverName'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'busNumber': busNumber,
      'driverId': driverId,
      'driverName': driverName,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  BusModel copyWith({
    String? busNumber,
    String? driverId,
    String? driverName,
  }) {
    return BusModel(
      id: id,
      busNumber: busNumber ?? this.busNumber,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      createdAt: createdAt,
    );
  }
}
