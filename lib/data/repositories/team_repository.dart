import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daily_company/data/models/team_model.dart';

class TeamRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createTeam(TeamModel team) async {
    try {
      await _firestore.collection('teams').doc(team.id).set(team.toFirestore());
    } catch (e) {
      throw Exception('Erro ao criar equipe: $e');
    }
  }

  Future<void> updateTeam(TeamModel team) async {
    try {
      await _firestore.collection('teams').doc(team.id).update(team.toFirestore());
    } catch (e) {
      throw Exception('Erro ao atualizar equipe: $e');
    }
  }

  Stream<List<TeamModel>> getTeamsStream(String companyId) {
    return _firestore
        .collection('teams')
        .where('companyId', isEqualTo: companyId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => TeamModel.fromFirestore(doc)).toList();
    });
  }

  Future<void> deleteTeam(String teamId) async {
    await _firestore.collection('teams').doc(teamId).delete();
  }
}