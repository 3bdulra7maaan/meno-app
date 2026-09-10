import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meno/data/in_memory_question_repository.dart';
import 'package:meno/main.dart';
import 'package:meno/models/home_banner.dart';
import 'package:meno/widgets/home_banner_carousel.dart';

HomeBanner banner({
  required String id,
  String title = 'تنبيه من Meno',
  bool enabled = true,
  HomeBannerTargetType targetType = HomeBannerTargetType.none,
  DateTime? startAt,
  DateTime? endAt,
}) =>
    HomeBanner(
      id: id,
      imageUrl: 'https://cdn.example.com/$id.png',
      title: title,
      shortText: 'معلومة قصيرة للمجتمع',
      type: HomeBannerType.announcement,
      displayOrder: 0,
      enabled: enabled,
      targetType: targetType,
      startAt: startAt,
      endAt: endAt,
    );

void main() {
  testWidgets('Home renders an active HTTPS banner above an intact feed', (
    tester,
  ) async {
    await tester.pumpWidget(
      MenoApp(
        repository: InMemoryQuestionRepository(banners: [banner(id: 'active')]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('home-banners')), findsOneWidget);
    expect(find.text('تنبيه من Meno'), findsOneWidget);
    expect(find.text('اكتشف المزيد'), findsOneWidget);
    final image = tester.widget<Image>(
      find.byKey(const Key('home-banner-image-active')),
    );
    expect(image.image, isA<NetworkImage>());
    expect((image.image as NetworkImage).url,
        'https://cdn.example.com/active.png');
    expect(find.text('أفضل طريقة للتحويل من قطر للسودان شنو؟'), findsOneWidget);
  });

  testWidgets('disabled and expired banners stay off Home', (tester) async {
    final now = DateTime.now();
    await tester.pumpWidget(
      MenoApp(
        repository: InMemoryQuestionRepository(
          banners: [
            banner(id: 'disabled', enabled: false),
            banner(
              id: 'expired',
              endAt: now.subtract(const Duration(minutes: 1)),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('home-banners')), findsNothing);
    expect(find.text('تنبيه من Meno'), findsNothing);
    expect(find.text('أفضل طريقة للتحويل من قطر للسودان شنو؟'), findsOneWidget);
  });

  testWidgets('failed banner image shows a clean placeholder and keeps feed', (
    tester,
  ) async {
    await tester.pumpWidget(
      MenoApp(
        repository: InMemoryQuestionRepository(banners: [banner(id: 'broken')]),
      ),
    );
    await tester.pumpAndSettle();

    // Flutter widget tests return HTTP 400 for real network image requests.
    expect(
      find.byKey(const Key('home-banner-placeholder-broken')),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget);
    expect(find.text('أفضل طريقة للتحويل من قطر للسودان شنو؟'), findsOneWidget);
  });

  testWidgets('carousel auto-advances, pauses for touch, then loops', (
    tester,
  ) async {
    final banners = [
      banner(id: 'one', title: 'البنر الأول'),
      banner(id: 'two', title: 'البنر الثاني'),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: HomeBannerCarousel(banners: banners)),
      ),
    );
    await tester.pump();
    expect(find.text('البنر الأول'), findsOneWidget);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('home-banner-page-view'))),
    );
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('البنر الأول'), findsOneWidget);
    await gesture.up();

    await tester.pump(homeBannerAdvanceInterval);
    await tester.pump(const Duration(milliseconds: 450));
    expect(find.text('البنر الثاني'), findsOneWidget);
    await tester.pump(homeBannerAdvanceInterval);
    await tester.pump(const Duration(milliseconds: 450));
    expect(find.text('البنر الأول'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('banner tap reports the selected banner', (tester) async {
    HomeBanner? tapped;
    final selected = banner(id: 'tap');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeBannerCarousel(
            banners: [selected],
            onBannerTap: (value) => tapped = value,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('home-banner-tap')));
    expect(tapped, same(selected));
  });

  testWidgets('internal banner opens the in-app detail screen', (tester) async {
    await tester.pumpWidget(
      MenoApp(
        repository: InMemoryQuestionRepository(
          banners: [
            banner(
              id: 'internal',
              title: 'تفاصيل مهمة',
              targetType: HomeBannerTargetType.internalPage,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('home-banner-internal')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('banner-detail-screen')), findsOneWidget);
    expect(find.text('تفاصيل الإعلان'), findsOneWidget);
    expect(find.byKey(const Key('share-banner-action')), findsOneWidget);
  });
}
