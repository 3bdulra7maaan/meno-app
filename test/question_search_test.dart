import 'package:flutter_test/flutter_test.dart';
import 'package:meno/data/question_search.dart';
import 'package:meno/models/question.dart';

Question question({
  required String id,
  required String title,
  required String body,
  required String category,
  QuestionStatus status = QuestionStatus.approved,
}) =>
    Question(
      id: id,
      title: title,
      body: body,
      category: category,
      author: 'مجهول',
      createdAt: DateTime(2026),
      status: status,
    );

void main() {
  final questions = [
    question(
      id: 'approved',
      title: 'أفضل طريقة للتحويل من قطر',
      body: 'تجربة سريعة ورسومها معقولة',
      category: 'البنوك والتحويلات',
    ),
    question(
      id: 'pending',
      title: 'سؤال التحويل المعلّق',
      body: 'لا يجب أن يظهر',
      category: 'البنوك والتحويلات',
      status: QuestionStatus.pending,
    ),
  ];

  test('Arabic search normalizes letters, diacritics and partial terms', () {
    expect(
      filterApprovedQuestions(questions, query: 'أَفْضَل تحويل').single.id,
      'approved',
    );
    expect(
      filterApprovedQuestions(questions, query: 'سريع').single.id,
      'approved',
    );
    expect(
      filterApprovedQuestions(questions, query: 'تحويلات').single.id,
      'approved',
    );
  });

  test('search and categories never return unapproved questions', () {
    expect(filterApprovedQuestions(questions, query: 'المعلّق'), isEmpty);
    expect(
      filterApprovedQuestions(
        questions,
        category: 'البنوك والتحويلات',
      ).map((item) => item.id),
      ['approved'],
    );
  });

  test('empty query resets to all approved results', () {
    expect(filterApprovedQuestions(questions).map((item) => item.id), [
      'approved',
    ]);
  });
}
