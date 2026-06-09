import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignupPageFuncionario extends StatefulWidget {
  const SignupPageFuncionario({super.key});

  @override
  State<SignupPageFuncionario> createState() => _SignupPageFuncionarioState();
}

class _SignupPageFuncionarioState extends State<SignupPageFuncionario> {
  final _dCodeController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _dCodeController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _registerFuncionario() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (context) => const AlertDialog(
          title: Text('Erro'),
          content: Text('Preencha todos os campos para continuar.'),
        ),
      );
      return;
    }

    if (password != confirmPassword) {
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (context) => const AlertDialog(
          title: Text('Erro'),
          content: Text('As senhas não coincidem.'),
        ),
      );
      return;
    }

    if (password.length < 6) {
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (context) => const AlertDialog(
          title: Text('Erro'),
          content: Text('A senha deve ter pelo menos 6 caracteres.'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final dCode = _dCodeController.text.trim();
    if (dCode.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (context) => const AlertDialog(
          title: Text('Erro'),
          content: Text('Digite o D-CODE da empresa para continuar.'),
        ),
      );
      return;
    }

    final inviteSnapshot = await FirebaseFirestore.instance
        .collection('employeeInviteCodes')
        .where('code', isEqualTo: dCode)
        .limit(1)
        .get();

    if (inviteSnapshot.docs.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (context) => const AlertDialog(
          title: Text('Erro'),
          content: Text('D-CODE inválido. Peça o código ao seu gestor.'),
        ),
      );
      return;
    }

    final inviteData = inviteSnapshot.docs.first.data();
    final companyId = inviteData['companyId'] as String?;
    final companyName = inviteData['companyName'] as String?;
    if (companyId == null || companyName == null) {
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (context) => const AlertDialog(
          title: Text('Erro'),
          content: Text('D-CODE inválido. Empresa não encontrada.'),
        ),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = FirebaseAuth.instance.currentUser;
      await user?.updateDisplayName(name);
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': name,
          'email': email,
          'role': 'employee',
          'companyId': companyId,
          'companyName': companyName,
          'inviteCode': dCode,
          'createdAt': Timestamp.now(),
        });
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('companyName', companyName);
      await prefs.setString('companyId', companyId);
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cadastro concluído'),
          content: const Text(
            'Cadastro feito com sucesso! Faça login para continuar.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      final message = switch (e.code) {
        'email-already-in-use' => 'Este e-mail já está em uso.',
        'invalid-email' => 'E-mail inválido.',
        'weak-password' => 'Senha muito fraca.',
        _ => 'Erro ao cadastrar. Tente novamente.',
      };
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Erro'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF0061BC);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF005EB8), Color(0xFF2196F3)],
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
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Cadastro',
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    "Cadastro de Funcionário",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Peça o D-CODE ao seu gestor",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildTextField(
                    "D-CODE DA EMPRESA",
                    _dCodeController,
                    "Ex: DC-1234",
                  ),
                  _buildTextField(
                    "SEU NOME COMPLETO",
                    _nameController,
                    "Ex: João Silva",
                  ),
                  _buildTextField(
                    "E-MAIL ACADÊMICO/PESSOAL",
                    _emailController,
                    "joao@email.com",
                  ),
                  _buildTextField(
                    "CRIAR SENHA",
                    _passwordController,
                    "******",
                    obscure: true,
                  ),
                  _buildTextField(
                    "CONFIRMAR SENHA",
                    _confirmPasswordController,
                    "******",
                    obscure: true,
                  ),

                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _registerFuncionario,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Finalizar Cadastro",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    String hint, {
    bool obscure = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 5),
          TextField(
            controller: controller,
            obscureText: obscure,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
              filled: true,
              fillColor: const Color(0xFFF2F2F2),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
