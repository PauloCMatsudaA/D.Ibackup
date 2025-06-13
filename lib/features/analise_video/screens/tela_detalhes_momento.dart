import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TelaDetalhesMomento extends StatelessWidget {
  final String momentoId;

  const TelaDetalhesMomento({required this.momentoId, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da Detecção'),
      ),
      // Trocamos o FutureBuilder por um StreamBuilder
      body: StreamBuilder<DocumentSnapshot>(
        // Usamos .snapshots() para ouvir em tempo real
        stream: FirebaseFirestore.instance.collection('momentos').doc(momentoId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Momento não encontrado.'));
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar detalhes.'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          // A lógica para extrair os dados continua a mesma
          final List<String> imagensDetectadas = List<String>.from(data['imagensDetectadas'] ?? []);
          final String titulo = '${data['sala'] ?? ''} - ${data['data'] ?? ''}';
          final String descricao = data['descricao'] ?? '';

          // A exibição da UI também continua a mesma
          if (imagensDetectadas.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(titulo, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Text(descricao, style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center),
                    const Divider(height: 32),
                    const Icon(Icons.image_not_supported_outlined, size: 60, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'Nenhuma detecção foi salva para este momento ainda.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(titulo, style: Theme.of(context).textTheme.headlineSmall),
                      Text(descricao),
                      const SizedBox(height: 8),
                      Text('${imagensDetectadas.length} detecção(ões) registrada(s).', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                      const Divider(height: 20),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                sliver: SliverGrid.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: imagensDetectadas.length,
                  itemBuilder: (context, index) {
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      child: Image.file(
                        File(imagensDetectadas[index]),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                           return const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image, size: 40, color: Colors.grey),
                              SizedBox(height: 4),
                              Text("Erro ao\ncarregar", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey))
                            ],
                          );
                        }
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}