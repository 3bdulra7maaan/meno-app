import '../models/question.dart';

abstract class QuestionRepository {
  Future<List<Question>> approvedQuestions();

  Future<List<Question>> searchApprovedQuestions({
    required String query,
    required String category,
  });

  Future<List<Question>> currentUserQuestions();

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
}
