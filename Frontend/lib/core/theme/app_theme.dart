import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const _primary = Color(0xFF00628b);
  static const _onPrimary = Color(0xFFffffff);
  static const _primaryContainer = Color(0xFF007caf);
  static const _onPrimaryContainer = Color(0xFFfcfcff);
  static const _surface = Color(0xFFf7f9fb);
  static const _onSurface = Color(0xFF191c1e);
  static const _surfaceVariant = Color(0xFFe0e3e5);
  static const _onSurfaceVariant = Color(0xFF3e4850);
  static const _error = Color(0xFFba1a1a);
  static const _errorContainer = Color(0xFFffdad6);

  // Status colors (para badges e inventário)
  static const statusDisponivel = Color(0xFF2e7d32);
  static const statusAlugado = Color(0xFFf9a825);
  static const statusManutencao = Color(0xFFc62828);
  static const statusPendente = Color(0xFFef6c00);
  static const statusFinalizada = Color(0xFF455a64);

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: _primary,
      onPrimary: _onPrimary,
      primaryContainer: _primaryContainer,
      onPrimaryContainer: _onPrimaryContainer,
      surface: _surface,
      onSurface: _onSurface,
      surfaceContainerHighest: _surfaceVariant,
      onSurfaceVariant: _onSurfaceVariant,
      error: _error,
      errorContainer: _errorContainer,
    ),
    textTheme: GoogleFonts.interTextTheme(),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      shadowColor: Colors.black.withValues(alpha: 0.05),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _surfaceVariant),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primary,
        foregroundColor: _onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        minimumSize: const Size.fromHeight(48),
      ),
    ),
  );
}
