import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meno/data/in_memory_question_repository.dart';
import 'package:meno/main.dart';
import 'package:meno/models/home_banner.dart';

HomeBanner banner({
  required String id,
  bool enabled = true,
  DateTime? startAt,
  DateTime? endAt,
}) =>
    HomeBanner(
      id: id,
      imageUrl: 'https://cdn.example.com/$id.png',
      title: 'تنبيه من Meno',
      shortText: 'معلومة قصيرة للمجتمع',
      type: HomeBannerType.announcement,
      displayOrder: 0,
      enabled: enabled,
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
    expect(find.byIcon(Icons.campaign_outlined), findsOneWidget);
    expect(find.text('أفضل طريقة للتحويل من قطر للسودان شنو؟'), findsOneWidget);
  });
}
