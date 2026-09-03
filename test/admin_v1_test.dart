import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('admin dashboard ships without privileged credentials', () {
    final files = [
      File('admin/index.html'),
      File('admin/app.js'),
      File('admin/config.example.js'),
      File('admin/styles.css'),
    ];
    for (final file in files) {
      expect(file.existsSync(), isTrue, reason: '${file.path} must exist');
    }

    final dashboard = files.map((file) => file.readAsStringSync()).join('\n');
    expect(dashboard, contains('is_meno_admin'));
    expect(dashboard, contains("signInWithPassword"));
    expect(dashboard.toLowerCase(), isNot(contains('service_role')));
  });

  test('migration enforces admin RLS and privacy-minimal analytics', () {
    final sql = File(
      'supabase/migrations/202609030001_admin_analytics.sql',
    ).readAsStringSync();

    expect(sql, contains('enable row level security'));
    expect(sql, contains('public.is_meno_admin()'));
    expect(sql, contains('is_hidden = false'));
    expect(sql, contains('user_id is null or user_id = auth.uid()'));
    expect(sql, contains('admin_dashboard_metrics'));
    for (final event in [
      'app_open',
      'question_view',
      'search',
      'category_selected',
      'question_submitted',
      'answer_submitted',
      'helpful_vote',
    ]) {
      expect(sql, contains("'$event'"));
    }
  });
}
