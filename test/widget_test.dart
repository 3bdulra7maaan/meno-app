import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:meno/data/in_memory_question_repository.dart';
import 'package:meno/main.dart';
import 'package:meno/models/question.dart';

void main() {
  testWidgets('shows the Arabic-first home feed', (tester) async {
    await tester.pumpWidget(MenoApp(repository: InMemoryQuestionRepository()));
    await tester.pumpAndSettle();

    expect(find.text('Meno'), findsOneWidget);
    expect(find.text('اسأل زول جرّب'), findsOneWidget);
    expect(find.text('اسأل'), findsNWidgets(2));
    expect(
      Theme.of(tester.element(find.text('Meno')))
          .textTheme
          .bodyMedium
          ?.fontFamily,
      'Almarai',
    );

    for (final asset in [
      'assets/fonts/Almarai-Light.ttf',
      'assets/fonts/Almarai-Regular.ttf',
      'assets/fonts/Almarai-Bold.ttf',
      'assets/fonts/Almarai-ExtraBold.ttf',
    ]) {
      expect((await rootBundle.load(asset)).lengthInBytes, greaterThan(0));
    }
  });

  test('new questions stay pending until moderation', () async {
    final repository = InMemoryQuestionRepository();
    final question = await repository.submitQuestion(
      title: 'سؤال جديد للمراجعة',
      body: 'تفاصيل السؤال الجديد',
      category: 'الخدمات',
      anonymous: true,
    );

    expect(question.status, QuestionStatus.pending);
    expect(question.author, 'مجهول');
  });

  test('helpful vote returns the updated state and count', () async {
    final repository = InMemoryQuestionRepository();
    final questions = await repository.approvedQuestions();
    final answer = questions.first.answers.first;
    final before = answer.helpfulCount;

    final result = await repository.toggleHelpful(
      questionId: questions.first.id,
      answerId: answer.id,
    );

    expect(result.isHelpful, isTrue);
    expect(result.helpfulCount, before + 1);
  });

  test('formats Arabic answer counts', () {
    expect(answerCountLabel(0), 'لا توجد إجابات');
    expect(answerCountLabel(1), 'إجابة واحدة');
    expect(answerCountLabel(2), 'إجابتان');
    expect(answerCountLabel(3), '3 إجابات');
    expect(answerCountLabel(10), '10 إجابات');
    expect(answerCountLabel(11), '11 إجابة');
    expect(answerCountLabel(125), '125 إجابة');
  });

  testWidgets('Search finds Arabic title/body/category and clears the field', (
    tester,
  ) async {
    await tester.pumpWidget(MenoApp(repository: InMemoryQuestionRepository()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('بحث'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('search-field')), 'تحويل');
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
    expect(find.text('أفضل طريقة للتحويل من قطر للسودان شنو؟'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('search-field')), 'وصل');
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
    expect(find.text('ما لقينا نتيجة مطابقة'), findsOneWidget);

    await tester.tap(find.text('امسح البحث'));
    await tester.pumpAndSettle();
    final field = tester.widget<TextField>(
      find.byKey(const Key('search-field')),
    );
    expect(field.controller!.text, isEmpty);
    expect(find.text('أفضل طريقة للتحويل من قطر للسودان شنو؟'), findsOneWidget);
  });

  testWidgets('أسئلتي displays private status and only published opens', (
    tester,
  ) async {
    final repository = InMemoryQuestionRepository();
    await repository.submitQuestion(
      title: 'سؤال خاص قيد المراجعة',
      body: 'تفاصيل خاصة لا تظهر في الخلاصة العامة',
      category: 'الخدمات',
      anonymous: true,
    );
    await tester.pumpWidget(MenoApp(repository: repository));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('my-questions-action')));
    await tester.pumpAndSettle();
    expect(find.text('قيد المراجعة'), findsOneWidget);
    expect(find.text('سؤال خاص قيد المراجعة'), findsOneWidget);
    await tester.tap(find.text('سؤال خاص قيد المراجعة'));
    await tester.pumpAndSettle();
    expect(find.text('أسئلتي'), findsOneWidget);
  });

  testWidgets('published question in أسئلتي opens normal details', (
    tester,
  ) async {
    await tester.pumpWidget(MenoApp(repository: _ApprovedOwnerRepository()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('my-questions-action')));
    await tester.pumpAndSettle();

    expect(find.text('تم النشر'), findsOneWidget);
    await tester.tap(find.text('أفضل طريقة للتحويل من قطر للسودان شنو؟'));
    await tester.pumpAndSettle();

    expect(find.text('السؤال'), findsOneWidget);
    expect(find.text('إجابة واحدة'), findsOneWidget);
  });

  test('maps all moderation statuses to approved Arabic wording', () {
    expect(questionStatusLabel(QuestionStatus.pending), 'قيد المراجعة');
    expect(questionStatusLabel(QuestionStatus.approved), 'تم النشر');
    expect(questionStatusLabel(QuestionStatus.rejected), 'لم يتم النشر');
  });
}

class _ApprovedOwnerRepository extends InMemoryQuestionRepository {
  @override
  Future<List<Question>> currentUserQuestions() async => [
        (await approvedQuestions()).first,
      ];
}
