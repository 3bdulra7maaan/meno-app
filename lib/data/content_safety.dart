const blockedContentMessage =
    'يرجى تعديل النص، بعض الكلمات المستخدمة غير مسموح بها في Meno.';

class BlockedContentException implements Exception {
  const BlockedContentException();

  @override
  String toString() => blockedContentMessage;
}

String normalizeModerationText(String value) => value
    .toLowerCase()
    .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06ED\u0640]'), '')
    .replaceAll(RegExp(r'[أإآٱ]'), 'ا')
    .replaceAllMapped(
      RegExp(r'([ء-ي])\1{2,}'),
      (match) => match.group(1)!,
    )
    .replaceAll(RegExp(r'[^a-z0-9ء-ي]+'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

bool containsBlockedPhrase(String text, Iterable<String> blockedWords) {
  final normalizedText = ' ${normalizeModerationText(text)} ';
  return blockedWords.any((word) {
    final normalizedWord = normalizeModerationText(word);
    return normalizedWord.isNotEmpty &&
        normalizedText.contains(' $normalizedWord ');
  });
}
