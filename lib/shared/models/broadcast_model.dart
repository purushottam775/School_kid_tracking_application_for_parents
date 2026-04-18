import 'package:cloud_firestore/cloud_firestore.dart';

class BroadcastModel {
  final String id;
  final String title;
  final String message;
  final String? targetBusId;     // null means "all"
  final String? targetBusNumber; // for display
  final String? targetParentId;  // null means "all parents on the bus"
  final String sentByName;
  final DateTime createdAt;

  const BroadcastModel({
    required this.id,
    required this.title,
    required this.message,
    this.targetBusId,
    this.targetBusNumber,
    this.targetParentId,
    required this.sentByName,
    required this.createdAt,
  });

  factory BroadcastModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return BroadcastModel(
      id: doc.id,
      title: d['title'] ?? '',
      message: d['message'] ?? '',
      targetBusId: d['targetBusId'],
      targetBusNumber: d['targetBusNumber'],
      targetParentId: d['targetParentId'],
      sentByName: d['sentByName'] ?? 'Admin',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'message': message,
        'targetBusId': targetBusId,
        'targetBusNumber': targetBusNumber,
        'targetParentId': targetParentId,
        'sentByName': sentByName,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

