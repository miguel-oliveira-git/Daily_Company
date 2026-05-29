import 'package:flutter/material.dart';
import 'package:daily_company/data/models/employee_model.dart';
import 'package:daily_company/data/repositories/employee_repository.dart';
import 'package:daily_company/data/models/team_model.dart';
import 'package:daily_company/data/repositories/team_repository.dart';

class CreateTeamPage extends StatefulWidget {
  final String companyId;

  const CreateTeamPage({super.key, required this.companyId});

  @override
  State<CreateTeamPage> createState() => _CreateTeamPageState();
}

class _CreateTeamPageState extends State<CreateTeamPage> {
  final _nameController = TextEditingController();
  final EmployeeRepository _employeeRepo = EmployeeRepository();
  final TeamRepository _teamRepo = TeamRepository();

  List<EmployeeModel> _employees = [];
  final List<String> _selectedEmployeeIds = [];
  bool _isLoadingEmployees = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    try {
      final list = await _employeeRepo.getEmployeesByCompanyId(widget.companyId);
      if (mounted) {
        setState(() {
          _employees = list;
          _isLoadingEmployees = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingEmployees = false);
    }
  }

  Future<void> _saveTeam() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, informe o nome da equipe.'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    if (_selectedEmployeeIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione pelo menos um funcionário.'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final newTeam = TeamModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        companyId: widget.companyId,
        employeeIds: _selectedEmployeeIds,
        createdAt: DateTime.now(),
      );

      await _teamRepo.createTeam(newTeam);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Equipe criada com sucesso!'), backgroundColor: Colors.green),
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao criar equipe.'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryBlue, lightBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
              ),
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.of(context).pop()),
                  const SizedBox(width: 10),
                  const Text('Criar Nova Equipe', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Nome da Equipe', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'Ex: Equipe de Desenvolvimento',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Selecione os Membros', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                    const SizedBox(height: 10),
                    Expanded(
                      child: _isLoadingEmployees
                          ? const Center(child: CircularProgressIndicator(color: primaryBlue))
                          : _employees.isEmpty
                              ? const Center(child: Text('Nenhum funcionário encontrado na empresa.'))
                              : ListView.builder(
                                  itemCount: _employees.length,
                                  itemBuilder: (context, index) {
                                    final employee = _employees[index];
                                    final isSelected = _selectedEmployeeIds.contains(employee.id);
                                    return CheckboxListTile(
                                      title: Text(employee.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                      subtitle: Text(employee.role),
                                      value: isSelected,
                                      activeColor: primaryBlue,
                                      onChanged: (bool? value) {
                                        setState(() {
                                          if (value == true) {
                                            _selectedEmployeeIds.add(employee.id);
                                          } else {
                                            _selectedEmployeeIds.remove(employee.id);
                                          }
                                        });
                                      },
                                    );
                                  },
                                ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveTeam,
                        style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: _isSaving
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Salvar Equipe', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}