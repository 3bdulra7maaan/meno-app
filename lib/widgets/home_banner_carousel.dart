import 'dart:async';

import 'package:flutter/material.dart';

import '../models/home_banner.dart';

const homeBannerAdvanceInterval = Duration(milliseconds: 4500);

class HomeBannerCarousel extends StatefulWidget {
  const HomeBannerCarousel({
    super.key,
    required this.banners,
    this.onBannerTap,
  });

  final List<HomeBanner> banners;
  final ValueChanged<HomeBanner>? onBannerTap;

  @override
  State<HomeBannerCarousel> createState() => _HomeBannerCarouselState();
}

class _HomeBannerCarouselState extends State<HomeBannerCarousel> {
  late PageController controller;
  Timer? timer;
  int page = 0;
  bool interacting = false;

  int get initialPage =>
      widget.banners.length > 1 ? widget.banners.length * 1000 : 0;

  @override
  void initState() {
    super.initState();
    controller = PageController(initialPage: initialPage);
    scheduleAdvance();
  }

  @override
  void didUpdateWidget(covariant HomeBannerCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.banners.length != widget.banners.length) {
      timer?.cancel();
      controller.dispose();
      page = 0;
      controller = PageController(initialPage: initialPage);
      scheduleAdvance();
    }
  }

  void scheduleAdvance() {
    timer?.cancel();
    if (widget.banners.length < 2 || interacting) return;
    timer = Timer.periodic(homeBannerAdvanceInterval, (_) {
      if (!mounted || interacting || !controller.hasClients) return;
      controller.nextPage(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void pause() {
    interacting = true;
    timer?.cancel();
  }

  void resume() {
    interacting = false;
    scheduleAdvance();
  }

  @override
  void dispose() {
    timer?.cancel();
    controller.dispose();
    super.dispose();
  }

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
            child: Listener(
              onPointerDown: (_) => pause(),
              onPointerUp: (_) => resume(),
              onPointerCancel: (_) => resume(),
              child: PageView.builder(
                key: const Key('home-banner-page-view'),
                controller: controller,
                itemCount: widget.banners.length == 1 ? 1 : null,
                onPageChanged: (value) => setState(
                  () => page = value % widget.banners.length,
                ),
                itemBuilder: (context, index) {
                  final banner = widget.banners[index % widget.banners.length];
                  return _BannerCard(
                    banner: banner,
                    onTap: widget.onBannerTap == null
                        ? null
                        : () => widget.onBannerTap!(banner),
                  );
                },
              ),
            ),
          ),
          if (widget.banners.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.banners.length,
                  (index) => AnimatedContainer(
                    key: Key('home-banner-indicator-$index'),
                    duration: const Duration(milliseconds: 180),
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
  const _BannerCard({required this.banner, this.onTap});

  final HomeBanner banner;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Material(
          color: const Color(0xFFE5C495),
          child: InkWell(
            key: Key('home-banner-${banner.id}'),
            onTap: onTap,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
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
                Positioned.fill(
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: .55),
                  ),
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
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
