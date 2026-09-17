import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'brand.dart';
import 'models/home_banner.dart';

class BannerDetailScreen extends StatelessWidget {
  const BannerDetailScreen({super.key, required this.banner});

  final HomeBanner banner;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text(
            'تفاصيل الإعلان',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          backgroundColor: surface,
        ),
        body: ListView(
          key: const Key('banner-detail-screen'),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: ColoredBox(
                  color: warmBeige,
                  child: Image.network(
                    banner.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(
                        Icons.campaign_outlined,
                        size: 46,
                        color: darkGold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
            const Row(
              children: [
                MenoMark(size: 24),
                SizedBox(width: 7),
                Text(
                  'Meno',
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    color: warmGold,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            Text(banner.title,
                style: Theme.of(context).textTheme.headlineSmall),
            if (banner.shortText.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                banner.shortText,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: muted,
                    ),
              ),
            ],
            const SizedBox(height: 22),
            FilledButton.icon(
              key: const Key('share-banner-action'),
              onPressed: () => Share.share(
                '${banner.title}\n\n${banner.shortText}\n\n'
                'اسأل زول جرّب على Meno',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: warmGold,
                foregroundColor: primaryBlack,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              icon: const Icon(Icons.ios_share_rounded),
              label: const Text(
                'مشاركة الإعلان',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(color: border),
            const SizedBox(height: 12),
            const Text(
              'معلومة من مجتمع Meno',
              textAlign: TextAlign.center,
              style: TextStyle(color: muted, fontSize: 12),
            ),
          ],
        ),
      );
}
