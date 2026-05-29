import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'employee_list_page.dart';
import 'tasks_page.dart';
import 'calendar_page.dart';
import 'teams_page.dart';

class MenuPage extends StatefulWidget {
  final String? userName;
  final String? companyName;

  const MenuPage({super.key, this.userName, this.companyName});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  bool _isOwner = false;
  bool _isLoadingRole = true;
  String? _fetchedUserName;
  String? _fetchedCompanyName;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoadingRole = false);
      return;
    }

    try {
          // 1. Tenta carregar do cache do celular (rápido)
          final prefs = await SharedPreferences.getInstance();
          if (mounted) {
            setState(() {
              _fetchedCompanyName = prefs.getString('companyName');
            });
          }

          // 2. Busca na coleção users
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final role = data['role'];

        if (role == 'owner') {
          String? fetchedCompany = data['companyName'];
          String? fetchedName = data['name'];

          // 3. Fallback: Se for dono e a empresa não estiver salva em "users" (contas antigas)
          if (fetchedCompany == null || fetchedCompany.trim().isEmpty) {
            var compQuery = await FirebaseFirestore.instance
                .collection('companies')
                .where('ownerUid', isEqualTo: user.uid)
                .limit(1)
                .get();

            if (compQuery.docs.isEmpty) {
              compQuery = await FirebaseFirestore.instance
                  .collection('companies')
                  .where('userId', isEqualTo: user.uid)
                  .limit(1)
                  .get();
            }

            if (compQuery.docs.isNotEmpty) {
              fetchedCompany = compQuery.docs.first.data()['name'] ?? compQuery.docs.first.data()['companyName'];
              await prefs.setString('companyId', compQuery.docs.first.id);
            }
          }

          // Atualiza o cache do celular para curar a persistência local
          if (fetchedCompany != null && fetchedCompany.isNotEmpty) {
            await prefs.setString('companyName', fetchedCompany);
          }

          if (mounted) {
            setState(() {
              _isOwner = true;
              if (fetchedCompany != null && fetchedCompany.isNotEmpty) {
                _fetchedCompanyName = fetchedCompany;
              }
              if (fetchedName != null && fetchedName.isNotEmpty) {
                _fetchedUserName = fetchedName;
              }
              _isLoadingRole = false;
            });
          }
          return;
        }
      }

      // 4. Se for funcionário (não é owner), a empresa é definida APENAS pelo E-mail,
      // corrigindo o conflito de usuários com o mesmo nome em empresas diferentes.
      if (user.email != null) {
        final empQuery = await FirebaseFirestore.instance
            .collection('employees')
            .where('email', isEqualTo: user.email)
            .limit(1)
            .get();

        if (empQuery.docs.isNotEmpty) {
          final empData = empQuery.docs.first.data();
          final companyId = empData['companyId'] ?? '';
          final companyName = empData['companyName'] ?? '';
          final employeeId = empData['id'] ?? empQuery.docs.first.id;
          final employeeName = empData['name'] ?? '';

          // Atualiza o cache local com a empresa e ID reais do funcionário baseados no E-MAIL
          await prefs.setString('companyId', companyId);
          await prefs.setString('companyName', companyName);
          await prefs.setString('employeeId', employeeId);

          if (mounted) {
            setState(() {
              _isOwner = false;
              if (companyName.isNotEmpty) _fetchedCompanyName = companyName;
              if (employeeName.isNotEmpty) _fetchedUserName = employeeName;
              _isLoadingRole = false;
            });
          }
          return;
        }
      }

      if (mounted) setState(() => _isLoadingRole = false);
    } catch (e) {
          debugPrint('Erro ao carregar os dados: $e');
      if (mounted) setState(() => _isLoadingRole = false);
    }
  }

  String _getUserName(User? user) {
    if (widget.userName != null && widget.userName!.trim().isNotEmpty) {
      return widget.userName!;
    }
    if (_fetchedUserName != null && _fetchedUserName!.trim().isNotEmpty) {
      return _fetchedUserName!;
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
    if (widget.companyName != null && widget.companyName!.trim().isNotEmpty) {
      return widget.companyName!;
    }
    if (_fetchedCompanyName != null && _fetchedCompanyName!.trim().isNotEmpty) {
      return _fetchedCompanyName!;
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
                    children: [
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.menu, color: Colors.white, size: 28),
                        offset: const Offset(0, 40),
                        onSelected: (value) async {
                          if (value == 'logout') {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Sair da conta'),
                                content: const Text('Tem certeza que deseja sair?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                                    child: const Text('Sair', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              await FirebaseAuth.instance.signOut();
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.clear(); // Limpa o cache da sessão
                              if (mounted) {
                                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                              }
                            }
                          }
                        },
                        itemBuilder: (BuildContext context) => [
                          const PopupMenuItem(
                            value: 'logout',
                            child: Row(
                              children: [
                                Icon(Icons.logout, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Sair da conta', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Icon(Icons.notifications, color: Colors.white, size: 28),
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
                child: _isLoadingRole
                    ? const Center(
                        child: CircularProgressIndicator(color: primaryBlue),
                      )
                    : GridView.count(
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.95,
                  children: [
                    _MenuCard(
                      icon: Icons.calendar_month,
                      label: 'Calendário',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const CalendarPage()),
                        );
                      },
                    ),
                    _MenuCard(
                      icon: Icons.task_alt,
                      label: 'Tarefas',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const TasksPage()),
                        );
                      },
                    ),
                    if (_isOwner)
                      _MenuCard(
                        icon: Icons.group,
                        label: 'Funcionários',
                        onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const EmployeeListPage()),
                        ),
                      ),
                    if (_isOwner)
                      _MenuCard(
                        icon: Icons.groups,
                        label: 'Equipes',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const TeamsPage()),
                          );
                        },
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
