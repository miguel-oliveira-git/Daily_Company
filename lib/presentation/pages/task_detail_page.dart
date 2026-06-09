import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TaskDetailPage extends StatefulWidget {
  final String taskId;
  final String initialTitle;
  final String initialDescription;
  final String initialReferenceLink;
  final String initialStatus;
  final String creatorId;

  const TaskDetailPage({
    super.key,
    required this.taskId,
    required this.initialTitle,
    required this.initialDescription,
    required this.creatorId,
    this.initialReferenceLink = '',
    this.initialStatus = 'espera',
  });

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _linkController;
  late String _currentStatus;
  bool _isSaving = false;
  bool _isDeleting = false;

  bool get _isCreator => FirebaseAuth.instance.currentUser?.uid == widget.creatorId;

  final List<String> _statusOptions = ['espera', 'andamento', 'concluida'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _descriptionController = TextEditingController(text: widget.initialDescription);
    _linkController = TextEditingController(text: widget.initialReferenceLink);
    
    // Garante que o status inicial seja válido, caso contrário, define como 'espera'
    _currentStatus = _statusOptions.contains(widget.initialStatus) 
        ? widget.initialStatus 
        : 'espera';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _saveTask() async {
    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance.collection('tasks').doc(widget.taskId).update({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'referenceLink': _linkController.text.trim(),
        'status': _currentStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tarefa atualizada com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(); // Volta para a lista de tarefas após salvar
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao atualizar a tarefa. Tente novamente.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteTask() async {
    // Pede confirmação antes de excluir
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Tarefa'),
        content: const Text('Tem certeza que deseja excluir esta tarefa? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isDeleting = true);

    try {
      await FirebaseFirestore.instance.collection('tasks').doc(widget.taskId).delete();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tarefa excluída com sucesso!'), backgroundColor: Colors.green),
      );
      Navigator.of(context).pop(); // Volta para a lista após excluir
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao excluir a tarefa.'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  String _formatStatusLabel(String status) {
    switch (status) {
      case 'andamento':
        return 'Em andamento';
      case 'concluida':
        return 'Concluída';
      case 'espera':
      default:
        return 'Em espera';
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF005EB8);

    return Scaffold(
      backgroundColor: const Color(0xFFEFF4FB),
      appBar: AppBar(
        backgroundColor: primaryBlue,
        title: const Text('Detalhes da Tarefa', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_isDeleting)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                ),
              ),
            )
          else if (_isCreator)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              onPressed: _deleteTask,
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Título da Tarefa', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                readOnly: !_isCreator,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: _isCreator ? Colors.white : Colors.grey.shade200,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              const Text('Descrição', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
              const SizedBox(height: 8),
              TextField(
                controller: _descriptionController,
                maxLines: 5,
                readOnly: !_isCreator,
                decoration: InputDecoration(
                  hintText: _isCreator ? 'Adicione detalhes da tarefa aqui...' : '',
                  filled: true,
                  fillColor: _isCreator ? Colors.white : Colors.grey.shade200,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),

          const Text('Link de Referência', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
          const SizedBox(height: 8),
          TextField(
            controller: _linkController,
                readOnly: !_isCreator,
            decoration: InputDecoration(
                  hintText: _isCreator ? 'Link da reunião, documento ou local' : 'Nenhum link foi adicionado',
              filled: true,
                  fillColor: _isCreator ? Colors.white : Colors.grey.shade200,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),

              const Text('Status', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _currentStatus,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: _isCreator ? Colors.white : Colors.grey.shade200,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: _statusOptions.map((String status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(_formatStatusLabel(status)),
                  );
                }).toList(),
                // Desabilita a mudança manual do status se for funcionário
                onChanged: _isCreator 
                    ? (String? newValue) {
                        if (newValue != null) {
                          setState(() => _currentStatus = newValue);
                        }
                      }
                    : null,
              ),
              
              if (!_isCreator && _currentStatus != 'concluida') ...[
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : () {
                      setState(() => _currentStatus = 'concluida');
                      _saveTask();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.check_circle, color: Colors.white),
                    label: const Text('Concluir Tarefa', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
              
              // Esconde o botão de salvar alterações se for funcionário
              if (_isCreator) ...[
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveTask,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSaving
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Salvar Alterações', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}