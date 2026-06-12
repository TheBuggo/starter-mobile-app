import 'package:flutter/material.dart';

import '../app/app_controller.dart';
import '../models/owner_dashboard_summary.dart';
import '../widgets/action_button.dart';
import '../widgets/screen_frame.dart';
import '../widgets/section_card.dart';
import '../widgets/tracked_list_view.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final summary = controller.ownerDashboard;

    return ScreenFrame(
      child: TrackedListView(
        controller: controller,
        screenName: 'Dashboard',
        children: [
          Text(
            'Owner dashboard',
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Activity',
            subtitle: summary == null
                ? 'No data loaded'
                : '${summary.activeUsers} users seen',
            icon: Icons.query_stats,
            child: Column(
              children: [
                _MetricRow(
                  label: 'App events',
                  value: '${summary?.totalAppEvents ?? 0}',
                ),
                _MetricRow(
                  label: 'Ad events',
                  value: '${summary?.totalAdEvents ?? 0}',
                ),
                const SizedBox(height: 12),
                ActionButton(
                  icon: Icons.refresh,
                  label: 'Refresh dashboard',
                  onPressed:
                      controller.busy ? null : controller.refreshOwnerDashboard,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Screens',
            subtitle: 'Views, time, and scroll depth',
            icon: Icons.phone_iphone,
            child: _ScreenMetrics(rows: summary?.screenRows ?? const []),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Ads',
            subtitle: 'Impressions, clicks, and rewards',
            icon: Icons.campaign,
            child: _AdMetrics(rows: summary?.adRows ?? const []),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Recent events',
            subtitle: 'Latest captured interactions',
            icon: Icons.timeline,
            child: _RecentEvents(rows: summary?.recentEvents ?? const []),
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _ScreenMetrics extends StatelessWidget {
  const _ScreenMetrics({required this.rows});

  final List<ScreenMetricRow> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Text('No screen events yet.');
    }

    return Column(
      children: [
        for (final row in rows.take(6))
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(row.screenName),
            subtitle: Text(
              '${row.views} views - ${_seconds(row.averageDurationMs)} avg - ${row.maxScrollDepth}% scroll',
            ),
          ),
      ],
    );
  }

  String _seconds(int milliseconds) {
    if (milliseconds <= 0) {
      return '0s';
    }
    return '${(milliseconds / 1000).round()}s';
  }
}

class _AdMetrics extends StatelessWidget {
  const _AdMetrics({required this.rows});

  final List<AdMetricRow> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Text('No ad events yet.');
    }

    return Column(
      children: [
        for (final row in rows.take(6))
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(row.campaignTitle),
            subtitle: Text(
              '${row.impressions} impressions - ${row.clicks} clicks - ${row.rewards} rewards',
            ),
            trailing: Text('${row.clickThroughRate}% CTR'),
          ),
      ],
    );
  }
}

class _RecentEvents extends StatelessWidget {
  const _RecentEvents({required this.rows});

  final List<RecentEventRow> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Text('No events yet.');
    }

    return Column(
      children: [
        for (final row in rows)
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(row.eventType),
            subtitle: Text(row.target.isEmpty
                ? row.screenName
                : '${row.screenName} - ${row.target}'),
          ),
      ],
    );
  }
}
