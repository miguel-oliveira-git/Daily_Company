class Employee {
  final String id;
  final String name;
  final String role;
  final String email;
  final String companyCode;
  final String companyId;
  final String companyName;
  final DateTime linkedAt;

  Employee({
    required this.id,
    required this.name,
    required this.role,
    required this.email,
    required this.companyCode,
    required this.companyId,
    required this.companyName,
    required this.linkedAt,
  });

  /// Cria cópia com possibilidade de modificação
  Employee copyWith({
    String? id,
    String? name,
    String? role,
    String? email,
    String? companyCode,
    String? companyId,
    String? companyName,
    DateTime? linkedAt,
  }) {
    return Employee(
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
    return 'Employee(id: $id, name: $name, role: $role, email: $email, companyCode: $companyCode)';
  }
}
