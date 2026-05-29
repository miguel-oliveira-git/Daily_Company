import 'package:cloud_firestore/cloud_firestore.dart';

class TeamModel {
  final String id;
  final String name;
  final String companyId;
  final List<String> employeeIds;
  final DateTime createdAt;

  TeamModel({
    required this.id,
    required this.name,
    required this.companyId,
    required this.employeeIds,
    required this.createdAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'companyId': companyId,
      'employeeIds': employeeIds,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory TeamModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return TeamModel(
      id: data['id'] ?? doc.id,
      name: data['name'] ?? '',
      companyId: data['companyId'] ?? '',
      employeeIds: List<String>.from(data['employeeIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}