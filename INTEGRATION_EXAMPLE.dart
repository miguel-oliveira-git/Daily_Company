// Exemplo de integração da página de cadastro e vínculo de funcionários

// 1. Adicionar import no arquivo de navegação ou menu
import 'package:daily_company/presentation/pages/employee_registration_linking_page.dart';
import 'package:flutter/material.dart';

class MenuPageExample extends StatelessWidget {
  const MenuPageExample({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const EmployeeRegistrationLinkingPage(),
          ),
        );
      },
      child: const Icon(Icons.person_add),
    );
  }
}

class AppDrawerExample extends StatelessWidget {
  const AppDrawerExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person_add),
            title: const Text('Cadastrar Funcionário'),
            onTap: () {
              Navigator.pop(context); // Fechar drawer
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const EmployeeRegistrationLinkingPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// 4. Exemplo de rota nomeada (se usar routing.dart)

class AppRoutes {
  static const String employeeRegistration = '/employee-registration';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case employeeRegistration:
        return MaterialPageRoute(
          builder: (_) => const EmployeeRegistrationLinkingPage(),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(
              child: Text('Rota não encontrada'),
            ),
          ),
        );
    }
  }
}

// Uso com rota nomeada:
// Navigator.of(context).pushNamed(AppRoutes.employeeRegistration);

// 5. Exemplo de integração em MenuPage já existente

class MenuPageIntegration extends StatelessWidget {
  const MenuPageIntegration({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Funcionários'),
            subtitle: const Text('Cadastrar e gerenciar'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const EmployeeRegistrationLinkingPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// 6. Exemplo com argumentos (se necessário passar dados)

class MenuPageWithArgs extends StatelessWidget {
  const MenuPageWithArgs({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) {
              // Você poderia passar dados adicionais aqui se necessário
              return const EmployeeRegistrationLinkingPage();
            },
          ),
        );
      },
      child: const Icon(Icons.add),
    );
  }
}

// 7. Exemplo de página que lista e oferece acesso à funcionalidade

class EmployeesManagementPage extends StatelessWidget {
  const EmployeesManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Funcionários'),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const EmployeeRegistrationLinkingPage(),
                  ),
                );
              },
              icon: const Icon(Icons.person_add),
              label: const Text('Cadastrar Novo Funcionário'),
            ),
          ),
          // ... resto da página com lista de funcionários
        ],
      ),
    );
  }
}

// 8. Exemplo de uso com Future result

Future<void> navigateToEmployeeRegistration(BuildContext context) async {
  final result = await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => const EmployeeRegistrationLinkingPage(),
    ),
  );

  if (result != null && context.mounted) {
    // Processar resultado se necessário
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funcionário adicionado com sucesso')),
    );
  }
}

// Uso: navigateToEmployeeRegistration(context);
