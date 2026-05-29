import 'package:flutter/material.dart';

/// Validadores reutilizáveis para campos de funcionário
class EmployeeFormValidators {
  static String? validateName(String? value) {
    if (value?.isEmpty ?? true) return 'Nome é obrigatório';
    if ((value?.length ?? 0) < 3) return 'Nome muito curto';
    return null;
  }

  static String? validateRole(String? value) {
    if (value?.isEmpty ?? true) return 'Cargo é obrigatório';
    return null;
  }

  static String? validateEmail(String? value) {
    if (value?.isEmpty ?? true) return 'E-mail é obrigatório';
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value!)) {
      return 'E-mail inválido';
    }
    return null;
  }

  static String? validateCompanyCode(String? value) {
    if (value?.isEmpty ?? true) return 'Código da empresa é obrigatório';
    return null;
  }
}

/// Widget customizado para campo de formulário de funcionário
class EmployeeFormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final bool isRequired;
  final int? maxLines;
  final int? minLines;

  const EmployeeFormField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.isRequired = true,
    this.maxLines = 1,
    this.minLines,
  });

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF005EB8);
    const errorColor = Color(0xFFE53935);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(color: errorColor),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          maxLines: maxLines,
          minLines: minLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: primaryBlue),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: primaryBlue, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: errorColor, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: errorColor, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            hintStyle: TextStyle(color: Colors.grey.shade400),
            errorStyle: const TextStyle(color: errorColor, fontSize: 12),
          ),
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }
}
