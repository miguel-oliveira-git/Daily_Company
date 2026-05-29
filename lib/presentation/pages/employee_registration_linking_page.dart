import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daily_company/core/app_constants.dart';
import 'package:daily_company/data/models/employee_model.dart';
import 'package:daily_company/data/repositories/employee_repository.dart';

class EmployeeRegistrationLinkingPage extends StatefulWidget {
  const EmployeeRegistrationLinkingPage({super.key});

  @override
  State<EmployeeRegistrationLinkingPage> createState() => _EmployeeRegistrationLinkingPageState();
}

class _EmployeeRegistrationLinkingPageState extends State<EmployeeRegistrationLinkingPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _roleController = TextEditingController();
  final _emailController = TextEditingController();
  final _companyCodeController = TextEditingController();

  late EmployeeRepository _employeeRepository;
  String? _generatedCompanyCode;
  String? _companyId;
  String? _companyName;
  bool _isLoading = false;
  bool _isSubmitting = false;

  final List<EmployeeModel> _linkedEmployees = [];
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  @override
  void initState() {
    super.initState();
    _employeeRepository = EmployeeRepository();
    _initializeCompanyInfo();
    _loadLinkedEmployees();
  }

  Future<void> _initializeCompanyInfo() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Usuário não autenticado');

      final prefs = await SharedPreferences.getInstance();
      final storedCompanyId = prefs.getString('companyId');
      final storedCompanyName = prefs.getString('companyName');

      if (storedCompanyId != null && storedCompanyName != null) {
        _companyId = storedCompanyId;
        _companyName = storedCompanyName;
      } else {
              debugPrint('🔍 SharedPreferences vazios. Buscando empresa para o usuário UID: ${user.uid}');
              var query = await FirebaseFirestore.instance
            .collection('companies')
            .where('ownerUid', isEqualTo: user.uid)
            .limit(1)
            .get();

              // Fallback: Tenta buscar usando 'userId' caso o campo não seja 'ownerUid'
              if (query.docs.isEmpty) {
                debugPrint('⚠️ Campo ownerUid não encontrado. Tentando buscar usando userId...');
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
                debugPrint('✅ Empresa encontrada: $_companyName (ID do Documento: $_companyId)');
          await prefs.setString('companyId', _companyId!);
          if (_companyName != null) {
            await prefs.setString('companyName', _companyName!);
          }
              } else {
                debugPrint('❌ Erro: Nenhuma empresa encontrada no Firestore vinculada a este UID!');
        }
      }

      // Gerar código simulado da empresa
      _generatedCompanyCode = _generateMockedCompanyCode();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Erro ao inicializar empresa: $e');
      if (mounted) {
        _showSnackBar('Erro ao carregar informações da empresa', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _generateMockedCompanyCode() {
    // Simular código único da empresa: EMP-2026-XYZ
    final random = _companyId?.hashCode.toRadixString(36).substring(0, 3).toUpperCase() ?? 'ABC';
    return 'EMP-2026-$random';
  }

  Future<void> _loadLinkedEmployees() async {
    try {
      if (_companyId == null) return;

      final employees = await _employeeRepository.getEmployeesByCompanyId(_companyId!);
      _linkedEmployees.clear();
      _linkedEmployees.addAll(employees);

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Erro ao carregar funcionários: $e');
    }
  }

  bool _validateCompanyCode(String inputCode) {
    return inputCode.trim().toUpperCase() == _generatedCompanyCode?.toUpperCase();
  }

  Future<void> _handleFormSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final inputCode = _companyCodeController.text.trim();

    if (!_validateCompanyCode(inputCode)) {
      _showSnackBar(
        'Código da empresa inválido! Digite: $_generatedCompanyCode',
        isError: true,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      if (_companyId == null || _companyName == null) {
        throw Exception('Dados da empresa inválidos');
      }

      final newEmployee = EmployeeModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        role: _roleController.text.trim(),
        email: _emailController.text.trim(),
        companyCode: _generatedCompanyCode!,
        companyId: _companyId!,
        companyName: _companyName!,
        linkedAt: DateTime.now(),
      );

      // Salvar no Firestore através do repositório
      await _employeeRepository.createEmployee(newEmployee);

      // Adicionar à lista com animação
      _linkedEmployees.insert(0, newEmployee);
      _listKey.currentState?.insertItem(0, duration: AppAnimations.normal);

      // Limpar formulário
      _nameController.clear();
      _roleController.clear();
      _emailController.clear();
      _companyCodeController.clear();

      if (mounted) {
        _showSnackBar(
          'Funcionário cadastrado e vinculado com sucesso!',
          isError: false,
        );
      }
    } catch (e) {
      debugPrint('Erro ao cadastrar funcionário: $e');
      if (mounted) {
        _showSnackBar('Erro ao cadastrar funcionário. Tente novamente.', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        backgroundColor: isError ? AppColors.errorColor : AppColors.successColor,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AppSpacing.lg),
      ),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    _showSnackBar('Código copiado para área de transferência!', isError: false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    _emailController.dispose();
    _companyCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primaryBlue),
              )
            : Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.xxl,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildCompanyCodeSection(),
                            const SizedBox(height: AppSpacing.xxxl),
                            _buildFormSection(),
                            const SizedBox(height: AppSpacing.xxxl),
                            _buildLinkedEmployeesHeader(),
                            const SizedBox(height: AppSpacing.md),
                            _buildEmployeesList(),
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

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryBlue, AppColors.lightBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppBorderRadius.xl),
          bottomRight: Radius.circular(AppBorderRadius.xl),
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
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Cadastro e Vínculo',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'de Funcionários',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyCodeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Código da Empresa',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.darkText,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppBorderRadius.lg),
            border: Border.all(color: AppColors.primaryBlue, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                _generatedCompanyCode ?? 'CARREGANDO...',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.info_outline, size: 16, color: AppColors.lightText),
                  const SizedBox(width: AppSpacing.md),
                  const Flexible(
                    child: Text(
                      'Compartilhe este código com os funcionários',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.lightText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _copyToClipboard(_generatedCompanyCode ?? '');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppBorderRadius.md),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  ),
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copiar Código'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dados do Funcionário',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextFormField(
                controller: _nameController,
                label: 'Nome Completo',
                hint: 'Digite o nome completo',
                icon: Icons.person,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Nome é obrigatório';
                  if ((value?.length ?? 0) < 3) return 'Nome muito curto';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              _buildTextFormField(
                controller: _roleController,
                label: 'Cargo',
                hint: 'Ex: Gerente, Desenvolvedor',
                icon: Icons.work,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Cargo é obrigatório';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              _buildTextFormField(
                controller: _emailController,
                label: 'E-mail',
                hint: 'funcionario@empresa.com',
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'E-mail é obrigatório';
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value!)) {
                    return 'E-mail inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              _buildTextFormField(
                controller: _companyCodeController,
                label: 'Código da Empresa',
                hint: _generatedCompanyCode ?? 'EMP-2026-XXX',
                icon: Icons.lock,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Código da empresa é obrigatório';
                  return null;
                },
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleFormSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.primaryBlue.withValues(alpha: 0.6),
                    disabledForegroundColor: Colors.white70,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Cadastrar e Vincular',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.primaryBlue),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.errorColor, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.errorColor, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildLinkedEmployeesHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Funcionários Vinculados',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${_linkedEmployees.length} funcionário${_linkedEmployees.length != 1 ? 's' : ''}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${_linkedEmployees.length}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlue,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmployeesList() {
    if (_linkedEmployees.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(
              Icons.people_outline,
              size: 48,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 12),
            Text(
              'Nenhum funcionário vinculado',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Preencha o formulário e cadastre um funcionário',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      );
    }

    return AnimatedList(
      key: _listKey,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      initialItemCount: _linkedEmployees.length,
      itemBuilder: (context, index, animation) {
        return SlideTransition(
          position: animation.drive(
            Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero),
          ),
          child: FadeTransition(
            opacity: animation,
            child: _buildEmployeeCard(_linkedEmployees[index]),
          ),
        );
      },
    );
  }

  Widget _buildEmployeeCard(EmployeeModel employee) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employee.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        employee.role,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.successColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.successColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, size: 14, color: AppColors.successColor),
                      const SizedBox(width: 4),
                      const Text(
                        'Vinculado',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.successColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEmployeeInfoRow(Icons.email, 'E-mail', employee.email),
                  const SizedBox(height: 8),
                  _buildEmployeeInfoRow(Icons.lock, 'Código', employee.companyCode),
                  const SizedBox(height: 8),
                  _buildEmployeeInfoRow(
                    Icons.calendar_today,
                    'Vinculado em',
                    _formatDate(employee.linkedAt),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
