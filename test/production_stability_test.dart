import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meno/main.dart';
import 'package:meno/core/config/backend_config.dart';
import 'package:meno/data/in_memory_question_repository.dart';
import 'package:meno/models/question.dart';

void main() {
  const publicKey = 'sb_publishable_example_key_for_tests';
  const url = 'https://example.supabase.co';

  test('release never silently chooses the in-memory repository', () {
    expect(
      () => resolveBackendConfig(
        url: '',
        publishableKey: '',
        allowInMemory: false,
        isRelease: true,
      ),
      throwsA(isA<StartupConfigurationException>()),
    );
    expect(
      () => resolveBackendConfig(
        url: '',
        publishableKey: '',
        allowInMemory: true,
        isRelease: true,
      ),
      throwsA(isA<StartupConfigurationException>()),
    );
    expect(
      () => resolveBackendConfig(
        url: 'http://example.supabase.co',
        publishableKey: publicKey,
        allowInMemory: false,
        isRelease: true,
      ),
      throwsA(isA<StartupConfigurationException>()),
    );
    expect(
      () => resolveBackendConfig(
        url: url,
        publishableKey: 'sb_secret_fake_private_key_12345',
        allowInMemory: false,
        isRelease: true,
      ),
      throwsA(isA<StartupConfigurationException>()),
    );
  });

  test('development demo mode is explicit and valid backend is selected', () {
    expect(
      resolveBackendConfig(
        url: '',
        publishableKey: '',
        allowInMemory: true,
        isRelease: false,
      ),
      isNull,
    );
    final config = resolveBackendConfig(
      url: '$url/rest/v1/',
      publishableKey: publicKey,
      allowInMemory: false,
      isRelease: true,
    );
    expect(config?.url, url);
  });

  testWidgets('configuration failure is a safe Arabic startup screen',
      (tester) async {
    await tester.pumpWidget(const MenoStartupError());
    expect(find.byKey(const Key('startup-configuration-error')), findsOneWidget);
    expect(find.text('تعذر تشغيل Meno الآن'), findsOneWidget);
    expect(find.textContaining('SUPABASE_'), findsNothing);
  });

  test('approved pages are bounded, stable and duplicate-free', () async {
    final date = DateTime.utc(2026, 9, 16);
    final repository = InMemoryQuestionRepository(
      additionalQuestions: [
        for (var i = 0; i < 45; i++)
          Question(
            id: 'stable-${i.toString().padLeft(3, '0')}',
            title: 'سؤال عن الخدمة $i',
            body: 'تجربة مفيدة',
            category: 'الخدمات',
            author: 'مجهول',
            createdAt: date,
            status: QuestionStatus.approved,
          ),
        Question(
          id: 'pending-secret',
          title: 'سؤال سري',
          body: 'لا يظهر',
          category: 'الخدمات',
          author: 'مجهول',
          createdAt: date,
          status: QuestionStatus.pending,
        ),
      ],
    );
    final first = await repository.approvedQuestionsPage(category: 'الخدمات');
    final second = await repository.approvedQuestionsPage(
      category: 'الخدمات',
      cursor: first.nextCursor,
    );
    final third = await repository.approvedQuestionsPage(
      category: 'الخدمات',
      cursor: second.nextCursor,
    );
    final all = [...first.items, ...second.items, ...third.items];
    expect(first.items, hasLength(20));
    expect(second.items, hasLength(20));
    expect(third.items, hasLength(5));
    expect(third.nextCursor, isNull);
    expect(all.map((question) => question.id).toSet(), hasLength(45));
    expect(all.any((question) => question.id == 'pending-secret'), isFalse);
  });

  test('search pages retain Arabic partial matching and category', () async {
    final repository = InMemoryQuestionRepository(
      additionalQuestions: [
        for (var i = 0; i < 26; i++)
          Question(
            id: 'search-$i',
            title: 'تجربة تحويل رقم $i',
            body: 'معلومة مفيدة عن التحويل',
            category: 'البنوك والتحويلات',
            author: 'مجهول',
            createdAt: DateTime.utc(2026, 9, 16, 1, i),
            status: QuestionStatus.approved,
          ),
      ],
    );
    final first = await repository.searchApprovedQuestionsPage(
      query: 'تحويل',
      category: 'البنوك والتحويلات',
    );
    final second = await repository.searchApprovedQuestionsPage(
      query: 'تحويل',
      category: 'البنوك والتحويلات',
      cursor: first.nextCursor,
    );
    expect(first.items, hasLength(20));
    expect(second.items, isNotEmpty);
    expect(
      first.items.map((item) => item.id).toSet().intersection(
        second.items.map((item) => item.id).toSet(),
      ),
      isEmpty,
    );
  });

  test('opening a summary loads only its question detail', () async {
    final repository = InMemoryQuestionRepository();
    final original = (await repository.approvedQuestions()).first;
    final summary = Question(
      id: original.id,
      title: original.title,
      body: original.body,
      category: original.category,
      author: original.author,
      createdAt: original.createdAt,
      status: original.status,
      answerCount: original.answerCount,
    );
    expect(summary.answers, isEmpty);
    final detail = await repository.questionDetails(summary);
    expect(detail.answers, isNotEmpty);
    expect(detail.id, summary.id);
  });

  test('paged SQL is bounded, invoker-safe and approved-only', () {
    final sql = File(
      'supabase/migrations/202609160001_approved_question_paging.sql',
    ).readAsStringSync().toLowerCase();
    expect(sql, contains('security invoker'));
    expect(sql, contains("q.status = 'approved'"));
    expect(sql, contains('limit least(greatest'));
    expect(sql, contains('grant execute on function public.approved_question_page'));
    expect(sql, isNot(contains('drop table')));
  });
}
