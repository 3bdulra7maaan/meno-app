enum QuestionStatus { pending, approved, rejected }

class Answer {
  Answer({
    required this.id,
    required this.author,
    required this.body,
    required this.createdAt,
    this.helpfulCount = 0,
    this.isHelpful = false,
  });

  final String id;
  final String author;
  final String body;
  final DateTime createdAt;
  int helpfulCount;
  bool isHelpful;
}

class HelpfulVoteResult {
  const HelpfulVoteResult({
    required this.isHelpful,
    required this.helpfulCount,
  });

  final bool isHelpful;
  final int helpfulCount;
}

class Question {
  Question({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.author,
    required this.createdAt,
    required this.status,
    List<Answer>? answers,
  }) : answers = answers ?? [];

  final String id;
  final String title;
  final String body;
  final String category;
  final String author;
  final DateTime createdAt;
  final QuestionStatus status;
  final List<Answer> answers;
}
