import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daily_company/presentation/pages/menu_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'init_page.dart';
import 'cadastro_empreendedor_page.dart';
import 'recupera_senha.dart';

class LoginPageEmpreendedor extends StatefulWidget {
  const LoginPageEmpreendedor({super.key});

  @override
  State<LoginPageEmpreendedor> createState() => _LoginPageEmpreendedorState();
}

class _LoginPageEmpreendedorState extends State<LoginPageEmpreendedor> {
  final TextEditingController emailEmpresa = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleLogin() async {
    final email = emailEmpresa.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Preencha e-mail e senha';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (!mounted) return;
      final user = credential.user;
      final prefs = await SharedPreferences.getInstance();
      var company = prefs.getString('companyName') ?? 'Minha Empresa';

      if (user != null) {
        final storedCompanyId = prefs.getString('companyId');
        final storedCompanyName = prefs.getString('companyName');
        if (storedCompanyId == null || storedCompanyName == null) {
          _refreshCompanyInfo(user.uid);
        }
      }
      if (!mounted) return;

      final userName = user?.displayName?.trim().isNotEmpty == true
          ? user!.displayName!
          : email.split('@').first;
      _navigateToMenu(context, userName, company);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      debugPrint('Login error code: ${e.code}');
      debugPrint('Login error message: ${e.message}');
      setState(() {
        _errorMessage = switch (e.code) {
          'user-not-found' => 'Usuário não encontrado',
          'wrong-password' => 'Senha incorreta',
          'invalid-email' => 'E-mail inválido',
          'user-disabled' => 'Conta desativada',
          'operation-not-allowed' => 'Login por e-mail e senha não está habilitado.',
          'network-request-failed' => 'Falha de rede. Verifique sua conexão.',
          _ => e.message ?? 'Erro ao fazer login. Tente novamente.',
        };
      });
    } catch (e) {
      if (!mounted) return;
      debugPrint('Login error: $e');
      setState(() {
        _errorMessage = 'Erro ao fazer login. Tente novamente.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToMenu(BuildContext context, String userName, String company) {
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _errorMessage = null;
    });
    messenger.showSnackBar(
      const SnackBar(content: Text('Login realizado com sucesso!')),
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MenuPage(userName: userName, companyName: company),
      ),
    );
  }

  Future<void> _refreshCompanyInfo(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (!userDoc.exists) return;

      final data = userDoc.data();
      if (data == null) return;

      final companyName = data['companyName'] as String?;
      final companyId = data['companyId'] as String?;
      if (companyName == null && companyId == null) return;

      final prefs = await SharedPreferences.getInstance();
      if (companyName != null) {
        await prefs.setString('companyName', companyName);
      }
      if (companyId != null) {
        await prefs.setString('companyId', companyId);
      }
    } catch (e) {
      debugPrint('Background company refresh failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF005EB8);
    const Color lightGrey = Color(0xFFD9D9D9);

    return Scaffold(
      backgroundColor: primaryBlue,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 10,
              left: 10,
              child: IconButton(
                padding: const EdgeInsets.all(15),
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 32,
                ),
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const InitPage()),
                    );
                  }
                },
              ),
            ),
            Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Container(
                      height: 160,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Icon(
                          Icons.business,
                          size: 90,
                          color: primaryBlue,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Olá, Empreendedor!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25),
                      child: Container(
                        padding: const EdgeInsets.all(25),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Center(
                              child: Text(
                                'Gestão da Empresa',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Center(
                              child: Text(
                                'Acesse o seu painel',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(height: 25),
                            const Text(
                              "E-MAIL",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 5),
                            TextField(
                              controller: emailEmpresa,
                              decoration: InputDecoration(
                                fillColor: lightGrey,
                                filled: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                            const SizedBox(height: 15),
                            const Text(
                              "SENHA",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 5),
                            TextField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                suffixIcon: const Icon(
                                  Icons.lock_outline,
                                  color: Colors.black,
                                ),
                                fillColor: lightGrey,
                                filled: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                            if (_errorMessage != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Center(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryBlue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 3,
                                        ),
                                      )
                                    : const Text(
                                        "Conectar",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Center(
                              child: TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ForgotPasswordPage(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  "Esqueceu a senha?",
                                  style: TextStyle(
                                    color: primaryBlue,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "Não tem uma conta? ",
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 13,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const SignupPage(),
                                      ),
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: const Text(
                                    "Cadastre-se aqui",
                                    style: TextStyle(
                                      color: primaryBlue,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
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
