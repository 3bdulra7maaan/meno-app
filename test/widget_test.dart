import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:meno/data/in_memory_question_repository.dart';
import 'package:meno/main.dart';
import 'package:meno/models/home_banner.dart';
import 'package:meno/models/question.dart';
import 'package:meno/onboarding.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows the Arabic-first home feed', (tester) async {
    await tester.pumpWidget(MenoApp(repository: InMemoryQuestionRepository()));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('meno-wordmark')), findsOneWidget);
    expect(find.text('اسأل زول جرّب'), findsOneWidget);
    expect(find.text('اسأل'), findsOneWidget);
    expect(find.byKey(const Key('about-action')), findsNothing);
    expect(find.byKey(const Key('profile-menu')), findsOneWidget);
    expect(
      Theme.of(tester.element(find.text('اسأل زول جرّب')))
          .textTheme
          .bodyMedium
          ?.fontFamily,
      'Almarai',
    );

    for (final asset in [
      'assets/fonts/Almarai-Light.ttf',
      'assets/fonts/Almarai-Regular.ttf',
      'assets/fonts/Almarai-Bold.ttf',
      'assets/fonts/Almarai-ExtraBold.ttf',
    ]) {
      expect((await rootBundle.load(asset)).lengthInBytes, greaterThan(0));
    }
  });

  testWidgets('branded splash hands off to Home', (tester) async {
    await tester.pumpWidget(
      MenoApp(
        repository: InMemoryQuestionRepository(),
        showSplash: true,
      ),
    );

    expect(find.byKey(const Key('meno-splash')), findsOneWidget);
    expect(find.byKey(const Key('meno-mark')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1100));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('meno-wordmark')), findsOneWidget);
  });

  testWidgets('Question Details exposes the share flow', (tester) async {
    await tester.pumpWidget(MenoApp(repository: InMemoryQuestionRepository()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('أفضل طريقة للتحويل من قطر للسودان شنو؟'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('share-question-action')), findsOneWidget);
    await tester.tap(find.byKey(const Key('share-question-action')));
    await tester.pumpAndSettle();
    expect(find.text('شارك السؤال'), findsOneWidget);
    expect(find.byKey(const Key('share-native-button')), findsOneWidget);
    expect(find.byKey(const Key('copy-question-link')), findsOneWidget);
  });

  test('new questions stay pending until moderation', () async {
    final repository = InMemoryQuestionRepository();
    final question = await repository.submitQuestion(
      title: 'سؤال جديد للمراجعة',
      body: 'تفاصيل السؤال الجديد',
      category: 'الخدمات',
      anonymous: true,
    );

    expect(question.status, QuestionStatus.pending);
    expect(question.author, 'مجهول');
  });

  test('helpful vote returns the updated state and count', () async {
    final repository = InMemoryQuestionRepository();
    final questions = await repository.approvedQuestions();
    final answer = questions.first.answers.first;
    final before = answer.helpfulCount;

    final result = await repository.toggleHelpful(
      questionId: questions.first.id,
      answerId: answer.id,
    );

    expect(result.isHelpful, isTrue);
    expect(result.helpfulCount, before + 1);
  });

  test('formats Arabic answer counts', () {
    expect(answerCountLabel(0), 'لا توجد إجابات');
    expect(answerCountLabel(1), 'إجابة واحدة');
    expect(answerCountLabel(2), 'إجابتان');
    expect(answerCountLabel(3), '3 إجابات');
    expect(answerCountLabel(10), '10 إجابات');
    expect(answerCountLabel(11), '11 إجابة');
    expect(answerCountLabel(125), '125 إجابة');
  });

  testWidgets('Search finds Arabic title/body/category and clears the field', (
    tester,
  ) async {
    await tester.pumpWidget(MenoApp(repository: InMemoryQuestionRepository()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('البحث'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('search-field')), 'تحويل');
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
    expect(find.text('أفضل طريقة للتحويل من قطر للسودان شنو؟'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('search-field')), 'وصل');
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
    expect(find.text('ما لقينا نتيجة مطابقة'), findsOneWidget);

    await tester.tap(find.text('امسح البحث'));
    await tester.pumpAndSettle();
    final field = tester.widget<TextField>(
      find.byKey(const Key('search-field')),
    );
    expect(field.controller!.text, isEmpty);
    expect(find.text('أفضل طريقة للتحويل من قطر للسودان شنو؟'), findsOneWidget);
  });

  testWidgets('أسئلتي displays private status and only published opens', (
    tester,
  ) async {
    final repository = InMemoryQuestionRepository();
    await repository.submitQuestion(
      title: 'سؤال خاص قيد المراجعة',
      body: 'تفاصيل خاصة لا تظهر في الخلاصة العامة',
      category: 'الخدمات',
      anonymous: true,
    );
    await tester.pumpWidget(MenoApp(repository: repository));
    await tester.pumpAndSettle();
    await tester.tap(find.text('أسئلتي').last);
    await tester.pumpAndSettle();
    expect(find.text('قيد المراجعة'), findsOneWidget);
    expect(find.text('سؤال خاص قيد المراجعة'), findsOneWidget);
    await tester.tap(find.text('سؤال خاص قيد المراجعة'));
    await tester.pumpAndSettle();
    expect(find.text('أسئلتي'), findsNWidgets(2));
  });

  testWidgets('published question in أسئلتي opens normal details', (
    tester,
  ) async {
    await tester.pumpWidget(MenoApp(repository: _ApprovedOwnerRepository()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('أسئلتي').last);
    await tester.pumpAndSettle();

    expect(find.text('تم النشر'), findsOneWidget);
    await tester.tap(find.text('أفضل طريقة للتحويل من قطر للسودان شنو؟'));
    await tester.pumpAndSettle();

    expect(find.text('السؤال'), findsOneWidget);
    expect(find.text('إجابة واحدة'), findsOneWidget);
  });

  test('maps all moderation statuses to approved Arabic wording', () {
    expect(questionStatusLabel(QuestionStatus.pending), 'قيد المراجعة');
    expect(questionStatusLabel(QuestionStatus.approved), 'تم النشر');
    expect(questionStatusLabel(QuestionStatus.rejected), 'لم يتم النشر');
  });

  testWidgets('first launch onboarding completes and persists', (tester) async {
    SharedPreferences.setMockInitialValues({});
    expect(await isOnboardingCompleted(), isFalse);

    await tester.pumpWidget(
      MenoApp(
        repository: InMemoryQuestionRepository(),
        showOnboarding: true,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('اسأل السودانيين عن تجربة حقيقية.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('onboarding-action')));
    await tester.pumpAndSettle();
    expect(find.text('شارك تجربتك'), findsOneWidget);
    await tester.tap(find.byKey(const Key('onboarding-action')));
    await tester.pumpAndSettle();
    expect(find.text('مجتمع أنفع'), findsOneWidget);
    await tester.tap(find.byKey(const Key('onboarding-action')));
    await tester.pumpAndSettle();

    expect(find.text('أسئلة من المجتمع'), findsOneWidget);
    expect(await isOnboardingCompleted(), isTrue);
  });

  testWidgets('Home hides an empty carousel and shows active banners', (
    tester,
  ) async {
    await tester.pumpWidget(MenoApp(repository: InMemoryQuestionRepository()));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('home-banners')), findsNothing);

    final now = DateTime.now();
    await tester.pumpWidget(
      MenoApp(
        key: const ValueKey('banner-app'),
        repository: InMemoryQuestionRepository(
          banners: [
            HomeBanner(
              id: 'active',
              imageUrl: 'https://example.com/banner.png',
              title: 'تنبيه من Meno',
              shortText: 'معلومة قصيرة للمجتمع',
              type: HomeBannerType.announcement,
              displayOrder: 0,
              startAt: now.subtract(const Duration(minutes: 1)),
              endAt: now.add(const Duration(minutes: 1)),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('home-banners')), findsOneWidget);
    expect(find.text('تنبيه من Meno'), findsOneWidget);

    final repository = InMemoryQuestionRepository(
      banners: [
        HomeBanner(
          id: 'disabled',
          imageUrl: 'https://example.com/disabled.png',
          title: 'بنر معطل',
          shortText: '',
          type: HomeBannerType.announcement,
          displayOrder: 0,
          enabled: false,
        ),
        HomeBanner(
          id: 'expired',
          imageUrl: 'https://example.com/expired.png',
          title: 'بنر منتهي',
          shortText: '',
          type: HomeBannerType.promotion,
          displayOrder: 1,
          endAt: now.subtract(const Duration(minutes: 1)),
        ),
      ],
    );
    expect(await repository.activeBanners(), isEmpty);
  });

  testWidgets('answer composer fits a compact Android viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });

    final repository = InMemoryQuestionRepository();
    await tester.pumpWidget(MenoApp(repository: repository));
    await tester.pumpAndSettle();
    final question = (await repository.approvedQuestions()).first;
    Navigator.of(tester.element(find.byType(HomeShell))).push<void>(
      MaterialPageRoute(
        builder: (_) => QuestionDetailsScreen(
          question: question,
          repository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.showKeyboard(find.byKey(const Key('answer-field')));
    tester.view.viewInsets = const FakeViewPadding(bottom: 220);
    addTearDown(() => tester.view.viewInsets = FakeViewPadding.zero);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('answer-field')), findsOneWidget);
    expect(find.byKey(const Key('answer-send-button')), findsOneWidget);
    expect(
      tester.getBottomRight(find.byKey(const Key('answer-send-button'))).dy,
      lessThanOrEqualTo(348),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('answer composer fits a tall Android viewport', (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.viewInsets = FakeViewPadding.zero;
    });

    final repository = InMemoryQuestionRepository();
    await tester.pumpWidget(MenoApp(repository: repository));
    await tester.pumpAndSettle();
    final question = (await repository.approvedQuestions()).first;
    Navigator.of(tester.element(find.byType(HomeShell))).push<void>(
      MaterialPageRoute(
        builder: (_) => QuestionDetailsScreen(
          question: question,
          repository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.showKeyboard(find.byKey(const Key('answer-field')));
    await tester.pumpAndSettle();

    expect(
      tester.getBottomRight(find.byKey(const Key('answer-send-button'))).dy,
      lessThanOrEqualTo(595),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('an answer can be reported once', (tester) async {
    await tester.pumpWidget(MenoApp(repository: InMemoryQuestionRepository()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('أفضل طريقة للتحويل من قطر للسودان شنو؟'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('report-answer-a1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('report-answer-a1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(reportReasons['spam']!).last);
    await tester.pumpAndSettle();
    expect(
      find.text('وصلنا بلاغك، شكراً لمساعدتك في الحفاظ على المجتمع.'),
      findsOneWidget,
    );
  });
}

class _ApprovedOwnerRepository extends InMemoryQuestionRepository {
  @override
  Future<List<Question>> currentUserQuestions() async => [
        (await approvedQuestions()).first,
      ];
}
