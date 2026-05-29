import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daily_company/data/models/employee_model.dart';

class EmployeeRepository {
  final FirebaseFirestore _firestore;

  EmployeeRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> createEmployee(EmployeeModel employee) async {
    try {
      await _firestore
          .collection('employees')
          .doc(employee.id)
          .set(employee.toFirestore());
    } catch (e) {
      throw Exception('Erro ao criar funcionário: $e');
    }
  }

  /// Busca funcionários por ID da empresa
  Future<List<EmployeeModel>> getEmployeesByCompanyId(String companyId) async {
    try {
      final query = await _firestore
          .collection('employees')
          .where('companyId', isEqualTo: companyId)
          .get();

      final list = query.docs
          .map((doc) => EmployeeModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();
      list.sort((a, b) => b.linkedAt.compareTo(a.linkedAt));
      return list;
    } catch (e) {
      throw Exception('Erro ao buscar funcionários: $e');
    }
  }

  /// Stream de funcionários em tempo real
  Stream<List<EmployeeModel>> getEmployeesStream(String companyId) {
    try {
      return _firestore
          .collection('employees')
          .where('companyId', isEqualTo: companyId)
          .snapshots()
          .map((snapshot) {
            final list = snapshot.docs
                .map((doc) =>
                    EmployeeModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
                .toList();
            list.sort((a, b) => b.linkedAt.compareTo(a.linkedAt));
            return list;
          });
    } catch (e) {
      throw Exception('Erro ao obter stream de funcionários: $e');
    }
  }

  /// Busca um funcionário por ID
  Future<EmployeeModel?> getEmployeeById(String employeeId) async {
    try {
      final doc = await _firestore.collection('employees').doc(employeeId).get();

      if (!doc.exists) return null;

      return EmployeeModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>);
    } catch (e) {
      throw Exception('Erro ao buscar funcionário: $e');
    }
  }

  /// Atualiza um funcionário
  Future<void> updateEmployee(EmployeeModel employee) async {
    try {
      await _firestore
          .collection('employees')
          .doc(employee.id)
          .update(employee.toFirestore());
    } catch (e) {
      throw Exception('Erro ao atualizar funcionário: $e');
    }
  }

  /// Deleta um funcionário
  Future<void> deleteEmployee(String employeeId) async {
    try {
      await _firestore.collection('employees').doc(employeeId).delete();
    } catch (e) {
      throw Exception('Erro ao deletar funcionário: $e');
    }
  }

  /// Conta funcionários de uma empresa
  Future<int> countEmployeesByCompanyId(String companyId) async {
    try {
      final query = await _firestore
          .collection('employees')
          .where('companyId', isEqualTo: companyId)
          .count()
          .get();

      return query.count ?? 0;
    } catch (e) {
      throw Exception('Erro ao contar funcionários: $e');
    }
  }

  /// Busca funcionário por código da empresa e e-mail
  Future<EmployeeModel?> getEmployeeByCodeAndEmail(String companyCode, String email) async {
    try {
      final query = await _firestore
          .collection('employees')
          .where('companyCode', isEqualTo: companyCode)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;

      return EmployeeModel.fromFirestore(
          query.docs.first as DocumentSnapshot<Map<String, dynamic>>);
    } catch (e) {
      throw Exception('Erro ao buscar funcionário por código e e-mail: $e');
    }
  }
}
