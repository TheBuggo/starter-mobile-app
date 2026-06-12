import 'dart:async';

import 'package:flutter/material.dart';

import '../app/app_controller.dart';
import '../models/ad_campaign.dart';

class AdPlacement extends StatefulWidget {
  const AdPlacement({
    super.key,
    required this.controller,
    required this.placementKey,
  });

  final AppController controller;
  final String placementKey;

  @override
  State<AdPlacement> createState() => _AdPlacementState();
}

class _AdPlacementState extends State<AdPlacement> {
  int? _impressedCampaignId;

  @override
  Widget build(BuildContext context) {
    final campaign =
        widget.controller.campaignForPlacement(widget.placementKey);
    if (campaign == null) {
      return const SizedBox.shrink();
    }

    if (_impressedCampaignId != campaign.id) {
      _impressedCampaignId = campaign.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(widget.controller.recordAdImpression(campaign));
        }
      });
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: colorScheme.secondaryContainer,
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(_iconFor(campaign),
                    color: colorScheme.onSecondaryContainer),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sponsored',
                      style: Theme.of(context).textTheme.labelSmall),
                  const SizedBox(height: 2),
                  Text(
                    campaign.title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  if (campaign.body.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(campaign.body),
                  ],
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.tonalIcon(
                      icon: Icon(campaign.isRewarded
                          ? Icons.play_arrow
                          : Icons.open_in_new),
                      label: Text(campaign.ctaLabel),
                      onPressed: () => _handlePressed(campaign),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(AdCampaign campaign) {
    return switch (campaign.type) {
      AdCampaignType.banner => Icons.campaign,
      AdCampaignType.clickOut => Icons.ads_click,
      AdCampaignType.rewardedVideo => Icons.smart_display,
    };
  }

  Future<void> _handlePressed(AdCampaign campaign) async {
    if (campaign.isRewarded) {
      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            icon: const Icon(Icons.smart_display),
            title: Text(campaign.title),
            content: Text(campaign.body),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Finish'),
              ),
            ],
          );
        },
      );
      await widget.controller.recordAdReward(campaign);
      return;
    }

    await widget.controller.recordAdClick(campaign);
  }
}
