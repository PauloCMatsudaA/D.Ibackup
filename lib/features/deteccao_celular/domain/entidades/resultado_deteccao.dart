import 'dart:ui';

class ResultadoDeteccao { 
  final Rect caixa;    
  final double pontuacao; 
  final String rotulo;   

  ResultadoDeteccao({
    required this.caixa,
    required this.pontuacao,
    required this.rotulo,
  });
}