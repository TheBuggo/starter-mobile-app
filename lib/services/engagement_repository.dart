import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/ad_campaign.dart';
import '../models/owner_dashboard_summary.dart';

class EngagementRepository {
  const EngagementRepository(this._client);

  final SupabaseClient _client;

  User? get _currentUser => _client.auth.currentUser;

  Future<List<AdCampaign>> loadActiveCampaigns() async {
    final rows = await _client
        .from('ad_campaigns')
        .select()
        .eq('active', true)
        .order('priority');

    return rows.map((row) => AdCampaign.fromMap(row)).toList();
  }

  Future<void> recordAdEvent({
    required AdCampaign campaign,
    required String eventType,
    Map<String, dynamic> metadata = const {},
  }) async {
    final user = _currentUser;
    if (user == null) {
      return;
    }

    await _client.from('ad_events').insert({
      'campaign_id': campaign.id,
      'event_type': eventType,
      'metadata': metadata,
      'placement_key': campaign.placementKey,
      'user_id': user.id,
    });
  }

  Future<void> recordAppEvent({
    required String eventType,
    required String sessionId,
    int? durationMs,
    Map<String, dynamic> metadata = const {},
    String? screenName,
    int? scrollDepth,
    String? target,
  }) async {
    final user = _currentUser;
    if (user == null) {
      return;
    }

    await _client.from('app_events').insert({
      'duration_ms': durationMs,
      'event_type': eventType,
      'metadata': metadata,
      'screen_name': screenName,
      'scroll_depth': scrollDepth,
      'session_id': sessionId,
      'target': target,
      'user_id': user.id,
    });
  }

  Future<OwnerDashboardSummary> loadOwnerDashboard() async {
    final appRows = await _client
        .from('app_events')
        .select()
        .order('created_at', ascending: false)
        .limit(750);
    final adRows = await _client
        .from('ad_events')
        .select()
        .order('created_at', ascending: false)
        .limit(750);
    final campaigns = await _client.from('ad_campaigns').select();

    return _buildSummary(
      adRows: adRows,
      appRows: appRows,
      campaignRows: campaigns,
    );
  }

  OwnerDashboardSummary _buildSummary({
    required List<dynamic> adRows,
    required List<dynamic> appRows,
    required List<dynamic> campaignRows,
  }) {
    final users = <String>{};
    final screens = <String, _ScreenAccumulator>{};
    final campaigns = {
      for (final row in campaignRows)
        row['id'] as int: AdCampaign.fromMap(row as Map<String, dynamic>),
    };
    final ads = <int, _AdAccumulator>{};
    final recent = <RecentEventRow>[];

    for (final row in appRows.cast<Map<String, dynamic>>()) {
      final userId = row['user_id'] as String?;
      if (userId != null) {
        users.add(userId);
      }

      final screenName = (row['screen_name'] as String?) ?? 'Unknown';
      final eventType = (row['event_type'] as String?) ?? 'event';
      final target = (row['target'] as String?) ?? '';
      final screen =
          screens.putIfAbsent(screenName, () => _ScreenAccumulator(screenName));

      if (eventType == 'screen_view') {
        screen.views += 1;
      }

      final durationMs = row['duration_ms'] as int?;
      if (durationMs != null && durationMs > 0) {
        screen.durationTotal += durationMs;
        screen.durationSamples += 1;
      }

      final scrollDepth = row['scroll_depth'] as int?;
      if (scrollDepth != null && scrollDepth > screen.maxScrollDepth) {
        screen.maxScrollDepth = scrollDepth;
      }

      if (recent.length < 8) {
        recent.add(
          RecentEventRow(
            eventType: eventType,
            screenName: screenName,
            target: target,
          ),
        );
      }
    }

    for (final row in adRows.cast<Map<String, dynamic>>()) {
      final campaignId = row['campaign_id'] as int?;
      if (campaignId == null) {
        continue;
      }

      final campaign = campaigns[campaignId];
      final ad = ads.putIfAbsent(
        campaignId,
        () => _AdAccumulator(
          campaignTitle: campaign?.title ?? 'Campaign $campaignId',
          placementKey:
              campaign?.placementKey ?? (row['placement_key'] as String? ?? ''),
        ),
      );

      switch (row['event_type'] as String?) {
        case 'impression':
          ad.impressions += 1;
          break;
        case 'click':
          ad.clicks += 1;
          break;
        case 'reward_earned':
          ad.rewards += 1;
          break;
      }
    }

    final screenRows = screens.values.map((screen) => screen.toRow()).toList()
      ..sort((a, b) => b.views.compareTo(a.views));
    final adMetricRows = ads.values.map((ad) => ad.toRow()).toList()
      ..sort((a, b) => b.impressions.compareTo(a.impressions));

    return OwnerDashboardSummary(
      activeUsers: users.length,
      adRows: adMetricRows,
      recentEvents: recent,
      screenRows: screenRows,
      totalAdEvents: adRows.length,
      totalAppEvents: appRows.length,
    );
  }
}

class _ScreenAccumulator {
  _ScreenAccumulator(this.screenName);

  int durationSamples = 0;
  int durationTotal = 0;
  int maxScrollDepth = 0;
  final String screenName;
  int views = 0;

  ScreenMetricRow toRow() {
    return ScreenMetricRow(
      averageDurationMs:
          durationSamples == 0 ? 0 : durationTotal ~/ durationSamples,
      maxScrollDepth: maxScrollDepth,
      screenName: screenName,
      views: views,
    );
  }
}

class _AdAccumulator {
  _AdAccumulator({
    required this.campaignTitle,
    required this.placementKey,
  });

  final String campaignTitle;
  int clicks = 0;
  int impressions = 0;
  final String placementKey;
  int rewards = 0;

  AdMetricRow toRow() {
    return AdMetricRow(
      campaignTitle: campaignTitle,
      clicks: clicks,
      impressions: impressions,
      placementKey: placementKey,
      rewards: rewards,
    );
  }
}
