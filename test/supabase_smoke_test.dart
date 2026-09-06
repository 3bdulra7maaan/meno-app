import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:meno/main.dart';

void main() {
  const url = String.fromEnvironment('SUPABASE_URL');
  const key = String.fromEnvironment('SUPABASE_ANON_KEY');

  test(
    'public feed and anonymous authentication reach Supabase',
    () async {
      final client = SupabaseClient(normalizeSupabaseUrl(url), key);
      final rows = await client
          .from('questions')
          .select('id, status')
          .eq('status', 'approved')
          .limit(1);
      expect(rows, isA<List<dynamic>>());

      final auth = await client.auth.signInAnonymously();
      expect(auth.user, isNotNull);
      await client.auth.signOut();
    },
    skip: url.isEmpty || key.isEmpty,
  );
}
