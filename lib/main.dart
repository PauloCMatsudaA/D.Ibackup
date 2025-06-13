import 'package:detector_celular_app/firebase_options.dart';
import 'package:detector_celular_app/features/autenticacao/screens/tela_login.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:detector_celular_app/arquivos_principais/providers/analise_video_provider.dart';

void main() async {
WidgetsFlutterBinding.ensureInitialized();
await Firebase.initializeApp(
options: DefaultFirebaseOptions.currentPlatform,
);
runApp(const MyApp());
}

class MyApp extends StatelessWidget {
const MyApp({super.key});

@override
Widget build(BuildContext context) {
return MultiProvider(
providers: [
ChangeNotifierProvider(create: (_) => AnaliseVideoProvider()),
],
child: MaterialApp(
title: 'Detector de Celular',
theme: ThemeData(
primarySwatch: Colors.indigo, // Cor primária da AppBar
appBarTheme: const AppBarTheme(
backgroundColor: Color(0xFF4CAF50), // Verde da AppBar
titleTextStyle: TextStyle(
color: Colors.white,
fontSize: 20,
fontWeight: FontWeight.bold,
),
centerTitle: true, // Centraliza o título (onde colocaremos o ícone)
iconTheme: IconThemeData(color: Colors.white),
),
scaffoldBackgroundColor: const Color(0xFF8BC34A).withOpacity(0.8), // Cor de fundo aproximada
floatingActionButtonTheme: const FloatingActionButtonThemeData(
backgroundColor: Colors.indigoAccent,
foregroundColor: Colors.white,
),
elevatedButtonTheme: ElevatedButtonThemeData(
style: ElevatedButton.styleFrom(
backgroundColor: Colors.indigo,
foregroundColor: Colors.white,
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
textStyle: const TextStyle(fontSize: 16),
),
),
cardTheme: CardTheme(
elevation: 4,
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
),
listTileTheme: const ListTileThemeData(
iconColor: Colors.indigo,
),
textTheme: const TextTheme(
headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black87),
bodyLarge: TextStyle(fontSize: 16, color: Colors.black87),
),
colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.indigo).copyWith(secondary: Colors.amber),
useMaterial3: true,
),
home: const TelaLogin(),
debugShowCheckedModeBanner: false,
),
);
}
}