enum AdCampaignType {
  banner('banner'),
  clickOut('click_out'),
  rewardedVideo('rewarded_video');

  const AdCampaignType(this.value);

  final String value;

  static AdCampaignType fromValue(String? value) {
    return AdCampaignType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => AdCampaignType.banner,
    );
  }
}

class AdCampaign {
  const AdCampaign({
    required this.active,
    required this.body,
    required this.ctaLabel,
    required this.id,
    required this.placementKey,
    required this.priority,
    required this.rewardQuantity,
    required this.slug,
    required this.title,
    required this.type,
    this.imageUrl,
    this.rewardKey,
    this.targetUrl,
  });

  final bool active;
  final String body;
  final String ctaLabel;
  final int id;
  final String? imageUrl;
  final String placementKey;
  final int priority;
  final String? rewardKey;
  final int rewardQuantity;
  final String slug;
  final String? targetUrl;
  final String title;
  final AdCampaignType type;

  bool get hasClickTarget => targetUrl != null && targetUrl!.isNotEmpty;
  bool get isRewarded => type == AdCampaignType.rewardedVideo;

  factory AdCampaign.fromMap(Map<String, dynamic> map) {
    return AdCampaign(
      active: (map['active'] as bool?) ?? false,
      body: (map['body'] as String?) ?? '',
      ctaLabel: (map['cta_label'] as String?) ?? 'Learn more',
      id: map['id'] as int,
      imageUrl: map['image_url'] as String?,
      placementKey: (map['placement_key'] as String?) ?? '',
      priority: (map['priority'] as int?) ?? 100,
      rewardKey: map['reward_key'] as String?,
      rewardQuantity: (map['reward_quantity'] as int?) ?? 0,
      slug: (map['slug'] as String?) ?? '',
      targetUrl: map['target_url'] as String?,
      title: (map['title'] as String?) ?? '',
      type: AdCampaignType.fromValue(map['campaign_type'] as String?),
    );
  }
}
