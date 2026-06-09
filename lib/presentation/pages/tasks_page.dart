import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daily_company/data/models/task_model.dart';
import 'package:daily_company/data/repositories/task_repository.dart';
import 'task_assignment_page.dart';
import 'task_detail_page.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  String? _companyId;
  String? _currentUserUid;
  String? _currentUserEmail;
  String? _userEmployeeId;
  bool _isOwner = false;
  int _selectedTabIndex = 0; // 0 = Pendentes, 1 = Concluídas
  final TaskRepository _taskRepository = TaskRepository();

  @override
  void initState() {
    super.initState();
    _loadCompanyId();
  }

  Future<void> _loadCompanyId() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;
    
    bool isOwnerCheck = false;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data()?['role'] == 'owner') {
        isOwnerCheck = true;
      }
    }

    setState(() {
      _companyId = prefs.getString('companyId');
      _currentUserUid = user?.uid;
      _currentUserEmail = user?.email;
      _userEmployeeId = prefs.getString('employeeId') ?? prefs.getString('companyCode');
      _isOwner = isOwnerCheck;
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF005EB8);
    const Color lightBlue = Color(0xFF2196F3);

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
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Gestão de Tarefas',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            if (_isOwner)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => setState(() => _selectedTabIndex = 0),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedTabIndex == 0 ? primaryBlue : Colors.white,
                          foregroundColor: _selectedTabIndex == 0 ? Colors.white : Colors.black54,
                          elevation: _selectedTabIndex == 0 ? 2 : 0,
                          side: BorderSide(color: _selectedTabIndex == 0 ? primaryBlue : Colors.grey.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Pendentes', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => setState(() => _selectedTabIndex = 1),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedTabIndex == 1 ? Colors.green : Colors.white,
                          foregroundColor: _selectedTabIndex == 1 ? Colors.white : Colors.black54,
                          elevation: _selectedTabIndex == 1 ? 2 : 0,
                          side: BorderSide(color: _selectedTabIndex == 1 ? Colors.green : Colors.grey.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Concluídas', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: _companyId == null
                  ? const Center(child: CircularProgressIndicator(color: primaryBlue))
                  : StreamBuilder<List<TaskModel>>(
                      stream: _taskRepository.getTasksStream(_companyId!),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: primaryBlue));
                        }
                        final allTasks = snapshot.data ?? [];
                        final tasks = allTasks.where((task) {
                          final isMyTask = task.creatorId == _currentUserUid ||
                                           task.assignedEmployeeId == _currentUserUid ||
                                           (_userEmployeeId != null && task.assignedEmployeeId == _userEmployeeId) ||
                                           (_currentUserEmail != null && (task.assignedEmployeeId == _currentUserEmail || task.assignedEmployeeName == _currentUserEmail));
                          
                          if (!isMyTask) return false;

                          if (_isOwner) {
                            if (_selectedTabIndex == 0) {
                              return task.status != 'concluida';
                            } else {
                              if (task.status != 'concluida') return false;
                              // Oculta as tarefas que estão concluídas há mais de 7 dias (baseado na data da tarefa)
                              return DateTime.now().difference(task.date).inDays <= 7;
                            }
                          } else {
                            // O funcionário só enxerga tarefas que ainda não estão concluídas
                            return task.status != 'concluida';
                          }
                        }).toList();
                        if (tasks.isEmpty) {
                          String emptyMsg = _isOwner 
                              ? (_selectedTabIndex == 0 ? 'Nenhuma tarefa pendente.' : 'Nenhuma tarefa concluída.') 
                              : 'Você não possui tarefas pendentes no momento.';
                          return Center(
                            child: Text(emptyMsg, style: const TextStyle(color: Colors.black54)),
                          );
                        }
                        return ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: tasks.length,
                          itemBuilder: (context, index) {
                            final task = tasks[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              child: ListTile(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => TaskDetailPage(
                                        taskId: task.id,
                                        initialTitle: task.title,
                                        initialDescription: task.description,
                                        initialReferenceLink: task.referenceLink,
                                        initialStatus: task.status,
                                        creatorId: task.creatorId,
                                      ),
                                    ),
                                  );
                                },
                                leading: CircleAvatar(
                                  backgroundColor: primaryBlue.withValues(alpha: 0.1),
                                  child: const Icon(Icons.assignment, color: primaryBlue),
                                ),
                                title: Text(task.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text('Para: ${task.assignedEmployeeName}', style: const TextStyle(color: primaryBlue, fontWeight: FontWeight.w500)),
                                    const SizedBox(height: 2),
                                    Text('${task.date.day.toString().padLeft(2, '0')}/${task.date.month.toString().padLeft(2, '0')}/${task.date.year} às ${task.time}'),
                                  ],
                                ),
                                isThreeLine: true,
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: _isOwner ? FloatingActionButton.extended(
        onPressed: () {
          if (_companyId != null) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => TaskAssignmentPage(companyId: _companyId!)),
            );
          }
        },
        backgroundColor: primaryBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Atribuir Nova Tarefa', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ) : null,
    );
  }
}