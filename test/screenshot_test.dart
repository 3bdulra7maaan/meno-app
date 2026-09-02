import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meno/data/in_memory_question_repository.dart';
import 'package:meno/data/question_repository.dart';
import 'package:meno/main.dart';
import 'package:meno/models/question.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  Future<void> capture(GlobalKey key, String name) async {
    final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final directory = Directory('build/screenshots')..createSync(recursive: true);
    await File('${directory.path}/$name.png').writeAsBytes(data!.buffer.asUint8List());
  }

  testWidgets('captures home', (tester) async {
    final key = GlobalKey();
    await pumpPhone(tester, InMemoryQuestionRepository(), key);
    await tester.pumpAndSettle();
    await capture(key, 'home');
  });

  testWidgets('captures search and categories', (tester) async {
    final key = GlobalKey();
    await pumpPhone(tester, InMemoryQuestionRepository(), key);
    await tester.pumpAndSettle();
    await tester.tap(find.text('بحث'));
    await tester.pumpAndSettle();
    await capture(key, 'search-categories');
  });

  testWidgets('captures ask question', (tester) async {
    final key = GlobalKey();
    await pumpPhone(tester, InMemoryQuestionRepository(), key);
    await tester.pumpAndSettle();
    await tester.tap(find.text('اسأل').first);
    await tester.pumpAndSettle();
    await capture(key, 'ask-question');
  });

  testWidgets('captures question details and answers', (tester) async {
    final key = GlobalKey();
    await pumpPhone(tester, InMemoryQuestionRepository(), key);
    await tester.pumpAndSettle();
    await tester.tap(find.text('أفضل طريقة للتحويل من قطر للسودان شنو؟'));
    await tester.pumpAndSettle();
    await capture(key, 'question-details');
    await tester.drag(find.byType(ListView).last, const Offset(0, -260));
    await tester.pumpAndSettle();
    await capture(key, 'answers');
  });

  testWidgets('captures empty state', (tester) async {
    final key = GlobalKey();
    await pumpPhone(tester, _StateRepository(Future.value(const [])), key);
    await tester.pumpAndSettle();
    await capture(key, 'empty-state');
  });

  testWidgets('captures loading state', (tester) async {
    final key = GlobalKey();
    await pumpPhone(tester, _StateRepository(Completer<List<Question>>().future), key);
    await tester.pump(const Duration(milliseconds: 250));
    await capture(key, 'loading-state');
  });

  testWidgets('captures error state', (tester) async {
    final key = GlobalKey();
    await pumpPhone(tester, _StateRepository(Future.error(Exception('offline'))), key);
    await tester.pumpAndSettle();
    await capture(key, 'error-state');
  });
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
