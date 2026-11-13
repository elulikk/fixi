import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/state/providers.dart';

Future<void> main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('es_AR');
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarColor: Colors.transparent));
    final prefs = await SharedPreferences.getInstance();
    runApp(ProviderScope(overrides: [prefsProvider.overrideWithValue(prefs)], child: const FixiApp()));
  }, (error, stack) {
    // Errores asíncronos no críticos (p. ej. fuentes sin conexión) no deben tirar la app.
    debugPrint('Error no capturado: $error');
  });
}
