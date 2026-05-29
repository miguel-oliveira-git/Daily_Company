import 'package:flutter_test/flutter_test.dart';
import 'package:daily_company/data/models/employee_model.dart';
import 'package:daily_company/domain/entities/employee.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('Employee Model Tests', () {
    test('EmployeeModel.toFirestore() converte corretamente', () {
      final employee = EmployeeModel(
        id: '123',
        name: 'João Silva',
        role: 'Desenvolvedor',
        email: 'joao@empresa.com',
        companyCode: 'EMP-2026-ABC',
        companyId: 'company-123',
        companyName: 'Minha Empresa',
        linkedAt: DateTime(2026, 5, 28),
      );

      final firestore = employee.toFirestore();

      expect(firestore['id'], equals('123'));
      expect(firestore['name'], equals('João Silva'));
      expect(firestore['email'], equals('joao@empresa.com'));
      expect(firestore['companyCode'], equals('EMP-2026-ABC'));
    });

    test('EmployeeModel.fromMap() cria instância corretamente', () {
      final map = {
        'id': '123',
        'name': 'Maria Silva',
        'role': 'Gerente',
        'email': 'maria@empresa.com',
        'companyCode': 'EMP-2026-XYZ',
        'companyId': 'company-456',
        'companyName': 'Outra Empresa',
        'linkedAt': DateTime(2026, 5, 28),
      };

      final employee = EmployeeModel.fromMap(map);

      expect(employee.id, equals('123'));
      expect(employee.name, equals('Maria Silva'));
      expect(employee.role, equals('Gerente'));
    });

    test('EmployeeModel.copyWith() cria cópia com modificações', () {
      final original = EmployeeModel(
        id: '123',
        name: 'João',
        role: 'Dev',
        email: 'joao@empresa.com',
        companyCode: 'EMP-2026-ABC',
        companyId: 'company-123',
        companyName: 'Empresa',
        linkedAt: DateTime(2026, 5, 28),
      );

      final modified = original.copyWith(name: 'João Silva', role: 'Senior Dev');

      expect(modified.name, equals('João Silva'));
      expect(modified.role, equals('Senior Dev'));
      expect(modified.id, equals(original.id)); // id não mudou
      expect(modified.email, equals(original.email)); // email não mudou
    });
  });

  group('Employee Entity Tests', () {
    test('Employee entity pode ser criada', () {
      final employee = Employee(
        id: '123',
        name: 'João',
        role: 'Desenvolvedor',
        email: 'joao@empresa.com',
        companyCode: 'EMP-2026-ABC',
        companyId: 'company-123',
        companyName: 'Empresa',
        linkedAt: DateTime(2026, 5, 28),
      );

      expect(employee.id, isNotEmpty);
      expect(employee.name, equals('João'));
    });

    test('Employee.copyWith() funciona corretamente', () {
      final original = Employee(
        id: '123',
        name: 'João',
        role: 'Dev',
        email: 'joao@empresa.com',
        companyCode: 'EMP-2026-ABC',
        companyId: 'company-123',
        companyName: 'Empresa',
        linkedAt: DateTime(2026, 5, 28),
      );

      final updated = original.copyWith(role: 'Senior Developer');

      expect(updated.role, equals('Senior Developer'));
      expect(original.role, equals('Dev')); // original não mudou
    });
  });

  group('Validation Tests', () {
    test('Código da empresa válido deve corresponder exatamente', () {
      const generatedCode = 'EMP-2026-ABC';
      const inputCode = 'emp-2026-abc'; // case-insensitive

      final isValid = inputCode.trim().toUpperCase() == generatedCode.toUpperCase();
      expect(isValid, isTrue);
    });

    test('Código da empresa inválido deve falhar', () {
      const generatedCode = 'EMP-2026-ABC';
      const inputCode = 'EMP-2026-XYZ';

      final isValid = inputCode.trim().toUpperCase() == generatedCode.toUpperCase();
      expect(isValid, isFalse);
    });

    test('Email válido deve passar na validação', () {
      const email = 'joao@empresa.com';
      final isValid = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
      expect(isValid, isTrue);
    });

    test('Email inválido deve falhar na validação', () {
      const email = 'joao@empresa';
      final isValid = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
      expect(isValid, isFalse);
    });

    test('Nome com menos de 3 caracteres deve falhar', () {
      const name = 'Jo';
      final isValid = name.length >= 3;
      expect(isValid, isFalse);
    });

    test('Nome com 3 ou mais caracteres deve passar', () {
      const name = 'João';
      final isValid = name.length >= 3;
      expect(isValid, isTrue);
    });
  });

  group('Company Code Generation Tests', () {
    test('Código da empresa deve estar no formato EMP-2026-XXX', () {
      const code = 'EMP-2026-ABC';
      final matches = RegExp(r'^EMP-2026-[A-Z]{3}$').hasMatch(code);
      expect(matches, isTrue);
    });

    test('Código com formato incorreto deve falhar', () {
      const code = 'INVALID-CODE';
      final matches = RegExp(r'^EMP-2026-[A-Z]{3}$').hasMatch(code);
      expect(matches, isFalse);
    });
  });

  group('EmployeeModel Equality Tests', () {
    test('Dois modelos iguais devem ter toString() iguais', () {
      final employee1 = EmployeeModel(
        id: '123',
        name: 'João',
        role: 'Dev',
        email: 'joao@empresa.com',
        companyCode: 'EMP-2026-ABC',
        companyId: 'company-123',
        companyName: 'Empresa',
        linkedAt: DateTime(2026, 5, 28),
      );

      final employee2 = EmployeeModel(
        id: '123',
        name: 'João',
        role: 'Dev',
        email: 'joao@empresa.com',
        companyCode: 'EMP-2026-ABC',
        companyId: 'company-123',
        companyName: 'Empresa',
        linkedAt: DateTime(2026, 5, 28),
      );

      expect(employee1.toString(), equals(employee2.toString()));
    });
  });

  group('Edge Cases', () {
    test('Código com espaços em branco deve ser trimado', () {
      const generatedCode = 'EMP-2026-ABC';
      const inputCode = '  EMP-2026-ABC  ';

      final isValid = inputCode.trim().toUpperCase() == generatedCode.toUpperCase();
      expect(isValid, isTrue);
    });

    test('Email com espaços deve falhar', () {
      const email = 'joao @empresa.com';
      final isValid = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
      expect(isValid, isFalse);
    });

    test('Nome vazio deve falhar', () {
      const name = '';
      final isValid = name.isNotEmpty && name.length >= 3;
      expect(isValid, isFalse);
    });

    test('Cargo vazio deve falhar', () {
      const role = '';
      final isValid = role.isNotEmpty;
      expect(isValid, isFalse);
    });
  });
}

