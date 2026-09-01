import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/question.dart';
import 'question_repository.dart';

class SupabaseQuestionRepository implements QuestionRepository {
  SupabaseQuestionRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Question>> approvedQuestions() async {
    final rows = await _client
        .from('questions')
        .select('*, answers(*, helpful_votes(user_id))')
        .eq('status', 'approved')
        .order('created_at', ascending: false);
    return rows.map(_questionFromMap).toList();
  }

  @override
  Future<Question> submitQuestion({
    required String title,
    required String body,
    required String category,
    required bool anonymous,
  }) async {
    final userId = await _ensureAnonymousSession();
    final row = await _client
        .from('questions')
        .insert({
          'user_id': userId,
          'author_name': anonymous ? null : 'مستخدم مينو',
          'title': title,
          'body': body,
          'category': category,
          'is_anonymous': anonymous,
          'status': 'pending',
        })
        .select()
        .single();
    return _questionFromMap(row);
  }

  @override
  Future<Answer> submitAnswer({
    required String questionId,
    required String body,
  }) async {
    final userId = await _ensureAnonymousSession();
    final row = await _client
        .from('answers')
        .insert({
          'question_id': questionId,
          'user_id': userId,
          'author_name': 'مستخدم مينو',
          'body': body,
        })
        .select()
        .single();
    return _answerFromMap(row);
  }

  @override
  Future<HelpfulVoteResult> toggleHelpful({
    required String questionId,
    required String answerId,
  }) async {
    await _ensureAnonymousSession();
    final row = await _client
        .rpc(
          'toggle_helpful',
          params: {'answer_id_input': answerId},
        )
        .single();
    return HelpfulVoteResult(
      isHelpful: row['is_helpful'] as bool,
      helpfulCount: row['helpful_count'] as int,
    );
  }

  Future<String> _ensureAnonymousSession() async {
    final existingUser = _client.auth.currentUser;
    if (existingUser != null) return existingUser.id;

    final response = await _client.auth.signInAnonymously();
    final user = response.user;
    if (user == null) {
      throw const AuthException('تعذر إنشاء جلسة آمنة. حاول مرة أخرى.');
    }
    return user.id;
  }

  Question _questionFromMap(Map<String, dynamic> row) {
    final answerRows = (row['answers'] as List?) ?? const [];
    final answers = answerRows
        .map((answer) => _answerFromMap(answer as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return Question(
      id: row['id'].toString(),
      title: row['title'] as String,
      body: row['body'] as String,
      category: row['category'] as String,
      author: row['is_anonymous'] == true
          ? 'مجهول'
          : (row['author_name'] as String? ?? 'مستخدم مينو'),
      createdAt: DateTime.parse(row['created_at'] as String),
      status: QuestionStatus.values.byName(row['status'] as String),
      answers: answers,
    );
  }

  Answer _answerFromMap(Map<String, dynamic> row) {
    final votes = (row['helpful_votes'] as List?) ?? const [];
    return Answer(
      id: row['id'].toString(),
      author: row['author_name'] as String? ?? 'مستخدم مينو',
      body: row['body'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
      helpfulCount: row['helpful_count'] as int? ?? 0,
      isHelpful: votes.isNotEmpty,
    );
  }
}
