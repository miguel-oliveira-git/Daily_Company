import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'employee_list_page.dart';
import 'tasks_page.dart';
import 'calendar_page.dart';
import 'teams_page.dart';
import 'task_detail_page.dart';

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
  String? _companyId;
  String? _currentUserUid;
  String? _currentUserEmail;
  String? _userEmployeeId;
  Stream<QuerySnapshot>? _notificationsStream;
  List<String> _readNotifications = [];

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

    _currentUserUid = user.uid;
    _currentUserEmail = user.email;

    try {
          // 1. Tenta carregar do cache do celular (rápido)
          final prefs = await SharedPreferences.getInstance();
          _userEmployeeId = prefs.getString('employeeId') ?? prefs.getString('companyCode');
          _readNotifications = prefs.getStringList('readNotifications') ?? [];
          if (mounted) {
            setState(() {
              _fetchedCompanyName = prefs.getString('companyName');
              _companyId = prefs.getString('companyId');
            });
            _setupNotificationsStream();
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
              _companyId = compQuery.docs.first.id;
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
              _setupNotificationsStream();
              _isLoadingRole = false;
            });
          }
          return;
        }
      }

      // 4. Se for funcionário (não é owner), a empresa é definida APENAS pelo E-mail,
      // corrigindo o conflito de usuários com o mesmo nome em empresas diferentes.
      if (user.email != null) {
        var empQuery = await FirebaseFirestore.instance
            .collection('employees')
            .where('email', isEqualTo: user.email)
            .limit(1)
            .get();

        // Fallback: Se o email estiver como "Aguardando 1º acesso...", buscamos no employeeInviteCodes
        if (empQuery.docs.isEmpty) {
          final inviteQuery = await FirebaseFirestore.instance
              .collection('employeeInviteCodes')
              .where('employeeEmail', isEqualTo: user.email)
              .limit(1)
              .get();

          if (inviteQuery.docs.isNotEmpty) {
            final employeeId = inviteQuery.docs.first.id;
            
            // Atualiza o funcionário para vincular o e-mail real dele no banco
            await FirebaseFirestore.instance.collection('employees').doc(employeeId).update({
              'email': user.email,
            });
            
            empQuery = await FirebaseFirestore.instance
                .collection('employees')
                .where('email', isEqualTo: user.email)
                .limit(1)
                .get();
          }
        }

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
          _userEmployeeId = employeeId;

          if (mounted) {
            setState(() {
              _isOwner = false;
              if (companyName.isNotEmpty) _fetchedCompanyName = companyName;
              if (employeeName.isNotEmpty) _fetchedUserName = employeeName;
              _companyId = companyId;
              _setupNotificationsStream();
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

  void _setupNotificationsStream() {
    if (_companyId != null && _companyId!.isNotEmpty) {
      _notificationsStream = FirebaseFirestore.instance
          .collection('tasks')
          .where('companyId', isEqualTo: _companyId)
          .snapshots();
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
                      _buildNotificationIcon(),
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
                  GestureDetector(
                    onTap: () {
                      showSearch(
                        context: context,
                        delegate: _MenuSearchDelegate(
                          companyId: _companyId,
                          isOwner: _isOwner,
                        ),
                      );
                    },
                    child: Container(
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
                              'Pesquisar...',
                              style: TextStyle(
                                color: Color(0xFF71879C),
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildNotificationIcon() {
    if (_notificationsStream == null) {
      return IconButton(
        icon: const Icon(Icons.notifications, color: Colors.white, size: 28),
        onPressed: () => _showNotificationsPanel([]),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _notificationsStream,
      builder: (context, snapshot) {
        int newCount = 0;
        List<QueryDocumentSnapshot> docs = [];
        
        if (snapshot.hasData) {
          final allDocs = snapshot.data!.docs;
          
          docs = allDocs.where((doc) {
            if (_isOwner) return true; // Dono vê todas as notificações
            
            final data = doc.data() as Map<String, dynamic>;
            final assignedId = data['assignedEmployeeId'];
            final assignedName = data['assignedEmployeeName'];
            
            // Funcionário vê apenas as tarefas atribuídas a ele
            return assignedId == _currentUserUid || 
                   assignedId == _userEmployeeId || 
                   assignedId == _currentUserEmail || 
                   assignedName == _currentUserEmail;
          }).toList();

          final now = DateTime.now();
          newCount = docs.where((doc) {
            if (_readNotifications.contains(doc.id)) return false; // Ignora se já foi clicada
            
            final data = doc.data() as Map<String, dynamic>;
            final time = data['updatedAt'] as Timestamp? ?? data['createdAt'] as Timestamp?;
            if (time == null) return false;
            // Considera como nova notificação (badge vermelho) tarefas criadas/atualizadas nas últimas 24h
            return now.difference(time.toDate()).inHours < 24;
          }).length;
        }

        return Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications, color: Colors.white, size: 28),
              onPressed: () => _showNotificationsPanel(docs),
            ),
            if (newCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    newCount > 9 ? '9+' : newCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showNotificationsPanel(List<QueryDocumentSnapshot> docs) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        // Ordena para mostrar as mais recentes primeiro localmente (evita a necessidade de index composto no Firestore)
        final sortedDocs = docs.toList();
        sortedDocs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTime = aData['updatedAt'] as Timestamp? ?? aData['createdAt'] as Timestamp?;
          final bTime = bData['updatedAt'] as Timestamp? ?? bData['createdAt'] as Timestamp?;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });
        
        final topDocs = sortedDocs.take(15).toList(); // Mostra até as 15 mais recentes

        return Container(
          height: MediaQuery.of(context).size.height * 0.6, // Ocupa 60% da tela de baixo para cima
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Notificações Recentes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1),
              if (topDocs.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      'Nenhuma tarefa ou notificação recente',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: topDocs.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final doc = topDocs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final title = data['title'] ?? 'Tarefa sem título';
                      final desc = data['description'] ?? 'Nenhuma descrição';
                      final time = data['updatedAt'] as Timestamp? ?? data['createdAt'] as Timestamp?;
                      
                      String timeText = '';
                      if (time != null) {
                        final diff = DateTime.now().difference(time.toDate());
                        if (diff.inMinutes < 1) {
                          timeText = 'Agora';
                        } else if (diff.inMinutes < 60) {
                          timeText = '${diff.inMinutes}m atrás';
                        } else if (diff.inHours < 24) {
                          timeText = '${diff.inHours}h atrás';
                        } else {
                          timeText = '${diff.inDays}d atrás';
                        }
                      }

                      final isRead = _readNotifications.contains(doc.id);

                      return ListTile(
                        leading: Stack(
                          children: [
                            const CircleAvatar(
                              backgroundColor: Color(0xFFE0EAFC),
                              child: Icon(Icons.task_alt, color: Color(0xFF005EB8)),
                            ),
                            if (!isRead)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        title: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          desc,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text(
                          timeText,
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        onTap: () {
                          Navigator.pop(context); // Fecha o painel modal
                          
                          if (!_readNotifications.contains(doc.id)) {
                            setState(() {
                              _readNotifications.add(doc.id);
                            });
                            SharedPreferences.getInstance().then((prefs) {
                              prefs.setStringList('readNotifications', _readNotifications);
                            });
                          }
                          
                          // Empilha a área de tarefas e depois a tarefa detalhada
                          // para manter o fluxo natural de navegação do app.
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const TasksPage()),
                          );
                          
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => TaskDetailPage(
                                taskId: doc.id,
                                initialTitle: title,
                                initialDescription: desc,
                                initialReferenceLink: data['referenceLink'] ?? '',
                                initialStatus: data['status'] ?? 'espera',
                                creatorId: data['creatorId'] ?? '',
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _MenuSearchDelegate extends SearchDelegate<String> {
  final String? companyId;
  final bool isOwner;

  _MenuSearchDelegate({required this.companyId, required this.isOwner})
      : super(searchFieldLabel: 'Pesquisar...');

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildSearchResults(context);

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return const Center(
        child: Text(
          'Pesquise por funcionários, equipes ou áreas.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    final normalizedQuery = query.toLowerCase().trim();

    final List<Map<String, dynamic>> systemAreas = [
      {'title': 'Calendário', 'icon': Icons.calendar_month, 'page': const CalendarPage()},
      {'title': 'Tarefas', 'icon': Icons.task_alt, 'page': const TasksPage()},
      if (isOwner) {'title': 'Funcionários', 'icon': Icons.group, 'page': const EmployeeListPage()},
      if (isOwner) {'title': 'Equipes', 'icon': Icons.groups, 'page': const TeamsPage()},
    ];

    final matchedAreas = systemAreas
        .where((area) => (area['title'] as String).toLowerCase().contains(normalizedQuery))
        .toList();

    if (companyId == null) {
      return _buildList(context, matchedAreas, [], []);
    }

    return FutureBuilder(
      future: Future.wait([
        FirebaseFirestore.instance.collection('employees').where('companyId', isEqualTo: companyId).get(),
        FirebaseFirestore.instance.collection('teams').where('companyId', isEqualTo: companyId).get(),
      ]),
      builder: (context, AsyncSnapshot<List<QuerySnapshot>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF005EB8)));
        }
        if (!snapshot.hasData || snapshot.hasError) {
          return _buildList(context, matchedAreas, [], []);
        }

        final employees = snapshot.data![0].docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = (data['name'] ?? '').toString().toLowerCase();
          final email = (data['email'] ?? '').toString().toLowerCase();
          final role = (data['role'] ?? '').toString().toLowerCase();
          return name.contains(normalizedQuery) || email.contains(normalizedQuery) || role.contains(normalizedQuery);
        }).toList();

        final teams = snapshot.data![1].docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = (data['name'] ?? data['title'] ?? '').toString().toLowerCase();
          return name.contains(normalizedQuery);
        }).toList();

        return _buildList(context, matchedAreas, employees, teams);
      },
    );
  }

  Widget _buildList(
    BuildContext context,
    List<Map<String, dynamic>> areas,
    List<QueryDocumentSnapshot> employees,
    List<QueryDocumentSnapshot> teams,
  ) {
    if (areas.isEmpty && employees.isEmpty && teams.isEmpty) {
      return const Center(
        child: Text('Nenhum resultado encontrado.', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView(
      children: [
        if (areas.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('ÁREAS DO SISTEMA', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
          ),
          ...areas.map((area) => ListTile(
                leading: CircleAvatar(backgroundColor: const Color(0xFFE0EAFC), child: Icon(area['icon'] as IconData, color: const Color(0xFF005EB8))),
                title: Text(area['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  close(context, '');
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => area['page'] as Widget));
                },
              )),
        ],
        if (employees.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('FUNCIONÁRIOS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
          ),
          ...employees.map((emp) {
            final data = emp.data() as Map<String, dynamic>;
            return ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFFE0EAFC), child: Icon(Icons.person, color: Color(0xFF005EB8))),
              title: Text(data['name'] ?? 'Sem nome', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${data['role'] ?? 'Cargo não definido'} • ${data['email'] ?? 'Sem e-mail'}'),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text(data['name'] ?? 'Funcionário'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Cargo: ${data['role'] ?? 'Não informado'}'),
                        const SizedBox(height: 8),
                        Text('E-mail: ${data['email'] ?? 'Não informado'}'),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Fechar', style: TextStyle(color: Color(0xFF005EB8))),
                      ),
                    ],
                  ),
                );
              },
            );
          }),
        ],
        if (teams.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('EQUIPES', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
          ),
          ...teams.map((team) {
            final data = team.data() as Map<String, dynamic>;
            return ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFFE0EAFC), child: Icon(Icons.groups, color: Color(0xFF005EB8))),
              title: Text(data['name'] ?? data['title'] ?? 'Equipe', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Visualizar informações da equipe'),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text(data['name'] ?? data['title'] ?? 'Equipe'),
                    content: const Text('As equipes ajudam a organizar os funcionários no sistema.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Fechar', style: TextStyle(color: Color(0xFF005EB8))),
                      ),
                    ],
                  ),
                );
              },
            );
          }),
        ],
      ],
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
