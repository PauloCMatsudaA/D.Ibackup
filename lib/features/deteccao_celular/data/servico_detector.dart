import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img_lib;
import 'dart:math' as math;
import 'dart:ui';
import 'package:detector_celular_app/features/deteccao_celular/domain/entidades/resultado_deteccao.dart';


class ServicoDetector { 
  Interpreter? _interpretador;
  static const String caminhoModelo = 'assets/modelos/melhor.tflite';
  static const List<String> rotulos = ['celular']; 

  int _alturaEntrada = 0; 
  int _larguraEntrada = 0; 

  Future<void> carregarModelo() async { 
    try {
      _interpretador = await Interpreter.fromAsset(caminhoModelo);
      print('ServicoDetector: Modelo TFLite carregado com sucesso!');

      _alturaEntrada = _interpretador!.getInputTensor(0).shape[1]; 
      _larguraEntrada = _interpretador!.getInputTensor(0).shape[2]; 
      print('ServicoDetector: Dimensão de Entrada: ${_interpretador!.getInputTensor(0).shape}');
      print('ServicoDetector: Dimensão de Saída: ${_interpretador!.getOutputTensor(0).shape}');

    } catch (e) {
      print('ServicoDetector: Erro ao carregar o modelo TFLite: $e');
      _interpretador = null;
    }
  }

  Future<List<ResultadoDeteccao>> detectar(img_lib.Image imagemOriginal) async { 
    if (_interpretador == null) {
      print('ServicoDetector: Modelo não carregado, não é possível detectar.');
      return [];
    }

    img_lib.Image imagemRedimensionada = img_lib.copyResize( 
      imagemOriginal,
      width: _larguraEntrada,
      height: _alturaEntrada,
    );

    final bytesEntrada = Float32List(1 * _alturaEntrada * _larguraEntrada * 3); 
    int indicePixel = 0; 
    for (int y = 0; y < _alturaEntrada; y++) {
      for (int x = 0; x < _larguraEntrada; x++) {
        final pixel = imagemRedimensionada.getPixel(x, y);
            bytesEntrada[indicePixel++] = pixel.r / 255.0;
            bytesEntrada[indicePixel++] = pixel.g / 255.0;
            bytesEntrada[indicePixel++] = pixel.b / 255.0; 
      }
    }

    final dimensaoTensorSaida = _interpretador!.getOutputTensor(0).shape; 
    final numCaixas = dimensaoTensorSaida[1]; 
    final numClasses = dimensaoTensorSaida[2] - 4; 

    final saida = List.filled( 
      1 * numCaixas * (4 + numClasses), 0.0,
    ).reshape([1, numCaixas, 4 + numClasses]);

    final saidas = {0: saida}; 

    _interpretador!.runForMultipleInputs([bytesEntrada.reshape([1, _alturaEntrada, _larguraEntrada, 3])], saidas);

    List<ResultadoDeteccao> deteccoes = []; 
    final dadosSaida = saida[0] as List<List<double>>; 

    final double limiarConfianca = 0.5; 
    final double limiarIoU = 0.4;       

    List<Rect> caixas = []; 
    List<double> pontuacoes = [];
    List<int> idsClasses = []; 

    for (int i = 0; i < numCaixas; i++) {
      final List<double> dadosCaixa = dadosSaida[i]; 
      final double pontuacao = dadosCaixa[4]; 

      if (pontuacao > limiarConfianca) {
        double cx = dadosCaixa[0];
        double cy = dadosCaixa[1];
        double w = dadosCaixa[2];
        double h = dadosCaixa[3];

        double x1 = (cx - w / 2) * imagemOriginal.width;
        double y1 = (cy - h / 2) * imagemOriginal.height;
        double x2 = (cx + w / 2) * imagemOriginal.width;
        double y2 = (cy + h / 2) * imagemOriginal.height;

        caixas.add(Rect.fromLTRB(x1, y1, x2, y2)); 
        pontuacoes.add(pontuacao);               
        idsClasses.add(0);                       
      }
    }

    List<int> resultadoNMS = _naoMaximaSupressao(caixas, pontuacoes, limiarIoU);

    for (int indice in resultadoNMS) { 
      deteccoes.add(
        ResultadoDeteccao( 
          caixa: caixas[indice], 
          pontuacao: pontuacoes[indice],
          rotulo: rotulos[idsClasses[indice]], 
        ),
      );
    }

    return deteccoes;
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

      indices = List.from(indices.where((idx) => !suprimir.contains(indices.indexOf(idx))));
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
    _interpretador?.close(); 
    _interpretador = null;
    print('ServicoDetector: Modelo TFLite fechado.');
  }
}