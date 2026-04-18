import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/models/student_model.dart';

class StudentService {
  final _col = FirebaseFirestore.instance.collection('students');

  // ─── Add student ──────────────────────────────────────────────────────────
  Future<String> addStudent(StudentModel student) async {
    final doc = await _col.add(student.toMap());
    return doc.id;
  }

  // ─── Update student ───────────────────────────────────────────────────────
  Future<void> updateStudent(String id, Map<String, dynamic> data) async {
    await _col.doc(id).update(data);
  }

  // ─── Delete student ───────────────────────────────────────────────────────
  Future<void> deleteStudent(String id) async {
    await _col.doc(id).delete();
  }

  // ─── Assign bus to student (admin only) ──────────────────────────────────
  Future<void> assignBus(String studentId, String busId, String busNumber) async {
    await _col.doc(studentId).update({
      'busId': busId,
      'busNumber': busNumber,
    });
  }

  // ─── Parents stream: only their children ─────────────────────────────────
  Stream<List<StudentModel>> streamStudentsForParent(String parentId) {
    return _col
        .where('parentId', isEqualTo: parentId)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map(StudentModel.fromFirestore).toList();
          list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          return list;
        });
  }

  // ─── Admin stream: all students ───────────────────────────────────────────
  Stream<List<StudentModel>> streamAllStudents() {
    return _col
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(StudentModel.fromFirestore).toList());
  }

  // ─── Get student count (for admin dashboard) ─────────────────────────────
  Future<int> getStudentCount() async {
    final snap = await _col.count().get();
    return snap.count ?? 0;
  }

  // ─── Students by bus (for driver) ─────────────────────────────────────────
  Stream<List<StudentModel>> streamStudentsForBus(String busId) {
    return _col
        .where('busId', isEqualTo: busId)
        .snapshots()
        .map((snap) => snap.docs.map(StudentModel.fromFirestore).toList());
  }
}
