import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img_lib;
import 'dart:math' as math;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';

import 'package:detector_celular_app/features/analise_video/domain/entidades/resultado_deteccao.dart';


class ServicoDetector {
  Interpreter? _interpretador;

  bool get estaPronto => _interpretador != null;

  static const String caminhoModelo = 'assets/models/best.tflite';
  static const List<String> rotulos = ['celular'];

  img_lib.Image? _ultimaImagemProcessada;
  List<ResultadoDeteccao> _ultimoResultadoDeteccao = [];

  final Uuid _uuid = Uuid();

  Future<void> carregarModelo() async {
    try {
      _interpretador = await Interpreter.fromAsset(caminhoModelo);
      print('ServicoDetector: Modelo TFLite carregado com sucesso!');
      print('ServicoDetector: Dimensão de Entrada: ${_interpretador!.getInputTensor(0).shape}');
      print('ServicoDetector: Dimensão de Saída: ${_interpretador!.getOutputTensor(0).shape}');
    } catch (e) {
      print('ServicoDetector: ERRO ao carregar o modelo TFLite: $e');
      _interpretador = null;
    }
  }

  // MÉTODO 'detectar' CORRIGIDO E ATUALIZADO
  Future<List<ResultadoDeteccao>> detectar(img_lib.Image imagemOriginal) async {
    if (_interpretador == null) {
      print('ServicoDetector: Modelo não carregado.');
      return [];
    }
    _ultimaImagemProcessada = imagemOriginal;

    try {
      final int larguraModelo = _interpretador!.getInputTensor(0).shape[2]; // 640
      final int alturaModelo = _interpretador!.getInputTensor(0).shape[1]; // 640

      img_lib.Image imagemRedimensionada = img_lib.copyResize(
        imagemOriginal,
        width: larguraModelo,
        height: alturaModelo,
      );

      final bytesEntrada = Float32List(1 * alturaModelo * larguraModelo * 3);
      int indicePixel = 0;
      for (int y = 0; y < alturaModelo; y++) {
        for (int x = 0; x < larguraModelo; x++) {
          final pixel = imagemRedimensionada.getPixel(x, y);
          bytesEntrada[indicePixel++] = pixel.r / 255.0;
          bytesEntrada[indicePixel++] = pixel.g / 255.0;
          bytesEntrada[indicePixel++] = pixel.b / 255.0;
        }
      }

      final outputShape = _interpretador!.getOutputTensor(0).shape; // [1, 5, 8400]
      final rawOutput = List.filled(outputShape.reduce((a, b) => a * b), 0.0).reshape(outputShape);
      
      final outputs = {0: rawOutput};
      _interpretador!.runForMultipleInputs([bytesEntrada.reshape([1, alturaModelo, larguraModelo, 3])], outputs);

      // Transpõe a saída de [1, 5, 8400] para uma lista de 8400 caixas com 5 valores cada
      final List<List<double>> transposedOutput = [];
      final int numBoxes = rawOutput[0][0].length; // 8400
      final int numValues = rawOutput[0].length;    // 5

      for (int i = 0; i < numBoxes; i++) {
          final boxData = List.filled(numValues, 0.0);
          for (int j = 0; j < numValues; j++) {
              boxData[j] = rawOutput[0][j][i];
          }
          transposedOutput.add(boxData);
      }
      
      List<Rect> caixas = [];
      List<double> pontuacoes = [];
      List<int> idsClasses = [];

      final double limiarConfianca = 0.60; // Limiar ajustado para a confiança real do modelo
      final double limiarIoU = 0.4;

      for (int i = 0; i < numBoxes; i++) {
        final pontuacao = transposedOutput[i][4]; // A confiança está no índice 4

        if (pontuacao > limiarConfianca) {
          final double cx = transposedOutput[i][0];
          final double cy = transposedOutput[i][1];
          final double w = transposedOutput[i][2];
          final double h = transposedOutput[i][3];

          final double x1 = (cx - w / 2) * imagemOriginal.width;
          final double y1 = (cy - h / 2) * imagemOriginal.height;
          final double x2 = (cx + w / 2) * imagemOriginal.width;
          final double y2 = (cy + h / 2) * imagemOriginal.height;

          caixas.add(Rect.fromLTRB(x1, y1, x2, y2));
          pontuacoes.add(pontuacao);
          idsClasses.add(0);
        }
      }

      if (caixas.isEmpty) {
        _ultimoResultadoDeteccao = [];
        return [];
      }

      List<int> resultadoNMS = _naoMaximaSupressao(caixas, pontuacoes, limiarIoU);
      List<ResultadoDeteccao> deteccoes = [];
      for (int indice in resultadoNMS) {
        deteccoes.add(ResultadoDeteccao(
          caixa: caixas[indice],
          pontuacao: pontuacoes[indice],
          rotulo: rotulos[idsClasses[indice]],
        ));
      }

      _ultimoResultadoDeteccao = deteccoes;
      return deteccoes;

    } catch (e) {
      print('ServicoDetector: ERRO DURANTE A INFERÊNCIA: $e');
      return [];
    }
  }

