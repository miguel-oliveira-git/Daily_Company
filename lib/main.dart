import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // 1. Importe o pacote
import 'firebase_options.dart'; 
import 'package:daily_company/presentation/auth/pages/init_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Carregue o arquivo .env antes de inicializar o Firebase
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    // Caso o arquivo .env não exista (útil para avisar sua equipe)
    debugPrint("Erro ao carregar o arquivo .env: $e");
  }

  // 3. Agora o Firebase pode inicializar usando as variáveis que estão no .env
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daily Company',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF005EB8)),
        useMaterial3: true,
      ),
      home: const InitPage(), 
    );
  }
}