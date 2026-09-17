import '../models/question.dart';
import '../models/home_banner.dart';

abstract class QuestionRepository {
  Future<QuestionPage> approvedQuestionsPage({
    String category = 'الكل',
    QuestionCursor? cursor,
    int pageSize = 20,
  }) async =>
      _localPage(
        await approvedQuestions(),
        category: category,
        cursor: cursor,
        pageSize: pageSize,
      );

  Future<QuestionPage> searchApprovedQuestionsPage({
    required String query,
    required String category,
    QuestionCursor? cursor,
    int pageSize = 20,
  }) async =>
      _localPage(
        await searchApprovedQuestions(query: query, category: category),
        category: category,
        cursor: cursor,
        pageSize: pageSize,
      );

  Future<Question> questionDetails(Question summary) async => summary;

  Future<List<Question>> approvedQuestions();

  Future<List<Question>> searchApprovedQuestions({
    required String query,
    required String category,
  });

  Future<List<Question>> currentUserQuestions();

  Future<List<HomeBanner>> activeBanners();

  Future<Question> submitQuestion({
    required String title,
    required String body,
    required String category,
    required bool anonymous,
  });

  Future<Answer> submitAnswer({
    required String questionId,
    required String body,
  });

  Future<HelpfulVoteResult> toggleHelpful({
    required String questionId,
    required String answerId,
  });

  Future<bool> reportAnswer({required String answerId, required String reason});
}

QuestionPage _localPage(
  List<Question> questions, {
  required String category,
  required QuestionCursor? cursor,
  required int pageSize,
}) {
  final sorted = questions
      .where((q) => q.status == QuestionStatus.approved)
      .where((q) => category == 'الكل' || q.category == category)
      .toList()
    ..sort((a, b) {
      final dateOrder = b.createdAt.compareTo(a.createdAt);
      return dateOrder != 0 ? dateOrder : b.id.compareTo(a.id);
    });
  final afterCursor = sorted.where((q) =>
      cursor == null ||
      q.createdAt.isBefore(cursor.createdAt) ||
      (q.createdAt.isAtSameMomentAs(cursor.createdAt) &&
          q.id.compareTo(cursor.id) < 0));
  final limit = pageSize.clamp(1, 50).toInt();
  final chunk = afterCursor.take(limit + 1).toList();
  final items = chunk.take(limit).toList();
  final last = items.isEmpty ? null : items.last;
  return QuestionPage(
    items: items,
    nextCursor: chunk.length > limit && last != null
        ? QuestionCursor(createdAt: last.createdAt, id: last.id)
        : null,
  );
}
