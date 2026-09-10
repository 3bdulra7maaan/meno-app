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
    expect(dashboard, contains('signInWithPassword'));
    expect(dashboard, contains('answer_reports'));
    expect(dashboard, contains('blocked_words'));
    expect(dashboard, contains('home_banners'));
    expect(dashboard, contains('data-view="reports"'));
    expect(dashboard, contains('data-view="answers"'));
    expect(dashboard, contains('banner-image-file'));
    expect(dashboard, contains('banner-upload-progress'));
    expect(dashboard, contains('banner-dropzone'));
    expect(dashboard, contains('إضافة بنر جديد'));
    expect(dashboard, contains('النسبة المفضلة 16:9'));
    expect(dashboard, contains('banner-target-type'));
    expect(dashboard, contains('meno-wordmark-on-dark.png'));
    expect(dashboard, contains('[hidden]{display:none!important}'));
    expect(dashboard, contains('storage/v1/object/home-banners'));
    expect(dashboard, contains('xhr.upload.onprogress'));
    expect(dashboard, contains('target_type'));
    expect(dashboard.toLowerCase(), isNot(contains('service_role')));
  });

  test('v1.2 banner storage is public-read and admin-write only', () {
    final sql = File(
      'supabase/migrations/202609080001_meno_v12_banner_storage.sql',
    ).readAsStringSync();

    expect(sql, isNot(contains('service_role')));
    expect(sql, isNot(contains('drop table')));
    expect(sql, contains("'home-banners'"));
    expect(sql, contains('public.is_meno_admin()'));
    expect(sql, contains('(storage.foldername(name))[1] = auth.uid()::text'));
    expect(sql, contains("target_type in ('none', 'internal', 'external')"));
  });

  test('migration enforces admin RLS and privacy-minimal analytics', () {
    final sql = File('supabase/migrations/202609030001_admin_analytics.sql')
        .readAsStringSync();

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
