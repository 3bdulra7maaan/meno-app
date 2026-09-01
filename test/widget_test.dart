import 'package:flutter_test/flutter_test.dart';
import 'package:meno/data/in_memory_question_repository.dart';
import 'package:meno/main.dart';
import 'package:meno/models/question.dart';

void main() {
  testWidgets('shows the Arabic-first home feed', (tester) async {
    await tester.pumpWidget(MenoApp(repository: InMemoryQuestionRepository()));
    await tester.pumpAndSettle();

    expect(find.text('Meno'), findsOneWidget);
    expect(find.text('اسأل زول جرّب'), findsOneWidget);
    expect(find.text('اسأل'), findsOneWidget);
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
}
