import 'package:flutter/material.dart';

import '../models/home_banner.dart';

class HomeBannerCarousel extends StatefulWidget {
  const HomeBannerCarousel({super.key, required this.banners});

  final List<HomeBanner> banners;

  @override
  State<HomeBannerCarousel> createState() => _HomeBannerCarouselState();
}

class _HomeBannerCarouselState extends State<HomeBannerCarousel> {
  int page = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) return const SizedBox.shrink();
    return Padding(
      key: const Key('home-banners'),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Column(
        children: [
          SizedBox(
            height: 142,
            child: PageView.builder(
              itemCount: widget.banners.length,
              onPageChanged: (value) => setState(() => page = value),
              itemBuilder: (context, index) =>
                  _BannerCard(banner: widget.banners[index]),
            ),
          ),
          if (widget.banners.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.banners.length,
                  (index) => Container(
                    width: index == page ? 18 : 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: index == page
                          ? const Color(0xFFD9A752)
                          : const Color(0xFFE5C495),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({required this.banner});

  final HomeBanner banner;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: const Color(0xFFE5C495),
              child: Image.network(
                banner.imageUrl,
                key: Key('home-banner-image-${banner.id}'),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(
                  key: Key('home-banner-placeholder-${banner.id}'),
                  child: const Icon(
                    Icons.campaign_outlined,
                    color: Color(0xFF121212),
                    size: 38,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: ColoredBox(color: Colors.black.withValues(alpha: .55)),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (banner.type == HomeBannerType.ad)
                    Container(
                      margin: const EdgeInsets.only(bottom: 7),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD9A752),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: const Text(
                        'إعلان',
                        style: TextStyle(
                          color: Color(0xFF121212),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  Text(
                    banner.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (banner.shortText.isNotEmpty)
                    Text(
                      banner.shortText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
}
