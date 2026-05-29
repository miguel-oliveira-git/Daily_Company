import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget customizado para exibir e copiar o código da empresa
class CompanyCodeDisplay extends StatelessWidget {
  final String code;
  final VoidCallback onCopy;
  final String? subtitle;

  const CompanyCodeDisplay({
    super.key,
    required this.code,
    required this.onCopy,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF005EB8);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryBlue, width: 2),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            code,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: primaryBlue,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.info_outline, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  subtitle ?? 'Compartilhe este código com os funcionários',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onCopy,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('Copiar Código'),
            ),
          ),
        ],
      ),
    );
  }
}
