import '../models/home_banner.dart';
import '../models/question.dart';
import 'content_safety.dart';
import 'question_repository.dart';
import 'question_search.dart';

class InMemoryQuestionRepository implements QuestionRepository {
  InMemoryQuestionRepository({
    List<HomeBanner> banners = const [],
    Set<String> blockedWords = const {},
  })  : _banners = List.of(banners),
        _blockedWords = Set.of(blockedWords);

  final List<HomeBanner> _banners;
  final Set<String> _blockedWords;
  final Set<String> _reports = {};

  final List<Question> _questions = [
    Question(
      id: '1',
      title: 'أفضل طريقة للتحويل من قطر للسودان شنو؟',
      body: 'داير طريقة مجرّبة، سريعة ورسومها معقولة.',
      category: 'البنوك والتحويلات',
      author: 'محمد أحمد',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      status: QuestionStatus.approved,
      answers: [
        Answer(
          id: 'a1',
          author: 'سارة عثمان',
          body:
              'جرّبت التحويل البنكي المباشر الأسبوع الفات، وصل في نفس اليوم. اتأكد من اسم المستفيد مطابق للحساب.',
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          helpfulCount: 14,
          answerType: 'تجربة شخصية',
        ),
      ],
    ),
    Question(
      id: '2',
      title: 'منو جرّب استخراج تأشيرة زيارة للسعودية قريب؟',
      body: 'محتاج أعرف الأوراق المطلوبة والزمن المتوقع.',
      category: 'السفر والتأشيرات',
      author: 'مجهول',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      status: QuestionStatus.approved,
      answers: [
        Answer(
          id: 'a2',
          author: 'أحمد الطيب',
          body:
              'قدمت إلكتروني ومعاي جواز ساري وصورة شخصية وحجز مبدئي. الرد وصلني بعد أربعة أيام.',
          createdAt: DateTime.now().subtract(const Duration(hours: 18)),
          helpfulCount: 8,
          answerType: 'تجربة شخصية',
        ),
        Answer(
          id: 'a3',
          author: 'منى',
          body:
              'خلي الاسم في الطلب مطابق للجواز حرفياً عشان ما تتأخر المعاملة.',
          createdAt: DateTime.now().subtract(const Duration(hours: 12)),
          helpfulCount: 5,
          answerType: 'معلومة أعرفها',
        ),
      ],
    ),
    Question(
      id: '3',
      title: 'شنو أحسن باقة إنترنت للاستخدام اليومي؟',
      body: 'استخدامي واتساب، مكالمات وفيديو خفيف.',
      category: 'الاتصالات والإنترنت',
      author: 'ريم',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      status: QuestionStatus.approved,
    ),
  ];

  @override
  Future<List<Question>> approvedQuestions() async => _questions
      .where((question) => question.status == QuestionStatus.approved)
      .toList();

  @override
  Future<List<Question>> searchApprovedQuestions({
    required String query,
    required String category,
  }) async =>
      filterApprovedQuestions(_questions, query: query, category: category);

  @override
  Future<List<Question>> currentUserQuestions() async => List.unmodifiable(
        _questions.where(
          (question) =>
              question.id != '1' && question.id != '2' && question.id != '3',
        ),
      );

  @override
  Future<List<HomeBanner>> activeBanners() async => List.unmodifiable(
        _banners.where((banner) {
          final now = DateTime.now();
          return banner.enabled &&
              (banner.startAt == null || !banner.startAt!.isAfter(now)) &&
              (banner.endAt == null || banner.endAt!.isAfter(now));
        }).toList()
          ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder)),
      );

  @override
  Future<Question> submitQuestion({
    required String title,
    required String body,
    required String category,
    required bool anonymous,
  }) async {
    _ensureAllowed('$title $body');
    final question = Question(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      body: body,
      category: category,
      author: anonymous ? 'مجهول' : 'مستخدم مينو',
      createdAt: DateTime.now(),
      status: QuestionStatus.pending,
    );
    _questions.insert(0, question);
    return question;
  }

  @override
  Future<Answer> submitAnswer({
    required String questionId,
    required String body,
  }) async {
    _ensureAllowed(body);
    final answer = Answer(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      author: 'مستخدم مينو',
      body: body,
      createdAt: DateTime.now(),
    );
    _questions
        .firstWhere((question) => question.id == questionId)
        .answers
        .add(answer);
    return answer;
  }

  @override
  Future<HelpfulVoteResult> toggleHelpful({
    required String questionId,
    required String answerId,
  }) async {
    final answer = _questions
        .firstWhere((question) => question.id == questionId)
        .answers
        .firstWhere((item) => item.id == answerId);
    answer.isHelpful = !answer.isHelpful;
    answer.helpfulCount += answer.isHelpful ? 1 : -1;
    return HelpfulVoteResult(
      isHelpful: answer.isHelpful,
      helpfulCount: answer.helpfulCount,
    );
  }

  @override
  Future<bool> reportAnswer({
    required String answerId,
    required String reason,
  }) async =>
      _reports.add(answerId);

  void _ensureAllowed(String text) {
    if (containsBlockedPhrase(text, _blockedWords)) {
      throw const BlockedContentException();
    }
  }
}
