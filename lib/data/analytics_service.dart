import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService instance = AnalyticsService._();

  SupabaseClient? _client;
  final String _sessionId = _newSessionId();

  void configure(SupabaseClient client) => _client = client;

  Future<void> track(
    String eventName, {
    String? category,
    String? entityId,
  }) async {
    final client = _client;
    if (client == null) return;
    try {
      await client.from('analytics_events').insert({
        'event_name': eventName,
        'session_id': _sessionId,
        'user_id': client.auth.currentUser?.id,
        if (category != null) 'category': category,
        if (entityId != null) 'entity_id': entityId,
      });
    } catch (_) {
      // Analytics must never block the core product flow.
    }
  }

  static String _newSessionId() {
    final random = Random.secure();
    final suffix = List.generate(
      4,
      (_) => random.nextInt(1 << 32).toRadixString(16).padLeft(8, '0'),
    ).join();
    return 's-${DateTime.now().microsecondsSinceEpoch}-$suffix';
  }
}
