import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daily_company/data/models/employee_model.dart';
import 'package:daily_company/data/repositories/employee_repository.dart';
import 'employees_page.dart';
import 'employee_edit_page.dart';

class EmployeeListPage extends StatefulWidget {
  const EmployeeListPage({super.key});

  @override
  State<EmployeeListPage> createState() => _EmployeeListPageState();
}

class _EmployeeListPageState extends State<EmployeeListPage> {
  String? _companyId;
  bool _isLoading = true;
  late EmployeeRepository _employeeRepository;

  @override
  void initState() {
    super.initState();
    _employeeRepository = EmployeeRepository();
    _loadCompanyId();
  }

  Future<void> _loadCompanyId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? storedCompanyId = prefs.getString('companyId');

      // Se não tiver no cache, busca no banco
      if (storedCompanyId == null) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final query = await FirebaseFirestore.instance
              .collection('companies')
              .where('ownerUid', isEqualTo: user.uid)
              .limit(1)
              .get();

          if (query.docs.isNotEmpty) {
            storedCompanyId = query.docs.first.id;
            await prefs.setString('companyId', storedCompanyId);
          } else {
            final queryFallback = await FirebaseFirestore.instance
                .collection('companies')
                .where('userId', isEqualTo: user.uid)
                .limit(1)
                .get();
            
            if (queryFallback.docs.isNotEmpty) {
              storedCompanyId = queryFallback.docs.first.id;
              await prefs.setString('companyId', storedCompanyId);
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _companyId = storedCompanyId;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF005EB8);
    const Color lightBlue = Color(0xFF2196F3);

    return Scaffold(
      backgroundColor: const Color(0xFFEFF4FB),
      body: SafeArea(
        child: Column(
          children: [
            // Cabeçalho
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryBlue, lightBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Funcionários',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            // Lista de Funcionários
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: primaryBlue))
                  : _companyId == null
                      ? const Center(child: Text('Empresa não encontrada.'))
                      : StreamBuilder<List<EmployeeModel>>(
                          stream: _employeeRepository.getEmployeesStream(_companyId!),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator(color: primaryBlue));
                            }
                            if (snapshot.hasError) {
                              return const Center(child: Text('Erro ao carregar funcionários.'));
                            }
                            
                            final employees = snapshot.data ?? [];
                            
                            if (employees.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Nenhum funcionário cadastrado.',
                                      style: TextStyle(fontSize: 16, color: Colors.black54),
                                    ),
                                  ],
                                ),
                              );
                            }
                            
                            return ListView.builder(
                              padding: const EdgeInsets.all(20),
                              itemCount: employees.length,
                              itemBuilder: (context, index) {
                                final employee = employees[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 2,
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(builder: (_) => EmployeeEditPage(employee: employee)),
                                      );
                                    },
                                    leading: CircleAvatar(
                                      backgroundColor: primaryBlue.withValues(alpha: 0.1),
                                      child: const Icon(Icons.person, color: primaryBlue),
                                    ),
                                    title: Text(
                                      employee.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Text(
                                          employee.role,
                                          style: const TextStyle(color: primaryBlue, fontWeight: FontWeight.w500),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          employee.email,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                                  ),
                                );
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Redireciona para a área de cadastro
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const EmployeesPage()),
          );
        },
        backgroundColor: const Color(0xFF005EB8),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Novo Funcionário',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}