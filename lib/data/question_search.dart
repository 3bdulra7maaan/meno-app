import '../models/question.dart';

String normalizeArabicSearch(String value) => value
    .toLowerCase()
    .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06ED\u0640]'), '')
    .replaceAll(RegExp(r'[أإآٱ]'), 'ا')
    .replaceAll('ى', 'ي')
    .replaceAll('ؤ', 'و')
    .replaceAll('ئ', 'ي')
    .replaceAll('ة', 'ه')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

List<Question> filterApprovedQuestions(
  Iterable<Question> questions, {
  String query = '',
  String category = 'الكل',
}) {
  final terms = normalizeArabicSearch(query)
      .split(' ')
      .where((term) => term.isNotEmpty)
      .toList();
  return questions.where((question) {
    if (question.status != QuestionStatus.approved) return false;
    if (category != 'الكل' && question.category != category) return false;
    final searchable = normalizeArabicSearch(
      '${question.title} ${question.body} ${question.category}',
    );
    return terms.every(searchable.contains);
  }).toList();
}
