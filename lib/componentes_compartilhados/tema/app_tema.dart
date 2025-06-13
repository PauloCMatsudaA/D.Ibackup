import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart'; // Descomente se for usar Google Fonts

class CoresApp {
  static const Color primary = Color(0xFF3F51B5); // Índigo (Azul Profundo)
  static const Color onPrimary = Color(0xFFFFFFFF); // Texto/ícones sobre a cor primária
  static const Color primaryContainer = Color(0xFFC5CAE9); // Contêiner primário
  static const Color onPrimaryContainer = Color(0xFF1A237E); // Texto/ícones sobre contêiner primário

  static const Color secondary = Color(0xFF00BCD4); // Ciano (Verde Água)
  static const Color onSecondary = Color(0xFFFFFFFF); // Texto/ícones sobre a cor secundária
  static const Color secondaryContainer = Color(0xFFB2EBF2); // Contêiner secundário
  static const Color onSecondaryContainer = Color(0xFF006064); // Texto/ícones sobre contêiner secundário

  static const Color tertiary = Color(0xFFFDD835); // Amarelo
  static const Color onTertiary = Color(0xFF212121);

  static const Color surface = Color(0xFFFFFFFF); // Cor principal do fundo
  static const Color onSurface = Color(0xFF212121); // Texto sobre a superfície
  static const Color surfaceVariant = Color(0xFFECEFF1); // Variação da superfície
  static const Color onSurfaceVariant = Color(0xFF455A64); // Texto sobre variação da superfície

  static const Color error = Color(0xFFB00020); // Vermelho para erros
  static const Color onError = Color(0xFFFFFFFF); // Texto sobre erro
  static const Color background = Color(0xFFF5F5F5); // Fundo geral do app
  static const Color onBackground = Color(0xFF212121); // Texto sobre o fundo
}

class AppTema {
  static ThemeData get temaClaro {
    return ThemeData(
      useMaterial3: true, // Habilita o Material Design 3
      brightness: Brightness.light, // Tema claro
      primaryColor: CoresApp.primary, // Cor primária

      colorScheme: const ColorScheme.light( // Adicionado 'const' aqui
        primary: CoresApp.primary,
        onPrimary: CoresApp.onPrimary,
        primaryContainer: CoresApp.primaryContainer,
        onPrimaryContainer: CoresApp.onPrimaryContainer,
        secondary: CoresApp.secondary,
        onSecondary: CoresApp.onSecondary,
        secondaryContainer: CoresApp.secondaryContainer,
        onSecondaryContainer: CoresApp.onSecondaryContainer,
        tertiary: CoresApp.tertiary,
        onTertiary: CoresApp.onTertiary,
        surface: CoresApp.surface,
        onSurface: CoresApp.onSurface,
        surfaceVariant: CoresApp.surfaceVariant,
        onSurfaceVariant: CoresApp.onSurfaceVariant,
        error: CoresApp.error,
        onError: CoresApp.onError,
        background: CoresApp.background,
        onBackground: CoresApp.onBackground,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: CoresApp.primary,
        foregroundColor: CoresApp.onPrimary,
        elevation: 4.0,
        centerTitle: true,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: CoresApp.secondary,
          foregroundColor: CoresApp.onSecondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: CoresApp.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: CoresApp.primary, width: 2.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: CoresApp.onSurfaceVariant.withOpacity(0.5), width: 1.0),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        hintStyle: TextStyle(color: CoresApp.onSurfaceVariant.withOpacity(0.7)),
      ),
    );
  }
}