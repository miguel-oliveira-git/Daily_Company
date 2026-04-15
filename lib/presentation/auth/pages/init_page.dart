import 'package:flutter/material.dart';
import 'login_page_funcionario.dart'; 
import 'login_page_empreendedor.dart';

class InitPage extends StatelessWidget {
  const InitPage({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF005EB8);

    return Scaffold(
      backgroundColor: primaryBlue,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'lib/assets/daily_company.png',
                  height: 120,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.account_circle, size: 100, color: Colors.white);
                  },
                ),
                const SizedBox(height: 10),
                const Text(
                  'DAILY\nCOMPANY',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Bem Vindo ao\nDaily Company!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D2D2D),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Sua empresa em um único App',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 35),
                        _buildActionButton(
                          label: 'Sou Funcionário!',
                          color: primaryBlue,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginPageFuncionario()),
                            );
                          },
                        ),
                        const SizedBox(height: 15),
                        _buildActionButton(
                          label: 'Sou Empreendedor!',
                          color: primaryBlue,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginPageEmpreendedor()),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Não tem uma conta? ",
                              style: TextStyle(color: Colors.black54),
                            ),
                            TextButton(
                              onPressed: () {
                                print("Ir para Cadastro");
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 0),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                Column(
                  children: [
                    const Text(
                      'Termos de Uso',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 50),
                      child: Row(
                        children: [
                          Expanded(child: Container(height: 1, color: Colors.white54)),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Icon(Icons.diamond, color: Colors.white, size: 12),
                          ),
                          Expanded(child: Container(height: 1, color: Colors.white54)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}