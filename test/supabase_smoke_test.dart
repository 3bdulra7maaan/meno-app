import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  const url = String.fromEnvironment('SUPABASE_URL');
  const key = String.fromEnvironment('SUPABASE_ANON_KEY');

  test(
    'public feed and anonymous authentication reach Supabase',
    () async {
      await Supabase.initialize(url: url, publishableKey: key);
      final rows = await Supabase.instance.client
          .from('questions')
          .select('id, status')
          .eq('status', 'approved')
          .limit(1);
      expect(rows, isA<List<dynamic>>());

      final auth = await Supabase.instance.client.auth.signInAnonymously();
      expect(auth.user, isNotNull);
      await Supabase.instance.client.auth.signOut();
    },
    skip: url.isEmpty || key.isEmpty,
  );
}
