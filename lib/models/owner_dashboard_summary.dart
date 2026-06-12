class OwnerDashboardSummary {
  const OwnerDashboardSummary({
    required this.activeUsers,
    required this.adRows,
    required this.recentEvents,
    required this.screenRows,
    required this.totalAdEvents,
    required this.totalAppEvents,
  });

  final int activeUsers;
  final List<AdMetricRow> adRows;
  final List<RecentEventRow> recentEvents;
  final List<ScreenMetricRow> screenRows;
  final int totalAdEvents;
  final int totalAppEvents;
}

class ScreenMetricRow {
  const ScreenMetricRow({
    required this.averageDurationMs,
    required this.maxScrollDepth,
    required this.screenName,
    required this.views,
  });

  final int averageDurationMs;
  final int maxScrollDepth;
  final String screenName;
  final int views;
}

class AdMetricRow {
  const AdMetricRow({
    required this.campaignTitle,
    required this.clicks,
    required this.impressions,
    required this.placementKey,
    required this.rewards,
  });

  final String campaignTitle;
  final int clicks;
  final int impressions;
  final String placementKey;
  final int rewards;

  int get clickThroughRate {
    if (impressions == 0) {
      return 0;
    }
    return ((clicks / impressions) * 100).round();
  }
}

class RecentEventRow {
  const RecentEventRow({
    required this.eventType,
    required this.screenName,
    required this.target,
  });

  final String eventType;
  final String screenName;
  final String target;
}
