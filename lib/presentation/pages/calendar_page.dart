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
  DateTime _displayMonth = DateTime(DateTime.now().year, DateTime.now().month);
  String? _companyId;
  String? _currentUserUid;
  String? _currentUserEmail;
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
      _currentUserEmail = FirebaseAuth.instance.currentUser?.email;
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
            
            // Corpo (Calendário e Lista) dependentes do Stream
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
                        // Filtra para exibir apenas as tarefas autorizadas
                        final authorizedTasks = allTasks.where((t) {
                          return t.creatorId == _currentUserUid || 
                                 t.assignedEmployeeId == _currentUserUid || 
                                 (_userEmployeeId != null && t.assignedEmployeeId == _userEmployeeId) ||
                                 (_currentUserEmail != null && (t.assignedEmployeeId == _currentUserEmail || t.assignedEmployeeName == _currentUserEmail));
                        }).toList();
                        
                        // Tarefas específicas do dia selecionado
                        final dailyTasks = authorizedTasks.where((t) => _isSameDay(t.date, _selectedDate)).toList();
                        
                        return Column(
                          children: [
                            // Calendário Customizado com as bolinhas (Eventos)
                            Container(
                              margin: const EdgeInsets.all(16),
                              padding: const EdgeInsets.only(top: 16, bottom: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                                ],
                              ),
                              child: _buildCustomCalendar(authorizedTasks),
                            ),
                            
                            // Lista de Tarefas do Dia
                            Expanded(
                              child: dailyTasks.isEmpty
                                  ? Center(
                                      child: Text(
                                        'Nenhuma tarefa para ${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}.',
                                        style: const TextStyle(color: Colors.black54, fontSize: 16),
                                      ),
                                    )
                                  : ListView.builder(
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
                                    ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomCalendar(List<TaskModel> tasks) {
    const List<String> monthNames = ['Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho', 'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'];
    final String currentMonthName = monthNames[_displayMonth.month - 1];

    int daysInMonth = DateTime(_displayMonth.year, _displayMonth.month + 1, 0).day;
    int firstWeekday = DateTime(_displayMonth.year, _displayMonth.month, 1).weekday; // 1 = Seg, 7 = Dom
    int emptySlotsBefore = firstWeekday == 7 ? 0 : firstWeekday; 
    int totalCells = emptySlotsBefore + daysInMonth;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Color(0xFF005EB8)),
                onPressed: () {
                  setState(() {
                    _displayMonth = DateTime(_displayMonth.year, _displayMonth.month - 1);
                  });
                },
              ),
              Text(
                '$currentMonthName ${_displayMonth.year}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF005EB8)),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Color(0xFF005EB8)),
                onPressed: () {
                  setState(() {
                    _displayMonth = DateTime(_displayMonth.year, _displayMonth.month + 1);
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'].map((day) {
            return Expanded(
              child: Center(
                child: Text(day, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1.0,
          ),
          itemCount: totalCells,
          itemBuilder: (context, index) {
            if (index < emptySlotsBefore) return const SizedBox();

            int day = index - emptySlotsBefore + 1;
            DateTime cellDate = DateTime(_displayMonth.year, _displayMonth.month, day);
            bool isSelected = _isSameDay(cellDate, _selectedDate);
            bool isToday = _isSameDay(cellDate, DateTime.now());
            bool hasTask = tasks.any((t) => _isSameDay(t.date, cellDate));

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedDate = cellDate;
                });
              },
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF005EB8) : Colors.transparent,
                  shape: BoxShape.circle,
                  border: isToday && !isSelected ? Border.all(color: const Color(0xFF005EB8).withValues(alpha: 0.5)) : null,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      '$day',
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    if (hasTask)
                      Positioned(
                        bottom: 6,
                        child: Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}