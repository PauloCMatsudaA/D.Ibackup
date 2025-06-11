import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img_lib;
import 'dart:io';

class UtilImagens { 
  static img_lib.Image? converterImagemCamera(CameraImage imagemCamera) {
    if (imagemCamera.format.group == ImageFormatGroup.yuv420) {
      return _converterYUV420ParaImagem(imagemCamera); 
    } else if (imagemCamera.format.group == ImageFormatGroup.bgra8888) {
      return img_lib.Image.fromBytes(
        width: imagemCamera.width,
        height: imagemCamera.height,
        bytes: imagemCamera.planes[0].bytes.buffer,
        format: img_lib.Format.uint8,
);
    }
    return null;
  }

  static img_lib.Image _converterYUV420ParaImagem(CameraImage imagemCamera) { 
    final int largura = imagemCamera.width; 
    final int altura = imagemCamera.height;  
    final Uint8List bufferY = imagemCamera.planes[0].bytes;
    final Uint8List bufferU = imagemCamera.planes[1].bytes; 
    final Uint8List bufferV = imagemCamera.planes[2].bytes; 

    final int strideLinhaY = imagemCamera.planes[0].bytesPerRow; 
    final int strideLinhaUV = imagemCamera.planes[1].bytesPerRow; 
    final int stridePixelUV = imagemCamera.planes[1].bytesPerPixel!; 

    final img_lib.Image imagem = img_lib.Image(width: largura, height: altura); 

    for (int h = 0; h < altura; h++) {
      for (int w = 0; w < largura; w++) {
        final int indiceY = h * strideLinhaY + w; 
        final int indiceU = (h ~/ 2) * strideLinhaUV + (w ~/ 2) * stridePixelUV;
        final int indiceV = (h ~/ 2) * strideLinhaUV + (w ~/ 2) * stridePixelUV; 
        final int Y = bufferY[indiceY];
        final int U = bufferU[indiceU] - 128;
        final int V = bufferV[indiceV] - 128;

        int R = (Y + V * 1.370705).round().clamp(0, 255);
        int G = (Y - U * 0.337633 - V * 0.698001).round().clamp(0, 255);
        int B = (Y + U * 1.732446).round().clamp(0, 255);

        imagem.setPixelRgb(w, h, R, G, B);
      }
    }
    return imagem;
  }
}