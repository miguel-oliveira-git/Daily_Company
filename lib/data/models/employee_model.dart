import 'package:cloud_firestore/cloud_firestore.dart';

class EmployeeModel {
  final String id;
  final String name;
  final String role;
  final String email;
  final String companyCode;
  final String companyId;
  final String companyName;
  final DateTime linkedAt;

  EmployeeModel({
    required this.id,
    required this.name,
    required this.role,
    required this.email,
    required this.companyCode,
    required this.companyId,
    required this.companyName,
    required this.linkedAt,
  });

  /// Converte para Firestore JSON
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'email': email,
      'companyCode': companyCode,
      'companyId': companyId,
      'companyName': companyName,
      'linkedAt': Timestamp.fromDate(linkedAt),
    };
  }

  /// Cria instância a partir de documento Firestore
  factory EmployeeModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return EmployeeModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      role: data['role'] as String? ?? '',
      email: data['email'] as String? ?? '',
      companyCode: data['companyCode'] as String? ?? '',
      companyId: data['companyId'] as String? ?? '',
      companyName: data['companyName'] as String? ?? '',
      linkedAt: (data['linkedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Cria instância a partir de Map (útil para testes)
  factory EmployeeModel.fromMap(Map<String, dynamic> map) {
    return EmployeeModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      role: map['role'] as String? ?? '',
      email: map['email'] as String? ?? '',
      companyCode: map['companyCode'] as String? ?? '',
      companyId: map['companyId'] as String? ?? '',
      companyName: map['companyName'] as String? ?? '',
      linkedAt: map['linkedAt'] is DateTime ? map['linkedAt'] : DateTime.now(),
    );
  }

  /// Cria cópia com possibilidade de modificação
  EmployeeModel copyWith({
    String? id,
    String? name,
    String? role,
    String? email,
    String? companyCode,
    String? companyId,
    String? companyName,
    DateTime? linkedAt,
  }) {
    return EmployeeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      email: email ?? this.email,
      companyCode: companyCode ?? this.companyCode,
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      linkedAt: linkedAt ?? this.linkedAt,
    );
  }

  @override
  String toString() {
    return 'EmployeeModel(id: $id, name: $name, role: $role, email: $email, companyCode: $companyCode)';
  }
}
