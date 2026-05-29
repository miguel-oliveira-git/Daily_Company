import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EmployeesPage extends StatefulWidget {
  const EmployeesPage({super.key});

  @override
  State<EmployeesPage> createState() => _EmployeesPageState();
}

class _EmployeesPageState extends State<EmployeesPage> {
  final TextEditingController _employeeNameController = TextEditingController();
  final TextEditingController _roleController = TextEditingController();
  String? _generatedCode;
  String? _companyName;
  String? _companyId;
  bool _isGenerating = false;
  bool _isSaving = false;

  // ✅ CORREÇÃO: estado de carregamento para aguardar os dados da empresa
  bool _isLoadingCompany = true;

  @override
  void initState() {
    super.initState();
    // ✅ CORREÇÃO: usa whenComplete para garantir que o setState
    // só ocorre depois que todos os dados foram carregados
    _loadCompanyInfo().whenComplete(() {
      if (mounted) {
        setState(() => _isLoadingCompany = false);
      }
    });
  }

  Future<void> _loadCompanyInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    final storedName = prefs.getString('companyName');
    final storedId = prefs.getString('companyId');

    if (storedName != null && storedId != null) {
      _companyName = storedName;
      _companyId = storedId;
      debugPrint('✅ Empresa carregada do SharedPreferences: $_companyName (ID: $_companyId)');
      return; // dados encontrados localmente, não precisa ir ao Firestore
    }

    debugPrint('🔍 Buscando empresa no Firestore para UID: ${user.uid}');
    var query = await FirebaseFirestore.instance
        .collection('companies')
        .where('ownerUid', isEqualTo: user.uid)
        .limit(1)
        .get();

    // Fallback: tenta campo 'userId' caso o documento use nomenclatura diferente
    if (query.docs.isEmpty) {
      debugPrint('⚠️ Campo ownerUid não encontrado. Tentando com userId...');
      query = await FirebaseFirestore.instance
          .collection('companies')
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();
    }

    if (query.docs.isNotEmpty) {
      final doc = query.docs.first;
      _companyId = doc.id;
      _companyName = (doc.data()['name'] ?? doc.data()['companyName']) as String?;
      debugPrint('✅ Empresa encontrada no Firestore: $_companyName (ID: $_companyId)');

      // Salva localmente para as próximas sessões
      if (_companyId != null) await prefs.setString('companyId', _companyId!);
      if (_companyName != null) await prefs.setString('companyName', _companyName!);
    } else {
      debugPrint('❌ Nenhuma empresa encontrada no Firestore para este UID!');
    }
  }

  Future<String> _generateUniqueCode() async {
    const prefix = 'D-';
    final random = Random();
    for (var attempt = 0; attempt < 10; attempt++) {
      final code = '$prefix${random.nextInt(9000) + 1000}';
      final query = await FirebaseFirestore.instance
          .collection('employeeInviteCodes')
          .where('code', isEqualTo: code)
          .limit(1)
          .get();
      if (query.docs.isEmpty) return code;
    }
    throw Exception('Não foi possível gerar um código único. Tente novamente.');
  }

  Future<void> _handleGenerateCode() async {
    if (_companyId == null || _companyName == null) {
      _showError('Não foi possível localizar a empresa. Faça login novamente.');
      return;
    }

    if (_employeeNameController.text.trim().isEmpty || _roleController.text.trim().isEmpty) {
      _showError('Preencha o nome e o cargo do funcionário antes de gerar o D-CODE.');
      return;
    }

    setState(() {
      _isGenerating = true;
      _generatedCode = null;
    });

    try {
      final code = await _generateUniqueCode();
      setState(() {
        _generatedCode = code;
      });
    } catch (e) {
      _showError('Erro ao gerar o código. Tente novamente.');
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  Future<void> _handleSaveInvite() async {
    if (_generatedCode == null) {
      _showError('Gere o D-CODE antes de adicionar o funcionário.');
      return;
    }
    if (_companyId == null || _companyName == null) {
      _showError('Dados da empresa não encontrados.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await FirebaseFirestore.instance.collection('employeeInviteCodes').doc(_generatedCode).set({
        'code': _generatedCode,
        'companyId': _companyId,
        'companyName': _companyName,
        'employeeName': _employeeNameController.text.trim(),
        'employeeRole': _roleController.text.trim(),
        'createdAt': Timestamp.now(),
      });

      // Também salva o funcionário na coleção principal para aparecer na lista imediatamente
      await FirebaseFirestore.instance.collection('employees').doc(_generatedCode).set({
        'id': _generatedCode,
        'name': _employeeNameController.text.trim(),
        'role': _roleController.text.trim(),
        'email': 'Aguardando 1º acesso...', // Fica como pendente até o funcionário logar
        'companyCode': _generatedCode,
        'companyId': _companyId,
        'companyName': _companyName,
        'linkedAt': Timestamp.now(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('D-CODE salvo e pronto para ser usado.')),
      );
      // Volta para a lista de funcionários automaticamente após adicionar
      Navigator.of(context).pop();
    } catch (e) {
      _showError('Erro ao salvar o D-CODE. Tente novamente.');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  void dispose() {
    _employeeNameController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF005EB8);
    const Color lightBlue = Color(0xFF2196F3);

    // ✅ CORREÇÃO: exibe loading enquanto os dados da empresa são carregados
    if (_isLoadingCompany) {
      return const Scaffold(
        backgroundColor: Color(0xFFEFF4FB),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF005EB8)),
        ),
      );
    }

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
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Adicionar funcionário',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildInput('Nome do funcionário', _employeeNameController, 'Digite aqui'),
                      const SizedBox(height: 14),
                      _buildInput('Cargo exercido', _roleController, 'Digite aqui'),
                      const SizedBox(height: 18),
                      ElevatedButton(
                        onPressed: _isGenerating ? null : _handleGenerateCode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: primaryBlue.withValues(alpha: 0.7),
                          disabledForegroundColor: Colors.white70,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _isGenerating
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('Gerar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 12),
                          InkWell(
                            onTap: () async {
                              if (_generatedCode != null) {
                                await Clipboard.setData(ClipboardData(text: _generatedCode!));
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Código copiado com sucesso!'),
                                    backgroundColor: Colors.green,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFB0C6E4)),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                _generatedCode ?? 'D-0000',
                                style: const TextStyle(
                                  color: Color(0xFF0D3D91),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      const SizedBox(height: 4),
                          const Text(
                            '*Clique no código para copiar e envie ao funcionário',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 18),
                      ElevatedButton(
                        onPressed: _isSaving ? null : _handleSaveInvite,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: primaryBlue.withValues(alpha: 0.7),
                          disabledForegroundColor: Colors.white70,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('Adicionar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 12),
                      if (_companyName != null)
                        Text(
                          'Empresa: $_companyName',
                          style: const TextStyle(color: Colors.black54, fontSize: 14),
                        ),
                      if (_companyName == null)
                        const Text(
                          'Empresa não encontrada. Faça login novamente.',
                          style: TextStyle(color: Colors.redAccent, fontSize: 14),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: const Color(0xFFF2F2F2),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}