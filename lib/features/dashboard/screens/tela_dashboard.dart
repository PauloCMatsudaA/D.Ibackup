import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:detector_celular_app/features/analise_video/screens/tela_adicionar_momento.dart';
import 'package:detector_celular_app/features/analise_video/screens/tela_detalhes_momento.dart';
import 'package:detector_celular_app/features/autenticacao/screens/tela_login.dart';
import 'package:detector_celular_app/features/analise_video/screens/widgets/card_momento.dart';

class TelaDashboard extends StatefulWidget {
  const TelaDashboard({super.key});

  @override
  State<TelaDashboard> createState() => _EstadoTelaDashboard();
}

class _EstadoTelaDashboard extends State<TelaDashboard> {
  
  void _deletarMomento(String idMomento) {
    FirebaseFirestore.instance
      .collection('momentos')
      .doc(idMomento)
      .delete();
    
    if(mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Momento deletado.')),
      );
    }
  }
  
  void _navegarParaLogin() {
    if(mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const TelaLogin()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Medida de segurança caso o stream demore a atualizar
      return const Scaffold(body: Center(child: Text("Usuário não encontrado.")));
    }

    // --- MUDANÇA PRINCIPAL AQUI ---
    // Criamos a consulta fora do StreamBuilder para maior clareza.
    final Query momentosQuery = FirebaseFirestore.instance
            .collection('momentos')
            .where('userId', isEqualTo: user.uid)
            .orderBy('dataCriacao', descending: true);
    // --- FIM DA MUDANÇA ---


    return Scaffold(
      appBar: AppBar(
        title: const Text('Detector de Celular'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              _navegarParaLogin();
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Usamos a consulta que criamos acima
        stream: momentosQuery.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            // Log para nos ajudar a depurar se houver erro na consulta
            print("Erro no StreamBuilder do Dashboard: ${snapshot.error}");
            return const Center(child: Text('Erro ao carregar os dados.'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Nenhum momento criado ainda.\nClique em "+" para adicionar e analisar um vídeo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ),
            );
          }
          
          final momentosDocs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: momentosDocs.length,
            itemBuilder: (context, index) {
              final doc = momentosDocs[index];
              
              return CardMomento(
                momentoDoc: doc,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => TelaDetalhesMomento(momentoId: doc.id)),
                  );
                },
                onDelete: () => _deletarMomento(doc.id),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TelaAdicionarMomento()),
          );
        },
        tooltip: 'Adicionar Momento',
        child: const Icon(Icons.add),
      ),
    );
  }
}