import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('generate approved-brand Play assets', () async {
    if (!const bool.fromEnvironment('CAPTURE_STORE_ASSETS')) return;
    final font = FontLoader('Almarai')
      ..addFont(rootBundle.load('assets/fonts/Almarai-ExtraBold.ttf'));
    await font.load();
    Future<void> render(
        String name, int width, int height, bool graphic) async {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawColor(const Color(0xFF121212), BlendMode.src);
      void label(String text, double size, double y, Color color,
          TextDirection direction) {
        final painter = TextPainter(
          text: TextSpan(
              text: text,
              style: TextStyle(
                  fontFamily: 'Almarai',
                  fontWeight: FontWeight.w800,
                  fontSize: size,
                  color: color)),
          textDirection: direction,
        )..layout(maxWidth: width.toDouble());
        painter.paint(canvas, Offset((width - painter.width) / 2, y));
      }

      label('Meno', graphic ? 112 : 108, graphic ? 85 : 175,
          const Color(0xFFD9A752), TextDirection.ltr);
      if (graphic) {
        label('اسأل زول جرّب', 62, 260, Colors.white, TextDirection.rtl);
      }
      final picture = recorder.endRecording();
      final image = await picture.toImage(width, height);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final directory = Directory('build/store-assets')
        ..createSync(recursive: true);
      await File('${directory.path}/$name.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
      picture.dispose();
    }

    await render('play-icon-512', 512, 512, false);
    await render('feature-graphic-1024x500', 1024, 500, true);
  });
}
