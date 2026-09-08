import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/home_banner.dart';
import '../models/question.dart';
import 'content_safety.dart';
import 'question_repository.dart';
import 'question_search.dart';

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
  Future<List<Question>> searchApprovedQuestions({
    required String query,
    required String category,
  }) async =>
      filterApprovedQuestions(
        await approvedQuestions(),
        query: query,
        category: category,
      );

  @override
  Future<List<Question>> currentUserQuestions() async {
    final user = _client.auth.currentUser;
    if (user == null) return const [];
    final rows = await _client
        .from('questions')
        .select('*, answers(*, helpful_votes(user_id))')
        .eq('user_id', user.id)
        .order('created_at', ascending: false);
    return rows.map(_questionFromMap).toList();
  }

  @override
  Future<List<HomeBanner>> activeBanners() async {
    final rows = await _client
        .from('home_banners')
        .select()
        .eq('enabled', true)
        .order('display_order')
        .order('created_at');
    return rows.map(_bannerFromMap).toList();
  }

  @override
  Future<Question> submitQuestion({
    required String title,
    required String body,
    required String category,
    required bool anonymous,
  }) async {
    await _ensureAllowed('$title $body');
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
    await _ensureAllowed(body);
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
        .rpc('toggle_helpful', params: {'answer_id_input': answerId}).single();
    return HelpfulVoteResult(
      isHelpful: row['is_helpful'] as bool,
      helpfulCount: row['helpful_count'] as int,
    );
  }

  @override
  Future<bool> reportAnswer({
    required String answerId,
    required String reason,
  }) async {
    await _ensureAnonymousSession();
    final result = await _client.rpc(
      'report_answer',
      params: {'answer_id_input': answerId, 'reason_input': reason},
    );
    return result == true;
  }

  Future<void> _ensureAllowed(String text) async {
    final result = await _client.rpc(
      'is_submission_text_allowed',
      params: {'input_text': text},
    );
    if (result != true) throw const BlockedContentException();
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

  HomeBanner _bannerFromMap(Map<String, dynamic> row) => HomeBanner(
        id: row['id'].toString(),
        imageUrl: row['image_url'] as String,
        title: row['title'] as String,
        shortText: row['short_text'] as String,
        targetUrl: row['target_url'] as String?,
        targetType: switch (row['target_type'] as String? ?? 'none') {
          'internal' => HomeBannerTargetType.internalPage,
          'external' => HomeBannerTargetType.externalUrl,
          _ => HomeBannerTargetType.none,
        },
        type: HomeBannerType.values.byName(row['type'] as String),
        displayOrder: row['display_order'] as int,
        enabled: row['enabled'] as bool? ?? true,
        startAt: row['start_at'] == null
            ? null
            : DateTime.parse(row['start_at'] as String),
        endAt: row['end_at'] == null
            ? null
            : DateTime.parse(row['end_at'] as String),
      );
}
