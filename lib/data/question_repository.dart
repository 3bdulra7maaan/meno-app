import '../models/question.dart';
import '../models/home_banner.dart';

abstract class QuestionRepository {
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
