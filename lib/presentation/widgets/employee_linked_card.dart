import 'package:flutter/material.dart';
import 'package:daily_company/data/models/employee_model.dart';
import 'package:daily_company/presentation/widgets/linked_badge.dart';

/// Widget customizado para exibir o card do funcionário vinculado
class EmployeeLinkedCard extends StatelessWidget {
  final EmployeeModel employee;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const EmployeeLinkedCard({
    super.key,
    required this.employee,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            _buildInfoSection(),
            if (onDelete != null || onEdit != null) ...[
              const SizedBox(height: 12),
              _buildActionsRow(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                employee.name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                employee.role,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF005EB8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        LinkedBadge.linked(),
      ],
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(Icons.email, 'E-mail', employee.email),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.lock, 'Código', employee.companyCode),
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.calendar_today,
            'Vinculado em',
            _formatDate(employee.linkedAt),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildActionsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (onEdit != null)
          TextButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('Editar'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF005EB8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        if (onDelete != null)
          TextButton.icon(
            onPressed: onDelete,
            icon: const Icon(Icons.delete, size: 16),
            label: const Text('Remover'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFE53935),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
