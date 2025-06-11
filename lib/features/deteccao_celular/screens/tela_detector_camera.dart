import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img_lib;
import 'package:logger/logger.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:detector_celular_app/arquivos_principais/servico_notificacao.dart';
import 'package:detector_celular_app/features/deteccao_celular/data/servico_detector.dart'; 
import 'package:detector_celular_app/features/deteccao_celular/domain/entidades/resultado_deteccao.dart'; 
import 'package:detector_celular_app/componentes_compartilhados/utilidades/util_imagens.dart';

class TelaDetectorCamera extends StatefulWidget { 
  const TelaDetectorCamera({super.key});

  @override
  State<TelaDetectorCamera> createState() => _EstadoTelaDetectorCamera(); 
}

class _EstadoTelaDetectorCamera extends State<TelaDetectorCamera> with WidgetsBindingObserver { 
  CameraController? _controladorCamera; 
  List<CameraDescription>? _camerasDisponiveis; 
  final ServicoDetector _servicoDetector = ServicoDetector(); 
  List<ResultadoDeteccao> _deteccoes = []; 
  bool _estaDetectando = false; 
  final Logger _logger = Logger();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _inicializarCameraEModelo();
    ServicoNotificacao.inicializar(); 
  }

  Future<void> _inicializarCameraEModelo() async { 
    _logger.i('TelaDetectorCamera: Inicializando câmera e modelo...');
    try {
      _camerasDisponiveis = await availableCameras(); 
      if (_camerasDisponiveis == null || _camerasDisponiveis!.isEmpty) {
        _logger.e('TelaDetectorCamera: ERRO: Nenhuma câmera disponível no dispositivo.');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nenhuma câmera disponível no dispositivo.')),
          );
        }
        return;
      }

      CameraDescription cameraSelecionada = _camerasDisponiveis!.firstWhere( 
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _camerasDisponiveis![0],
      );

      _controladorCamera = CameraController( 
        cameraSelecionada, 
        ResolutionPreset.medium,
        enableAudio: false,
      );

      _controladorCamera!.addListener(() { 
        if (mounted) setState(() {});
      });

      await _controladorCamera!.initialize(); 
      await _servicoDetector.carregarModelo(); 
      _iniciarStreamDeImagens(); 
      _logger.i('TelaDetectorCamera: Câmera e modelo inicializados com sucesso.');
    } on CameraException catch (e) {
      _logger.e('TelaDetectorCamera: Erro ao inicializar a câmera: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao inicializar a câmera: ${e.code}')),
        );
      }
    } on Exception catch (e) {
      _logger.e('TelaDetectorCamera: Erro inesperado ao inicializar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro inesperado: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _iniciarStreamDeImagens() {
        if (_controladorCamera == null || !_controladorCamera!.value.isInitialized) {
          _logger.w('TelaDetectorCamera: Câmera não inicializada para stream.');
          return;
        }

  
        _controladorCamera!.startImageStream((CameraImage imagem) async {
          if (!_estaDetectando) {
            _estaDetectando = true; 
            try {
              final img_lib.Image? imagemConvertida = UtilImagens.converterImagemCamera(imagem);
              if (imagemConvertida != null) {
                final resultados = await _servicoDetector.detectar(imagemConvertida);
                
                if (mounted) {
                  setState(() {
                    _deteccoes = resultados; 
                  });

      
                  if (resultados.isNotEmpty) {
                    _logger.i('TelaDetectorCamera: Celular(es) detectado(s)! Exibindo notificação.');
                    ServicoNotificacao.mostrarNotificacao(
                      id: 0, 
                      titulo: 'Celular Detectado!',
                      corpo: 'Um ou mais celulares foram encontrados em sua vizinhança.',
                    );
                  }
                }
              } else {
                _logger.w('TelaDetectorCamera: Formato de imagem da câmera não suportado ou erro na conversão.');
              }
            } catch (e) {
              _logger.e('TelaDetectorCamera: Erro durante a detecção do frame: $e');
            } finally {
              _estaDetectando = false;
            }
          }
        });
      }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controladorCamera == null || !_controladorCamera!.value.isInitialized) { 
      return;
    }
    if (state == AppLifecycleState.inactive) {
      _controladorCamera!.dispose(); 
    } else if (state == AppLifecycleState.resumed) {
      if (!_controladorCamera!.value.isInitialized) { 
        _inicializarCameraEModelo(); 
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controladorCamera?.dispose(); 
    _servicoDetector.fechar(); 
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controladorCamera == null || !_controladorCamera!.value.isInitialized) { 
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.blue)),
        ),
      );
    }

    final Size tela = MediaQuery.of(context).size; 
    final Size tamanhoPreview = _controladorCamera!.value.previewSize!; 

    final double larguraPreviewReal = Platform.isIOS ? tamanhoPreview.width : tamanhoPreview.height; 
    final double alturaPreviewReal = Platform.isIOS ? tamanhoPreview.height : tamanhoPreview.width; 

    double escala; 
    if (larguraPreviewReal / alturaPreviewReal > tela.width / tela.height) { 
      escala = tela.height / alturaPreviewReal; 
    } else {
      escala = tela.width / larguraPreviewReal; 
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Detector de Celular')),
      body: Stack(
        children: [
          Positioned.fill(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: larguraPreviewReal, 
                height: alturaPreviewReal,   
                child: CameraPreview(_controladorCamera!), 
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: PintorCaixas( 
                deteccoes: _deteccoes, 
                larguraPreview: larguraPreviewReal, 
                alturaPreview: alturaPreviewReal,   
                escala: escala, 
                tamanhoTela: tela, 
                ehIOS: Platform.isIOS, 
                orientacaoSensorCamera: _controladorCamera!.description.sensorOrientation, 
                direcaoLenteCamera: _controladorCamera!.description.lensDirection, 
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
      backgroundColor: Theme.of(context).colorScheme.secondary,
      foregroundColor: Theme.of(context).colorScheme.onSecondary,
      onPressed: () async {
        if (_deteccoes.isNotEmpty) {
          _logger.i('TelaDetectorCamera: Tentando salvar imagem com detecções...');
          final caminhoSalvo = await _servicoDetector.salvarImagemComDeteccao();
          if (mounted) {
            if (caminhoSalvo != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Imagem salva em: $caminhoSalvo')),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Falha ao salvar imagem.')),
              );
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Nenhuma detecção para salvar.')),
            );
          }
        }
      },
        child: const Icon(Icons.camera_alt), 
    ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat, 
    );
  }
}

