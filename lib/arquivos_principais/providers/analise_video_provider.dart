import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:logger/logger.dart';
import 'package:image/image.dart' as img_lib;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_compress/video_compress.dart';

import 'package:detector_celular_app/features/analise_video/data/servico_detector.dart';
import 'package:detector_celular_app/features/analise_video/domain/entidades/resultado_deteccao.dart';
import 'package:detector_celular_app/arquivos_principais/servico_notificacao.dart';

class AnaliseVideoProvider extends ChangeNotifier {
  // Estado da UI
  VideoPlayerController? _videoController;
  XFile? _videoFile;
  bool _estaProcessando = false;
  String _progressoProcessamento = '';
  List<String> _caminhosImagensDetectadas = [];

  // Getters
  VideoPlayerController? get videoController => _videoController;
  XFile? get videoFile => _videoFile;
  bool get estaProcessando => _estaProcessando;
  String get progressoProcessamento => _progressoProcessamento;
  List<String> get caminhosImagensDetectadas => _caminhosImagensDetectadas;

  // Serviços
  final Logger _logger = Logger();
  final ServicoDetector _servicoDetector = ServicoDetector();

  AnaliseVideoProvider() {
    _inicializar();
  }

  Future<void> _inicializar() async {
    await _servicoDetector.carregarModelo();
    await ServicoNotificacao.inicializar();
  }

  Future<void> selecionarVideo() async {
    limparSelecao();
    final ImagePicker picker = ImagePicker();
    final XFile? video = await picker.pickVideo(source: ImageSource.gallery);

    if (video != null) {
      _videoFile = video;
      _videoController = VideoPlayerController.file(File(video.path))
        ..initialize().then((_) {
          notifyListeners();
        });
      notifyListeners();
    }
  }

  Future<void> iniciarAnaliseDoVideo() async {
    if (_videoFile == null || !_servicoDetector.estaPronto || _estaProcessando) return;

    _setEstadoProcessamento(true, 'Iniciando extração e detecção...');
    _caminhosImagensDetectadas = [];

    try {
      final videoPath = _videoFile!.path;
      final int duracaoMs = _videoController!.value.duration.inMilliseconds;
      if (duracaoMs == 0) throw Exception("Duração do vídeo é zero.");
      final int intervaloFramesMs = 1000;

      for (int i = 0; i <= duracaoMs; i += intervaloFramesMs) {
        if (!_estaProcessando) break;
        _setEstadoProcessamento(true, 'Analisando... (${(i / duracaoMs * 100).toStringAsFixed(0)}%)');
        final thumbnailBytes = await VideoCompress.getByteThumbnail(videoPath, quality: 75, position: i);

        if (thumbnailBytes != null) {
          final img_lib.Image? frame = img_lib.decodeImage(thumbnailBytes);
          if (frame != null) {
            final List<ResultadoDeteccao> deteccoes = await _servicoDetector.detectar(frame);
            if (deteccoes.isNotEmpty) {
              final String? caminhoSalvo = await _servicoDetector.salvarImagemComDeteccao();
              if (caminhoSalvo != null) {
                _caminhosImagensDetectadas.add(caminhoSalvo);
                if (_caminhosImagensDetectadas.length == 1) {
                  ServicoNotificacao.mostrarNotificacao(id: 0, titulo: "Alerta de Detecção", corpo: "Um celular foi detectado no vídeo analisado!");
                }
                notifyListeners();
              }
            }
          }
        }
      }
      _setEstadoProcessamento(false, 'Análise concluída. ${_caminhosImagensDetectadas.length} detecções salvas.');
    } catch (e) {
      _logger.e('Provider: Erro ao processar vídeo: $e');
      _setEstadoProcessamento(false, 'Erro no processamento: $e');
    }
  }

  // NOVO MÉTODO PARA SALVAR
  Future<void> salvarAnaliseNoFirestore(String momentoId) async {
    if (_caminhosImagensDetectadas.isEmpty) {
        _logger.w("Nenhuma imagem detectada para salvar.");
        return;
    }
    try {
      _logger.i('Salvando ${_caminhosImagensDetectadas.length} imagens no momento $momentoId');
      await FirebaseFirestore.instance
          .collection('momentos')
          .doc(momentoId)
          .update({
        'imagensDetectadas': _caminhosImagensDetectadas,
        'status': 'Analisado',
      });
    } catch (e) {
      _logger.e('Erro ao salvar resultados no Firestore: $e');
      // Re-throw para que a UI possa mostrar um erro
      throw Exception('Falha ao salvar no banco de dados.');
    }
  }

  void _setEstadoProcessamento(bool processando, String mensagem) {
    _estaProcessando = processando;
    _progressoProcessamento = mensagem;
    notifyListeners();
  }

  void limparSelecao() {
    _videoController?.dispose();
    _videoController = null;
    _videoFile = null;
    _estaProcessando = false;
    _progressoProcessamento = '';
    _caminhosImagensDetectadas = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _servicoDetector.fechar();
    super.dispose();
  }
}