import 'package:cloud_firestore/cloud_firestore.dart';

class StudentModel {
  final String id;
  final String name;
  final String className;
  final String parentId;
  final String parentName;
  final String busId;
  final String busNumber;
  final String pickupAddress;
  final double? pickupLat;
  final double? pickupLng;
  final String? photoUrl;
  final DateTime createdAt;

  const StudentModel({
    required this.id,
    required this.name,
    required this.className,
    required this.parentId,
    required this.parentName,
    this.busId = '',
    this.busNumber = '',
    required this.pickupAddress,
    this.pickupLat,
    this.pickupLng,
    this.photoUrl,
    required this.createdAt,
  });

  factory StudentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StudentModel(
      id: doc.id,
      name: data['name'] ?? '',
      className: data['className'] ?? '',
      parentId: data['parentId'] ?? '',
      parentName: data['parentName'] ?? '',
      busId: data['busId'] ?? '',
      busNumber: data['busNumber'] ?? '',
      pickupAddress: data['pickupAddress'] ?? '',
      pickupLat: (data['pickupLat'] as num?)?.toDouble(),
      pickupLng: (data['pickupLng'] as num?)?.toDouble(),
      photoUrl: data['photoUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'className': className,
      'parentId': parentId,
      'parentName': parentName,
      'busId': busId,
      'busNumber': busNumber,
      'pickupAddress': pickupAddress,
      'pickupLat': pickupLat,
      'pickupLng': pickupLng,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  StudentModel copyWith({
    String? name,
    String? className,
    String? busId,
    String? busNumber,
    String? pickupAddress,
    double? pickupLat,
    double? pickupLng,
    String? photoUrl,
  }) {
    return StudentModel(
      id: id,
      name: name ?? this.name,
      className: className ?? this.className,
      parentId: parentId,
      parentName: parentName,
      busId: busId ?? this.busId,
      busNumber: busNumber ?? this.busNumber,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      pickupLat: pickupLat ?? this.pickupLat,
      pickupLng: pickupLng ?? this.pickupLng,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt,
    );
  }
}
