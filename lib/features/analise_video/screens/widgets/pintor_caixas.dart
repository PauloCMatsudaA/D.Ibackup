import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:logger/logger.dart';

import 'package:detector_celular_app/features/analise_video/domain/entidades/resultado_deteccao.dart';

class PintorCaixas extends CustomPainter {
  final List<ResultadoDeteccao> deteccoes;
  final double larguraPreview;
  final double alturaPreview;
  final double escala;
  final Size tamanhoTela;
  final bool ehIOS;
  // Removido: final int orientacaoSensorCamera;
  // Removido: final CameraLensDirection direcaoLenteCamera;

  final Logger _logger = Logger();

  PintorCaixas({
    super.repaint,
    required this.deteccoes,
    required this.larguraPreview,
    required this.alturaPreview,
    required this.escala,
    required this.tamanhoTela,
    required this.ehIOS,
    // Removido dos required: orientacaoSensorCamera, direcaoLenteCamera,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _logger.d('PintorCaixas: Método paint chamado. Detecções: ${deteccoes.length}');
    _logger.d('PintorCaixas: Tamanho Canvas (size): ${size.width}x${size.height}');

    final Paint pincel = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final TextPainter pintorTexto = TextPainter(
      textAlign: TextAlign.left,
      textDirection: TextDirection.ltr,
    );

    final double larguraPreviewEscalada = larguraPreview * escala;
    final double alturaPreviewEscalada = alturaPreview * escala;
    
    final double offsetX = (size.width - larguraPreviewEscalada) / 2;
    final double offsetY = (size.height - alturaPreviewEscalada) / 2;

    _logger.d('PintorCaixas: Preview ORIGINAL (Sensor): ${larguraPreview}x${alturaPreview}');
    _logger.d('PintorCaixas: Preview ESCALADO: ${larguraPreviewEscalada.toStringAsFixed(1)}x${alturaPreviewEscalada.toStringAsFixed(1)}');
    _logger.d('PintorCaixas: Escala: $escala');
    _logger.d('PintorCaixas: Offset para Centralização: X=${offsetX.toStringAsFixed(1)}, Y=${offsetY.toStringAsFixed(1)}');

    for (var deteccao in deteccoes) {
      Rect caixaOriginal = deteccao.caixa;

      double displayX, displayY, displayWidth, displayHeight;

      // ATENÇÃO: A lógica de mapeamento para análise de vídeo é mais simples
      // porque a imagem já vem do VideoThumbnail em uma orientação padrão
      // e não de um stream de câmera ao vivo com rotações complexas de sensor.
      displayX = caixaOriginal.left * escala;
      displayY = caixaOriginal.top * escala;
      displayWidth = caixaOriginal.width * escala;
      displayHeight = caixaOriginal.height * escala;
      
      final Rect caixaExibicao = Rect.fromLTWH(
        displayX + offsetX,
        displayY + offsetY,
        displayWidth,
        displayHeight,
      );

      _logger.d('PintorCaixas: Detecção ${deteccao.rotulo} (Confiança: ${deteccao.pontuacao.toStringAsFixed(2)})');
      _logger.d('PintorCaixas:   Caixa Original: L=${caixaOriginal.left.toInt()}, T=${caixaOriginal.top.toInt()}, R=${caixaOriginal.right.toInt()}, B=${caixaOriginal.bottom.toInt()} (Res Sensor: ${larguraPreview.toInt()}x${alturaPreview.toInt()})');
      _logger.d('PintorCaixas:   Caixa Exibição: L=${caixaExibicao.left.toInt()}, T=${caixaExibicao.top.toInt()}, R=${caixaExibicao.right.toInt()}, B=${caixaExibicao.bottom.toInt()} (Res Canvas: ${size.width.toInt()}x${size.height.toInt()})');

      if (caixaExibicao.width > 0 &&
          caixaExibicao.height > 0 &&
          caixaExibicao.right > 0 &&
          caixaExibicao.bottom > 0 &&
          caixaExibicao.left < size.width &&
          caixaExibicao.top < size.height) {
        
        _logger.i('PintorCaixas: Caixa ${deteccao.rotulo} VISÍVEL e sendo desenhada em: $caixaExibicao');
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
      } else {
        _logger.w('PintorCaixas: Caixa ${deteccao.rotulo} está FORA DA TELA ou tem dimensão zero: $caixaExibicao');
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return (oldDelegate as PintorCaixas).deteccoes != deteccoes;
  }
}