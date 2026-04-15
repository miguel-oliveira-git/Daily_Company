import 'package:flutter/material.dart';
import 'init_page.dart'; 

class LoginPageFuncionario extends StatefulWidget {
  const LoginPageFuncionario({super.key});

  @override
  State<LoginPageFuncionario> createState() => _LoginPageFuncionarioState();
}

class _LoginPageFuncionarioState extends State<LoginPageFuncionario> {
  final TextEditingController _dCodeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _showErrorMessage = false;

  void _handleLogin() {
    setState(() {
      if (_dCodeController.text.isEmpty || _passwordController.text != "123") {
        _showErrorMessage = true;
      } else {
        _showErrorMessage = false;
        print("Login Funcionário Sucesso!");
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
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
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
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Icon(Icons.person_pin, size: 90, color: primaryBlue),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Olá, Funcionário!', 
                      style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25),
                      child: Container(
                        padding: const EdgeInsets.all(25),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Center(child: Text('Faça seu Login', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
                            const Center(child: Text('Entre para continuar', style: TextStyle(color: Colors.grey, fontSize: 14))),
                            const SizedBox(height: 25),
                            const Text("D-CODE < >", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 5),
                            TextField(
                              controller: _dCodeController,
                              decoration: InputDecoration(
                                fillColor: lightGrey,
                                filled: true,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                              ),
                            ),
                            const SizedBox(height: 15),
                            const Text("SENHA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 5),
                            TextField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                suffixIcon: const Icon(Icons.lock_outline, color: Colors.black),
                                fillColor: lightGrey,
                                filled: true,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                              ),
                            ),
                            if (_showErrorMessage)
                              const Padding(
                                padding: EdgeInsets.only(top: 10),
                                child: Center(
                                  child: Text("* Identificação ou senha incorreta *",
                                    style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
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
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: const Text("CONTINUAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            Center(
                              child: TextButton(
                                onPressed: () {},
                                child: const Text("Esqueceu a senha?", style: TextStyle(color: primaryBlue, decoration: TextDecoration.underline)),
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