import 'package:daily_company/domain/entities/employee.dart';

/// Contrato abstrato para repositório de funcionários
abstract class IEmployeeRepository {
  /// Cria um novo funcionário
  Future<void> createEmployee(Employee employee);

  /// Busca funcionários por ID da empresa
  Future<List<Employee>> getEmployeesByCompanyId(String companyId);

  /// Stream de funcionários em tempo real
  Stream<List<Employee>> getEmployeesStream(String companyId);

  /// Busca um funcionário por ID
  Future<Employee?> getEmployeeById(String employeeId);

  /// Atualiza um funcionário
  Future<void> updateEmployee(Employee employee);

  /// Deleta um funcionário
  Future<void> deleteEmployee(String employeeId);

  /// Conta funcionários de uma empresa
  Future<int> countEmployeesByCompanyId(String companyId);

  /// Busca funcionário por código da empresa e e-mail
  Future<Employee?> getEmployeeByCodeAndEmail(String companyCode, String email);
}