class PintorCaixas extends CustomPainter {
  final List<ResultadoDeteccao> deteccoes; 
  final double larguraPreview; 
  final double alturaPreview;  
  final double escala; 
  final Size tamanhoTela; 
  final bool ehIOS; 
  final int orientacaoSensorCamera; 
  final CameraLensDirection direcaoLenteCamera; 

  PintorCaixas({
    required this.deteccoes,
    required this.larguraPreview,
    required this.alturaPreview,
    required this.escala,
    required this.tamanhoTela,
    required this.ehIOS,
    required this.orientacaoSensorCamera,
    required this.direcaoLenteCamera,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint pincel = Paint() 
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final TextPainter pintorTexto = TextPainter( 
      textAlign: TextAlign.left,
      textDirection: TextDirection.ltr,
    );

    final double larguraExibidaReal = larguraPreview * escala; 
    final double alturaExibidaReal = alturaPreview * escala;   
    final double offsetX = (tamanhoTela.width - larguraExibidaReal) / 2; 
    final double offsetY = (tamanhoTela.height - alturaExibidaReal) / 2; 

    for (var deteccao in deteccoes) { 
      Rect caixaOriginal = deteccao.caixa; 

      double x, y, largura, altura; 

      if (ehIOS) { 
        x = caixaOriginal.left * escala; 
        y = caixaOriginal.top * escala; 
        largura = caixaOriginal.width * escala; 
        altura = caixaOriginal.height * escala; 
      } else { 
        if (direcaoLenteCamera == CameraLensDirection.back) { 
            x = (alturaPreview - caixaOriginal.bottom) * escala; 
            y = caixaOriginal.left * escala; 
        } else {
            x = caixaOriginal.top * escala; 
            y = (larguraPreview - caixaOriginal.right) * escala; 
        }
        largura = caixaOriginal.height * escala; 
        altura = caixaOriginal.width * escala; 
      }

      final Rect caixaExibicao = Rect.fromLTWH( 
        x + offsetX,
        y + offsetY,
        largura,
        altura,
      );

      canvas.drawRect(caixaExibicao, pincel); 

      pintorTexto.text = TextSpan( 
        text: '${deteccao.rotulo} ${(deteccao.pontuacao * 100).toStringAsFixed(1)}%', 
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12.0,
          fontWeight: FontWeight.bold,
          backgroundColor: Colors.green,
        ),
      );
      pintorTexto.layout(); 
      pintorTexto.paint(canvas, Offset(caixaExibicao.left + 5, caixaExibicao.top - pintorTexto.height - 2)); 
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return (oldDelegate as PintorCaixas).deteccoes != deteccoes; 
  }
}