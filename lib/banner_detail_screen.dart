import 'package:flutter/material.dart';

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
          backgroundColor: Colors.white,
        ),
        body: ListView(
          key: const Key('banner-detail-screen'),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
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
                        color: primaryBlack,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: warmBeige.withValues(alpha: .42),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Text(
                'من Meno',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 13),
            Text(banner.title,
                style: Theme.of(context).textTheme.headlineSmall),
            if (banner.shortText.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                banner.shortText,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ],
        ),
      );
}
