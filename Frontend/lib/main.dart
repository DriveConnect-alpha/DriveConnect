import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import './app.dart';
import './services/fcm_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Carrega variáveis de ambiente
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Erro ao carregar .env: $e');
  }

  // Inicializa o Firebase (Exige google-services.json no Android e GoogleService-Info.plist no iOS)
  try {
    await Firebase.initializeApp();
    await FcmService().init();
  } catch (e) {
    debugPrint('Falha na inicialização do Firebase: $e');
  }

  runApp(const DriveConnectApp());
}
