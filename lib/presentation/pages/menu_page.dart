import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'employees_page.dart';

class MenuPage extends StatelessWidget {
  final String? userName;
  final String? companyName;

  const MenuPage({super.key, this.userName, this.companyName});

  String _getUserName(User? user) {
    if (userName != null && userName!.trim().isNotEmpty) {
      return userName!;
    }
    if (user?.displayName != null && user!.displayName!.trim().isNotEmpty) {
      return user.displayName!;
    }
    if (user?.email != null && user!.email!.contains('@')) {
      return user.email!.split('@').first;
    }
    return 'Usuário';
  }

  String _getCompanyName() {
    if (companyName != null && companyName!.trim().isNotEmpty) {
      return companyName!;
    }
    return 'Minha Empresa';
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF005EB8);
    const Color lightBlue = Color(0xFF2196F3);
    final user = FirebaseAuth.instance.currentUser;
    final displayName = _getUserName(user);
    final displayCompany = _getCompanyName();

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
                    children: const [
                      Icon(Icons.menu, color: Colors.white, size: 28),
                      Icon(Icons.notifications, color: Colors.white, size: 28),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    displayCompany,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.search, color: Color(0xFF71879C)),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Pesquisar',
                            style: TextStyle(
                              color: Color(0xFF71879C),
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.95,
                  children: [
                    const _MenuCard(icon: Icons.calendar_month, label: 'Calendário'),
                    const _MenuCard(icon: Icons.task_alt, label: 'Tarefas'),
                    _MenuCard(
                      icon: Icons.group,
                      label: 'Funcionários',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const EmployeesPage()),
                      ),
                    ),
                    const _MenuCard(icon: Icons.groups, label: 'Equipes'),
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

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _MenuCard({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF005EB8);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap ?? () {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('$label selecionado')));
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: primaryBlue),
              const SizedBox(height: 16),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
