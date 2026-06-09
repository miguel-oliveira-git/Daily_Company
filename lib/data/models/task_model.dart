import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  final String id;
  final String title;
  final String description;
  final String referenceLink;
  final DateTime date;
  final String time;
  final String assignedEmployeeId;
  final String assignedEmployeeName;
  final String companyId;
  final String creatorId;
  final String status;
  final DateTime createdAt;
  final DateTime? deadline;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    this.referenceLink = '',
    required this.date,
    required this.time,
    required this.assignedEmployeeId,
    required this.assignedEmployeeName,
    required this.companyId,
    required this.creatorId,
    this.status = 'pending',
    required this.createdAt,
    this.deadline,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'referenceLink': referenceLink,
      'date': Timestamp.fromDate(date),
      'time': time,
      'assignedEmployeeId': assignedEmployeeId,
      'assignedEmployeeName': assignedEmployeeName,
      'companyId': companyId,
      'creatorId': creatorId,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'deadline': deadline != null ? Timestamp.fromDate(deadline!) : null,
    };
  }

  factory TaskModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return TaskModel(
      id: data['id'] ?? doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      referenceLink: data['referenceLink'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      time: data['time'] ?? '',
      assignedEmployeeId: data['assignedEmployeeId'] ?? '',
      assignedEmployeeName: data['assignedEmployeeName'] ?? '',
      companyId: data['companyId'] ?? '',
      creatorId: data['creatorId'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      deadline: data['deadline'] != null ? (data['deadline'] as Timestamp).toDate() : null,
    );
  }
}