import 'package:flutter/material.dart';
import 'init_page.dart';

class LoginPageEmpreendedor extends StatefulWidget {
  const LoginPageEmpreendedor({super.key});

  @override
  State<LoginPageEmpreendedor> createState() => _LoginPageEmpreendedorState();
}

class _LoginPageEmpreendedorState extends State<LoginPageEmpreendedor> {
  final TextEditingController emailEmpresa = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isErrorVisible = false;

  void _handleLogin() {
    setState(() {
      if (emailEmpresa.text.isEmpty || _passwordController.text != "admin") {
        _isErrorVisible = true;
      } else {
        _isErrorVisible = false;
        print("Login feito com Sucesso!");
      }
    });
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
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  constraints: const BoxConstraints(), 
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
                        child: Icon(Icons.business, size: 90, color: primaryBlue),
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
                                style: TextStyle(color: Colors.grey, fontSize: 14),
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
                                suffixIcon: const Icon(Icons.lock_outline, color: Colors.black),
                                fillColor: lightGrey,
                                filled: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                            if (_isErrorVisible)
                              const Padding(
                                padding: EdgeInsets.only(top: 10),
                                child: Center(
                                  child: Text(
                                    "Usuário ou senha incorretos",
                                    style: TextStyle(
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
                                onPressed: _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryBlue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  "Conectar",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
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