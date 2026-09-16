import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:meno/main.dart';

void main() {
  const url = String.fromEnvironment('SUPABASE_URL');
  const key = String.fromEnvironment('SUPABASE_ANON_KEY');

  const runAuthWriteSmoke = bool.fromEnvironment('RUN_AUTH_WRITE_SMOKE');

  test('paged approved feed reaches Supabase without writing data', () async {
    final client = SupabaseClient(normalizeSupabaseUrl(url), key);
    final rows = await client.rpc('approved_question_page', params: {
      'search_input': '',
      'category_input': null,
      'cursor_created_at': null,
      'cursor_id': null,
      'page_size': 1,
    });
    expect(rows, isA<List<dynamic>>());
    expect((rows as List).length, lessThanOrEqualTo(2));
    for (final row in rows) {
      expect(row['status'], 'approved');
      expect(row, contains('answer_count'));
      expect(row, isNot(contains('answers')));
    }
  }, skip: url.isEmpty || key.isEmpty);

  test('optional anonymous sign-in reaches Supabase', () async {
    final client = SupabaseClient(normalizeSupabaseUrl(url), key);
    final auth = await client.auth.signInAnonymously();
    expect(auth.user, isNotNull);
    await client.auth.signOut();
  }, skip: url.isEmpty || key.isEmpty || !runAuthWriteSmoke);
}