// Exemplos de uso da funcionalidade

void exampleUsage() {
  // Exemplo 1: Criar um employee
  final employee = EmployeeModel(
    id: '${DateTime.now().millisecondsSinceEpoch}',
    name: 'João Silva',
    role: 'Desenvolvedor',
    email: 'joao@empresa.com',
    companyCode: 'EMP-2026-ABC',
    companyId: 'company-123',
    companyName: 'Minha Empresa',
    linkedAt: DateTime.now(),
  );

  // Exemplo 2: Converter para Firestore
  final firestoreData = employee.toFirestore();
  print('Firestore Data: $firestoreData');

  // Exemplo 3: Criar a partir de um Map
  final employeeFromMap = EmployeeModel.fromMap({
    'id': '456',
    'name': 'Maria Santos',
    'role': 'Gerente',
    'email': 'maria@empresa.com',
    'companyCode': 'EMP-2026-XYZ',
    'companyId': 'company-456',
    'companyName': 'Outra Empresa',
    'linkedAt': DateTime.now(),
  });

  // Exemplo 4: Copiar com modificações
  final updatedEmployee = employee.copyWith(role: 'Senior Developer');
  print('Updated: ${updatedEmployee.role}');

  // Exemplo 5: Validações
  print('Email válido: ${RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(employee.email)}');
  print('Nome válido: ${employee.name.length >= 3}');
  print('Código válido: ${employee.companyCode.startsWith('EMP-2026')}');
}
