import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:detector_celular_app/arquivos_principais/providers/analise_video_provider.dart';

class TelaAnaliseVideo extends StatefulWidget {
  final String momentoId;
  final String tituloMomento;

  const TelaAnaliseVideo({
    required this.momentoId,
    required this.tituloMomento,
    super.key
  });

  @override
  State<TelaAnaliseVideo> createState() => _EstadoTelaAnaliseVideo();
}

class _EstadoTelaAnaliseVideo extends State<TelaAnaliseVideo> {
  bool _estaSalvando = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AnaliseVideoProvider>(context, listen: false).limparSelecao();
    });
  }

  Future<void> _onConcluirAnalise(AnaliseVideoProvider provider) async {
    setState(() => _estaSalvando = true);
    try {
      await provider.salvarAnaliseNoFirestore(widget.momentoId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Resultados salvos com sucesso!'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _estaSalvando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AnaliseVideoProvider>(
      builder: (context, provider, child) {
        final bool videoSelecionado = provider.videoFile != null;
        final bool analiseConcluida = !provider.estaProcessando && provider.caminhosImagensDetectadas.isNotEmpty;

        return Scaffold(
          appBar: AppBar(
            title: Text(widget.tituloMomento),
            actions: [
              if (analiseConcluida && !_estaSalvando)
                IconButton(
                  icon: const Icon(Icons.check),
                  tooltip: 'Salvar e Concluir',
                  onPressed: () => _onConcluirAnalise(provider),
                ),
              if (_estaSalvando)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)),
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!videoSelecionado)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.video_library),
                    onPressed: provider.selecionarVideo,
                    label: const Text('Selecionar Vídeo da Galeria'),
                  ),
                
                if (videoSelecionado) ...[
                  AspectRatio(
                    aspectRatio: provider.videoController!.value.aspectRatio,
                    child: VideoPlayer(provider.videoController!),
                  ),
                  const SizedBox(height: 16),
                  if (!provider.estaProcessando)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.change_circle_outlined),
                            onPressed: provider.selecionarVideo, // Botão para trocar
                            label: const Text('Trocar'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade700),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.search),
                            onPressed: provider.iniciarAnaliseDoVideo,
                            label: const Text('Analisar'),
                            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.secondary),
                          ),
                        ),
                      ],
                    ),
                ],

                if (provider.estaProcessando)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Column(
                      children: [
                        const LinearProgressIndicator(),
                        const SizedBox(height: 8),
                        Text(provider.progressoProcessamento, style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                  ),

                if (provider.caminhosImagensDetectadas.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text('Detecções Encontradas:', style: Theme.of(context).textTheme.headlineSmall),
                  const Divider(),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, crossAxisSpacing: 8, mainAxisSpacing: 8,
                    ),
                    itemCount: provider.caminhosImagensDetectadas.length,
                    itemBuilder: (context, index) {
                      return Card(
                        clipBehavior: Clip.antiAlias,
                        child: Image.file(File(provider.caminhosImagensDetectadas[index]), fit: BoxFit.cover),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}