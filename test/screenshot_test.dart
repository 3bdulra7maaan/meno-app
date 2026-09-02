import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meno/data/in_memory_question_repository.dart';
import 'package:meno/data/question_repository.dart';
import 'package:meno/main.dart';
import 'package:meno/models/question.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const enabled = bool.fromEnvironment('CAPTURE_SCREENSHOTS');
  const almaraiAssets = [
    'assets/fonts/Almarai-Light.ttf',
    'assets/fonts/Almarai-Regular.ttf',
    'assets/fonts/Almarai-Bold.ttf',
    'assets/fonts/Almarai-ExtraBold.ttf',
  ];

  setUpAll(() async {
    final loader = FontLoader('Almarai');
    for (final asset in almaraiAssets) {
      loader.addFont(rootBundle.load(asset));
    }
    await loader.load();
  });

  Future<void> pumpPhone(
    WidgetTester tester,
    QuestionRepository repository,
    GlobalKey boundaryKey,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundaryKey,
        child: MenoApp(repository: repository),
      ),
    );
  }

  Future<void> capture(WidgetTester tester, GlobalKey key, String name) async {
    await tester.runAsync(() async {
      final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final directory = Directory('build/screenshots')..createSync(recursive: true);
      await File('${directory.path}/$name.png').writeAsBytes(data!.buffer.asUint8List());
    });
  }

  testWidgets('captures home', (tester) async {
    final key = GlobalKey();
    await pumpPhone(tester, InMemoryQuestionRepository(), key);
    await tester.pumpAndSettle();

    final tagline = find.text('اسأل زول جرّب');
    expect(tagline, findsOneWidget);
    expect(
      Theme.of(tester.element(tagline)).textTheme.bodyMedium?.fontFamily,
      'Almarai',
    );
    await _expectArabicGlyphsAreNotTofu();

    await capture(tester, key, 'home');
  }, skip: !enabled);

  testWidgets('captures search and categories', (tester) async {
    final key = GlobalKey();
    await pumpPhone(tester, InMemoryQuestionRepository(), key);
    await tester.pumpAndSettle();
    await tester.tap(find.text('بحث'));
    await tester.pumpAndSettle();
    await capture(tester, key, 'search-categories');
  }, skip: !enabled);

  testWidgets('captures ask question', (tester) async {
    final key = GlobalKey();
    await pumpPhone(tester, InMemoryQuestionRepository(), key);
    await tester.pumpAndSettle();
    await tester.tap(find.text('اسأل').first);
    await tester.pumpAndSettle();
    await capture(tester, key, 'ask-question');
  }, skip: !enabled);

  testWidgets('captures question details and answers', (tester) async {
    final key = GlobalKey();
    await pumpPhone(tester, InMemoryQuestionRepository(), key);
    await tester.pumpAndSettle();
    await tester.tap(find.text('أفضل طريقة للتحويل من قطر للسودان شنو؟'));
    await tester.pumpAndSettle();
    await capture(tester, key, 'question-details');
    await tester.drag(find.byType(ListView).last, const Offset(0, -260));
    await tester.pumpAndSettle();
    await capture(tester, key, 'answers');
  }, skip: !enabled);

  testWidgets('captures empty state', (tester) async {
    final key = GlobalKey();
    await pumpPhone(tester, _StateRepository(Future.value(const [])), key);
    await tester.pumpAndSettle();
    await capture(tester, key, 'empty-state');
  }, skip: !enabled);

  testWidgets('captures loading state', (tester) async {
    final key = GlobalKey();
    await pumpPhone(tester, _StateRepository(Completer<List<Question>>().future), key);
    await tester.pump(const Duration(milliseconds: 250));
    await capture(tester, key, 'loading-state');
  }, skip: !enabled);

  testWidgets('captures error state', (tester) async {
    final key = GlobalKey();
    await pumpPhone(
      tester,
      _StateRepository(Future<List<Question>>.delayed(const Duration(milliseconds: 1), () => throw Exception('offline'))),
      key,
    );
    await tester.pumpAndSettle();
    await capture(tester, key, 'error-state');
  }, skip: !enabled);
}

Future<void> _expectArabicGlyphsAreNotTofu() async {
  const arabic = 'اسأل زول جرب';
  final tofu = arabic.runes
      .map((rune) => rune == 0x20 ? ' ' : '□')
      .join();
  final arabicPixels = await _renderText(arabic);
  final tofuPixels = await _renderText(tofu);

  var differentPixels = 0;
  for (var i = 0; i < arabicPixels.length; i += 4) {
    if (arabicPixels[i] != tofuPixels[i] ||
        arabicPixels[i + 1] != tofuPixels[i + 1] ||
        arabicPixels[i + 2] != tofuPixels[i + 2] ||
        arabicPixels[i + 3] != tofuPixels[i + 3]) {
      differentPixels++;
    }
  }
  expect(
    differentPixels,
    greaterThan(500),
    reason: 'Arabic raster output must differ visibly from missing-glyph boxes.',
  );
}

Future<Uint8List> _renderText(String value) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawColor(Colors.white, BlendMode.src);
  final painter = TextPainter(
    text: TextSpan(
      text: value,
      style: const TextStyle(
        fontFamily: 'Almarai',
        fontSize: 34,
        fontWeight: FontWeight.w700,
        color: Colors.black,
      ),
    ),
    textDirection: TextDirection.rtl,
  )..layout(maxWidth: 360);
  painter.paint(canvas, const Offset(12, 16));
  final image = await recorder.endRecording().toImage(390, 80);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  image.dispose();
  return bytes!.buffer.asUint8List();
}

class _StateRepository implements QuestionRepository {
  _StateRepository(this.result);
  final Future<List<Question>> result;

  @override
  Future<List<Question>> approvedQuestions() => result;

  @override
  Future<Question> submitQuestion({required String title, required String body, required String category, required bool anonymous}) => throw UnimplementedError();

  @override
  Future<Answer> submitAnswer({required String questionId, required String body}) => throw UnimplementedError();

  @override
  Future<HelpfulVoteResult> toggleHelpful({required String questionId, required String answerId}) => throw UnimplementedError();
}
