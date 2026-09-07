import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final sql = File('supabase/migrations/202609060001_meno_v11.sql')
      .readAsStringSync()
      .toLowerCase();

  test('v1.1 migration is additive and contains no privileged key', () {
    expect(sql, isNot(contains('drop table')));
    expect(sql, isNot(contains('truncate ')));
    expect(sql, isNot(contains('service_role')));
    expect(sql, contains('create table if not exists public.blocked_words'));
    expect(sql, contains('create table if not exists public.answer_reports'));
    expect(sql, contains('create table if not exists public.home_banners'));
  });

  test('server-side moderation, reporting and RLS are defined', () {
    expect(sql,
        contains('create or replace function public.contains_blocked_content'));
    expect(sql, contains('create or replace function public.report_answer'));
    expect(sql, contains('enable row level security'));
    expect(sql, contains('public.is_meno_admin()'));
    expect(sql, contains('unique(answer_id, reporter_id)'));
    expect(sql, contains('create policy "public reads active banners"'));
  });

  test('audit trigger fix branches before reading table-specific fields', () {
    final fix = File(
      'supabase/migrations/202609070001_fix_moderation_audit_trigger.sql',
    ).readAsStringSync().toLowerCase();

    expect(fix, isNot(contains('drop table')));
    expect(fix, isNot(contains('alter table')));
    expect(fix, contains("if tg_table_name = 'questions' then"));
    expect(fix, contains("elsif tg_table_name = 'answers' then"));
    expect(fix, contains("elsif tg_table_name = 'answer_reports' then"));
    expect(fix, contains('old.status is not distinct from new.status'));
    expect(fix, contains('old.is_hidden is not distinct from new.is_hidden'));
  });
}
