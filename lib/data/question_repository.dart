import '../models/question.dart';

abstract class QuestionRepository {
  Future<List<Question>> approvedQuestions();

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

  Future<void> toggleHelpful({
    required String questionId,
    required String answerId,
  });
}
