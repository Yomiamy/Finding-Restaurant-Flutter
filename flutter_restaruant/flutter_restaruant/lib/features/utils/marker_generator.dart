import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MarkerGenerator {
  /// 生成包含數字的聚類圓形圖標
  static Future<BitmapDescriptor> getClusterMarker(
    int clusterSize, {
    Color clusterColor = Colors.redAccent,
    Color textColor = Colors.white,
    double radius = 30.0, // Logical radius
    double devicePixelRatio = 3.0,
  }) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final double size = radius * 2;
    final double scaledSize = size * devicePixelRatio;
    final double scaledRadius = radius * devicePixelRatio;
    
    // 繪製圓形背景
    final Paint paint = Paint()..color = clusterColor;
    canvas.drawCircle(Offset(scaledRadius, scaledRadius), scaledRadius, paint);

    // 繪製外圈邊框 (增加層次感)
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0 * devicePixelRatio;
    canvas.drawCircle(Offset(scaledRadius, scaledRadius), scaledRadius - borderPaint.strokeWidth / 2, borderPaint);

    // 繪製文字
    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    textPainter.text = TextSpan(
      text: clusterSize.toString(),
      style: TextStyle(
        fontSize: scaledRadius * 0.8,
        color: textColor,
        fontWeight: FontWeight.bold,
      ),
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        scaledRadius - textPainter.width / 2,
        scaledRadius - textPainter.height / 2,
      ),
    );

    final ui.Image image = await pictureRecorder.endRecording().toImage(
          scaledSize.toInt(),
          scaledSize.toInt(),
        );
    final data = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.bytes(
      data!.buffer.asUint8List(),
      width: size,
      height: size,
      imagePixelRatio: devicePixelRatio,
    );
  }
}
