import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _companyController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _companyController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _registerEmpreendedor() async {
    final currentContext = context;
    final company = _companyController.text.trim();
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (company.isEmpty ||
        name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      await showDialog(
        context: currentContext,
        builder: (context) => const AlertDialog(
          title: Text('Erro'),
          content: Text('Preencha todos os campos para continuar.'),
        ),
      );
      return;
    }

    if (password != confirmPassword) {
      await showDialog(
        context: currentContext,
        builder: (context) => const AlertDialog(
          title: Text('Erro'),
          content: Text('As senhas não coincidem.'),
        ),
      );
      return;
    }

    if (password.length < 6) {
      await showDialog(
        context: currentContext,
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

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = FirebaseAuth.instance.currentUser;
      await user?.updateDisplayName(name);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('companyName', company);
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  height: 180,
                  decoration: const BoxDecoration(
                    color: Color(0xFF005EB8),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(80),
                    ),
                  ),
                ),
                Positioned(
                  top: 50,
                  left: 20,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    "Criar uma nova conta",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text("Já é registrado? Entre aqui."),
                  ),
                  const SizedBox(height: 30),
                  _buildTextField(
                    "NOME DA EMPRESA",
                    _companyController,
                    "Ex: Daily Company",
                  ),
                  _buildTextField(
                    "NOME COMPLETO",
                    _nameController,
                    "Ex: João Silva",
                  ),
                  _buildTextField(
                    "EMAIL",
                    _emailController,
                    "Ex: email@empresarial.com",
                  ),
                  _buildTextField(
                    "SENHA",
                    _passwordController,
                    "******",
                    obscure: true,
                  ),
                  _buildTextField(
                    "CONFIRME A SENHA",
                    _confirmPasswordController,
                    "******",
                    obscure: true,
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _registerEmpreendedor,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0061BC),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Cadastre-se",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ],
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
              fontSize: 12,
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
              filled: true,
              fillColor: Colors.grey[300],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
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
