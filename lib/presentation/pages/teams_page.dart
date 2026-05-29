import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daily_company/data/models/team_model.dart';
import 'package:daily_company/data/repositories/team_repository.dart';
import 'create_team_page.dart';
import 'team_detail_page.dart';

class TeamsPage extends StatefulWidget {
  const TeamsPage({super.key});

  @override
  State<TeamsPage> createState() => _TeamsPageState();
}

class _TeamsPageState extends State<TeamsPage> {
  String? _companyId;
  final TeamRepository _teamRepository = TeamRepository();

  @override
  void initState() {
    super.initState();
    _loadCompanyId();
  }

  Future<void> _loadCompanyId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _companyId = prefs.getString('companyId');
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
                  const Text('Gestão de Equipes', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Expanded(
              child: _companyId == null
                  ? const Center(child: CircularProgressIndicator(color: primaryBlue))
                  : StreamBuilder<List<TeamModel>>(
                      stream: _teamRepository.getTeamsStream(_companyId!),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: primaryBlue));
                        }
                        final teams = snapshot.data ?? [];
                        if (teams.isEmpty) {
                          return const Center(
                            child: Text('Nenhuma equipe criada ainda.', style: TextStyle(color: Colors.black54)),
                          );
                        }
                        return ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: teams.length,
                          itemBuilder: (context, index) {
                            final team = teams[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              child: ListTile(
                                onTap: () {
                                  if (_companyId != null) {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => TeamDetailPage(
                                          team: team,
                                          companyId: _companyId!,
                                        ),
                                      ),
                                    );
                                  }
                                },
                                leading: CircleAvatar(
                                  backgroundColor: primaryBlue.withValues(alpha: 0.1),
                                  child: const Icon(Icons.groups, color: primaryBlue),
                                ),
                                title: Text(team.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('${team.employeeIds.length} membros vinculados'),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_companyId != null) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => CreateTeamPage(companyId: _companyId!)),
            );
          }
        },
        backgroundColor: primaryBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nova Equipe', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}