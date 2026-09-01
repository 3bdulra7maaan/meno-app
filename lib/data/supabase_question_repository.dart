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
        .select('*, answers(*)')
        .eq('status', 'approved')
        .order('created_at', ascending: false);
    return (rows as List).map((row) => _questionFromMap(row as Map<String, dynamic>)).toList();
  }

  @override
  Future<Question> submitQuestion({
    required String title,
    required String body,
    required String category,
    required bool anonymous,
  }) async {
    final row = await _client.from('questions').insert({
      'title': title,
      'body': body,
      'category': category,
      'is_anonymous': anonymous,
      'status': 'pending',
    }).select().single();
    return _questionFromMap(row);
  }

  @override
  Future<Answer> submitAnswer({required String questionId, required String body}) async {
    final row = await _client.from('answers').insert({
      'question_id': questionId,
      'body': body,
    }).select().single();
    return _answerFromMap(row);
  }

  @override
  Future<void> toggleHelpful({required String questionId, required String answerId}) async {
    await _client.rpc('toggle_helpful', params: {'answer_id_input': answerId});
  }

  Question _questionFromMap(Map<String, dynamic> row) => Question(
        id: row['id'].toString(),
        title: row['title'] as String,
        body: row['body'] as String,
        category: row['category'] as String,
        author: row['is_anonymous'] == true ? 'مجهول' : (row['author_name'] as String? ?? 'مستخدم مينو'),
        createdAt: DateTime.parse(row['created_at'] as String),
        status: QuestionStatus.values.byName(row['status'] as String),
        answers: ((row['answers'] as List?) ?? [])
            .map((answer) => _answerFromMap(answer as Map<String, dynamic>))
            .toList(),
      );

  Answer _answerFromMap(Map<String, dynamic> row) => Answer(
        id: row['id'].toString(),
        author: row['author_name'] as String? ?? 'مستخدم مينو',
        body: row['body'] as String,
        createdAt: DateTime.parse(row['created_at'] as String),
        helpfulCount: row['helpful_count'] as int? ?? 0,
      );
}
