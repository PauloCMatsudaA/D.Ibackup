import 'package:flutter/material.dart';
import 'package:detector_celular_app/features/deteccao_celular/screens/tela_detector_camera.dart'; // Caminho completo
import 'package:detector_celular_app/features/deteccao_celular/screens/tela_analise_video.dart'; // Caminho completo
import 'package:firebase_auth/firebase_auth.dart';


class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut(); // Desloga o usuário
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TelaDetectorCamera()),
                );
              },
              child: const Text('Detector de Câmera (Tempo Real)'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TelaAnaliseVideo()),
                );
              },
              child: const Text('Analisar Vídeo da Galeria'),
            ),
          ],
        ),
      ),
    );
  }
}