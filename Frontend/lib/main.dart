import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import './app.dart';
import './services/fcm_service.dart';
import './core/feedback/app_feedback.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    AppFeedback.handleFlutterError(details);
  };

  await runZonedGuarded(() async {
    await initializeDateFormatting('pt_BR');
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
  }, (error, stackTrace) {
    AppFeedback.handleZoneError(error, stackTrace);
  });
}