  Future<String?> salvarImagemComDeteccao() async {
    if (_ultimaImagemProcessada == null || _ultimoResultadoDeteccao.isEmpty) {
      return null;
    }

    final img_lib.Image imagemParaSalvar = img_lib.Image.from(_ultimaImagemProcessada!);
    final img_lib.Color corDaCaixa = img_lib.ColorRgba8(0, 255, 0, 255);

    for (var detecao in _ultimoResultadoDeteccao) {
      img_lib.drawRect(
        imagemParaSalvar,
        x1: detecao.caixa.left.toInt(),
        y1: detecao.caixa.top.toInt(),
        x2: detecao.caixa.right.toInt(),
        y2: detecao.caixa.bottom.toInt(),
        color: corDaCaixa,
        thickness: 3,
      );
    }

    final directory = await getApplicationDocumentsDirectory();
    final String caminhoArquivo = '${directory.path}/deteccao_${_uuid.v4()}.jpg';

    final File arquivo = File(caminhoArquivo);
    await arquivo.writeAsBytes(img_lib.encodeJpg(imagemParaSalvar));

    print('ServicoDetector: Imagem salva em: $caminhoArquivo');
    return caminhoArquivo;
  }

  List<int> _naoMaximaSupressao(List<Rect> caixas, List<double> pontuacoes, double limiarIoU) {
    if (caixas.isEmpty) return [];

    List<int> selecionadas = [];
    List<int> indices = List.generate(pontuacoes.length, (i) => i);
    indices.sort((a, b) => pontuacoes[b].compareTo(pontuacoes[a]));

    while (indices.isNotEmpty) {
      int ultimo = indices.length - 1;
      int i = indices[ultimo];
      selecionadas.add(i);

      List<int> suprimir = [ultimo];
      for (int pos = 0; pos < ultimo; pos++) {
        int j = indices[pos];
        double iou = _calcularIoU(caixas[i], caixas[j]);

        if (iou > limiarIoU) {
          suprimir.add(pos);
        }
      }
      indices.removeWhere((item) => suprimir.contains(indices.indexOf(item)));
    }
    return selecionadas;
  }

  double _calcularIoU(Rect caixa1, Rect caixa2) {
    double x1 = math.max(caixa1.left, caixa2.left);
    double y1 = math.max(caixa1.top, caixa2.top);
    double x2 = math.min(caixa1.right, caixa2.right);
    double y2 = math.min(caixa1.bottom, caixa2.bottom);

    double larguraInterseccao = math.max(0.0, x2 - x1);
    double alturaInterseccao = math.max(0.0, y2 - y1);
    double areaInterseccao = larguraInterseccao * alturaInterseccao;

    double areaCaixa1 = caixa1.width * caixa1.height;
    double areaCaixa2 = caixa2.width * caixa2.height;
    double areaUniao = areaCaixa1 + areaCaixa2 - areaInterseccao;

    return areaUniao > 0 ? areaInterseccao / areaUniao : 0.0;
  }

  void fechar() {
    if (_interpretador != null) {
      _interpretador!.close();
      _interpretador = null;
      print('ServicoDetector: Modelo TFLite fechado.');
    }
  }
}