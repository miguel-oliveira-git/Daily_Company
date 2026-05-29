import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daily_company/data/models/task_model.dart';
import 'package:daily_company/data/repositories/task_repository.dart';
import 'task_detail_page.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _selectedDate = DateTime.now();
  String? _companyId;
  String? _currentUserUid;
  String? _userEmployeeId;
  final TaskRepository _taskRepository = TaskRepository();

  @override
  void initState() {
    super.initState();
    _loadCompanyId();
  }

  Future<void> _loadCompanyId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _companyId = prefs.getString('companyId');
      _currentUserUid = FirebaseAuth.instance.currentUser?.uid;
      _userEmployeeId = prefs.getString('employeeId') ?? prefs.getString('companyCode');
    });
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
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
            // Cabeçalho
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
                    'Calendário de Tarefas',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            
            // Calendário Visual
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: primaryBlue,
                    onPrimary: Colors.white,
                    onSurface: Colors.black87,
                  ),
                ),
                child: CalendarDatePicker(
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                  onDateChanged: (date) {
                    setState(() {
                      _selectedDate = date;
                    });
                  },
                ),
              ),
            ),
            
            // Lista de Tarefas do Dia Selecionado
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
                        // Filtra para exibir apenas as tarefas do dia clicado
                        final dailyTasks = allTasks.where((t) {
                          final isSameDay = _isSameDay(t.date, _selectedDate);
                          final isAuthorized = t.creatorId == _currentUserUid || 
                                               t.assignedEmployeeId == _currentUserUid || 
                                               (_userEmployeeId != null && t.assignedEmployeeId == _userEmployeeId);
                          return isSameDay && isAuthorized;
                        }).toList();
                        
                        if (dailyTasks.isEmpty) {
                          return Center(
                            child: Text(
                              'Nenhuma tarefa para ${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}.',
                              style: const TextStyle(color: Colors.black54, fontSize: 16),
                            ),
                          );
                        }
                        
                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: dailyTasks.length,
                          itemBuilder: (context, index) {
                            final task = dailyTasks[index];
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
                                  child: const Icon(Icons.access_time, color: primaryBlue),
                                ),
                                title: Text(task.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text('Para: ${task.assignedEmployeeName}', style: const TextStyle(color: primaryBlue, fontWeight: FontWeight.w500)),
                                    const SizedBox(height: 2),
                                    Text('Horário: ${task.time}'),
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
    );
  }
}