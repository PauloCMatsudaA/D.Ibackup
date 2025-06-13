import 'package:flutter/material.dart';

class ResultadoDeteccao {
  final Rect caixa;       
  final double pontuacao; 
  final String rotulo;    

  ResultadoDeteccao({
    required this.caixa,
    required this.pontuacao,
    required this.rotulo,
  });

  @override
  String toString() {
    return 'ResultadoDeteccao(rotulo: $rotulo, pontuacao: ${pontuacao.toStringAsFixed(2)})';
  }
}