import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daily_company/data/models/task_model.dart';

class TaskRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createTask(TaskModel task) async {
    await _firestore.collection('tasks').doc(task.id).set(task.toFirestore());
  }

  Stream<List<TaskModel>> getTasksStream(String companyId) {
    return _firestore
        .collection('tasks')
        .where('companyId', isEqualTo: companyId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList();
      // Ordena pelas tarefas com a data mais próxima
      list.sort((a, b) => a.date.compareTo(b.date));
      return list;
    });
  }
}