import 'package:cloud_firestore/cloud_firestore.dart';

class SchoolSettings {
  final String name;
  final double? lat;
  final double? lng;
  final String? address;

  const SchoolSettings({
    required this.name,
    this.lat,
    this.lng,
    this.address,
  });

  bool get hasLocation => lat != null && lng != null;

  factory SchoolSettings.fromMap(Map<String, dynamic> data) {
    return SchoolSettings(
      name: data['schoolName'] ?? 'School',
      lat: (data['schoolLat'] as num?)?.toDouble(),
      lng: (data['schoolLng'] as num?)?.toDouble(),
      address: data['schoolAddress'],
    );
  }

  Map<String, dynamic> toMap() => {
        'schoolName': name,
        if (lat != null) 'schoolLat': lat,
        if (lng != null) 'schoolLng': lng,
        if (address != null) 'schoolAddress': address,
      };
}

class SchoolSettingsService {
  final _doc = FirebaseFirestore.instance
      .collection('app_settings')
      .doc('school');

  Stream<SchoolSettings> stream() {
    return _doc.snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) {
        return const SchoolSettings(name: 'School');
      }
      return SchoolSettings.fromMap(snap.data()!);
    });
  }

  Future<SchoolSettings> fetch() async {
    final snap = await _doc.get();
    if (!snap.exists || snap.data() == null) {
      return const SchoolSettings(name: 'School');
    }
    return SchoolSettings.fromMap(snap.data()!);
  }

  Future<void> save(SchoolSettings settings) async {
    await _doc.set(settings.toMap(), SetOptions(merge: true));
  }
}
