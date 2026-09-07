import 'package:flutter_test/flutter_test.dart';
import 'package:meno/data/content_safety.dart';
import 'package:meno/data/in_memory_question_repository.dart';

void main() {
  test('normalizes Arabic diacritics, alef forms and simple obfuscation', () {
    expect(normalizeModerationText('آلـكَلِمَة!!!'), 'الكلمة');
    expect(normalizeModerationText('كــلــمة سيئة'), 'كلمة سيئة');
    expect(normalizeModerationText('كلممممة سيئة'), 'كلمة سيئة');
    expect(containsBlockedPhrase('هذه كلممممة سيئة', {'كلمة سيئة'}), isTrue);
  });

  test('matches whole blocked phrases without substring false positives', () {
    expect(containsBlockedPhrase('نص ممنوع هنا', {'ممنوع'}), isTrue);
    expect(containsBlockedPhrase('هذا غيرممنوع تماماً', {'ممنوع'}), isFalse);
  });

  test('questions and answers reject blocked text with friendly message',
      () async {
    final repository = InMemoryQuestionRepository(blockedWords: {'محتوى سيئ'});

    await expectLater(
      repository.submitQuestion(
        title: 'هذا محتوى سيئ',
        body: 'تفاصيل',
        category: 'أخرى',
        anonymous: true,
      ),
      throwsA(
        isA<BlockedContentException>().having(
          (error) => error.toString(),
          'message',
          blockedContentMessage,
        ),
      ),
    );

    final question = (await repository.approvedQuestions()).first;
    await expectLater(
      repository.submitAnswer(questionId: question.id, body: 'محتوى سيئ'),
      throwsA(isA<BlockedContentException>()),
    );
  });

  test('duplicate answer reports are prevented for one identity', () async {
    final repository = InMemoryQuestionRepository();
    expect(
      await repository.reportAnswer(answerId: 'a1', reason: 'spam'),
      isTrue,
    );
    expect(
      await repository.reportAnswer(answerId: 'a1', reason: 'other'),
      isFalse,
    );
  });
}
