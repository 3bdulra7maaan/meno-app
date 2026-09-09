enum HomeBannerType { announcement, promotion, ad }

enum HomeBannerTargetType { none, internalPage, externalUrl }

class HomeBanner {
  const HomeBanner({
    required this.id,
    required this.imageUrl,
    required this.title,
    required this.shortText,
    required this.type,
    required this.displayOrder,
    this.enabled = true,
    this.targetType = HomeBannerTargetType.none,
    this.targetUrl,
    this.startAt,
    this.endAt,
  });

  final String id;
  final String imageUrl;
  final String title;
  final String shortText;
  final String? targetUrl;
  final HomeBannerType type;
  final int displayOrder;
  final bool enabled;
  final HomeBannerTargetType targetType;
  final DateTime? startAt;
  final DateTime? endAt;
}
