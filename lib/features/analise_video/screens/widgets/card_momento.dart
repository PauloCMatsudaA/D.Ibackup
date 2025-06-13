import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:detector_celular_app/features/analise_video/screens/tela_adicionar_momento.dart';
import 'package:flutter/material.dart';

class CardMomento extends StatelessWidget {
  final DocumentSnapshot momentoDoc; // Agora recebe o documento inteiro
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const CardMomento({
    required this.momentoDoc,
    required this.onTap,
    required this.onDelete,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final dados = momentoDoc.data() as Map<String, dynamic>;
    final String sala = dados['sala'] ?? 'N/A';
    final String data = dados['data'] ?? 'N/A';
    final String descricao = dados['descricao'] ?? 'N/A';
    // Pega a cor salva, ou usa uma cor padrão se não existir
    final Color corDoCard = Color(dados['cor'] ?? Colors.blue.shade700.value);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      color: corDoCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      elevation: 4.0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(sala, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('DIA ${data}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  // Botões de Ação (Editar e Deletar)
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white),
                        tooltip: 'Editar',
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (context) => TelaAdicionarMomento(momentoParaEditar: momentoDoc),
                          ));
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.white),
                        tooltip: 'Deletar',
                        onPressed: onDelete,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(descricao, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}