import 'package:flutter/material.dart';

import '../app/app_controller.dart';
import '../app/starter_manifest.dart';
import '../models/service_connection.dart';
import '../widgets/action_button.dart';
import '../widgets/screen_frame.dart';
import '../widgets/section_card.dart';
import '../widgets/tracked_list_view.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return ScreenFrame(
      child: TrackedListView(
        controller: controller,
        screenName: 'Tools',
        children: [
          Text(
            'Tools',
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          Text(
            'Phone tools',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          if (StarterManifest.capabilities.isEmpty) ...[
            const _EmptyToolSection(
              icon: Icons.phonelink_off_outlined,
              title: 'No phone tools selected',
            ),
            const SizedBox(height: 12),
          ] else
            for (final capability in StarterManifest.capabilities) ...[
              _CapabilityCard(
                capability: capability,
                controller: controller,
              ),
              const SizedBox(height: 12),
            ],
          Text(
            'Connections',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          if (StarterManifest.serviceProviders.isEmpty) ...[
            const _EmptyToolSection(
              icon: Icons.link_off,
              title: 'No service connections selected',
            ),
            const SizedBox(height: 12),
          ] else
            for (final provider in StarterManifest.serviceProviders) ...[
              _ProviderCard(
                connection: controller.serviceConnectionFor(provider.key),
                controller: controller,
                provider: provider,
              ),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}

class _CapabilityCard extends StatelessWidget {
  const _CapabilityCard({
    required this.capability,
    required this.controller,
  });

  final StarterCapability capability;
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final prepared = controller.capabilityPrepared(capability.key);

    return SectionCard(
      title: capability.name,
      subtitle: capability.status,
      icon: _iconForCapability(capability.key),
      child: _ToolCardBody(
        action: ActionButton(
          compact: true,
          icon: prepared ? Icons.check_circle : Icons.add_task,
          label: prepared ? 'Prepared' : 'Prepare',
          onPressed: prepared || controller.busy
              ? null
              : () => controller.prepareCapability(
                    capabilityKey: capability.key,
                    capabilityName: capability.name,
                  ),
        ),
        body: capability.body,
        statusIcon: prepared ? Icons.check_circle : Icons.circle_outlined,
        statusLabel: prepared ? 'Prepared' : 'Not enabled',
      ),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({
    required this.connection,
    required this.controller,
    required this.provider,
  });

  final ServiceConnection? connection;
  final AppController controller;
  final StarterServiceProvider provider;

  @override
  Widget build(BuildContext context) {
    final currentConnection = connection;
    final connected = currentConnection?.connected ?? false;
    final statusLabel = currentConnection?.statusLabel ?? 'Not connected';

    return SectionCard(
      title: provider.name,
      subtitle: _connectionTypeLabel(provider.connectionType),
      icon: _iconForProvider(provider.key),
      child: _ToolCardBody(
        action: ActionButton(
          compact: true,
          icon: connected ? Icons.check_circle : Icons.link,
          label: connected
              ? 'Connected'
              : currentConnection == null
                  ? 'Connect'
                  : 'Update',
          onPressed: connected || controller.busy
              ? null
              : () => controller.requestServiceConnection(
                    connectionType: provider.connectionType,
                    providerKey: provider.key,
                    providerName: provider.name,
                  ),
        ),
        body: provider.body,
        statusIcon: connected ? Icons.check_circle : Icons.pending_outlined,
        statusLabel: statusLabel,
      ),
    );
  }
}

class _ToolCardBody extends StatelessWidget {
  const _ToolCardBody({
    required this.action,
    required this.body,
    required this.statusIcon,
    required this.statusLabel,
  });

  final Widget action;
  final String body;
  final IconData statusIcon;
  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(statusIcon, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(statusLabel)),
          ],
        ),
        const SizedBox(height: 8),
        Text(body),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 380) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              details,
              const SizedBox(height: 12),
              Align(alignment: Alignment.centerLeft, child: action),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: details),
            const SizedBox(width: 16),
            action,
          ],
        );
      },
    );
  }
}

class _EmptyToolSection extends StatelessWidget {
  const _EmptyToolSection({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: title,
      subtitle: 'Starter setup',
      icon: icon,
      child: const Text('Run the starter setup when this app needs one.'),
    );
  }
}

IconData _iconForCapability(String key) {
  return switch (key) {
    'camera' => Icons.photo_camera_outlined,
    'qr_scanner' => Icons.qr_code_scanner,
    'microphone' => Icons.mic_none,
    'nfc' => Icons.nfc,
    'location' => Icons.location_on_outlined,
    'push_notifications' => Icons.notifications_none,
    'photo_library' => Icons.photo_library_outlined,
    'file_picker' => Icons.attach_file,
    'contacts' => Icons.contacts_outlined,
    'calendar' => Icons.event_outlined,
    'bluetooth' => Icons.bluetooth,
    _ => Icons.extension_outlined,
  };
}

IconData _iconForProvider(String key) {
  return switch (key) {
    'spotify' => Icons.music_note,
    'instagram' => Icons.camera_alt_outlined,
    'tiktok' => Icons.smart_display_outlined,
    'youtube' => Icons.play_circle_outline,
    'google' => Icons.account_circle_outlined,
    'apple' => Icons.phone_iphone,
    'stripe' => Icons.payments_outlined,
    'shopify' => Icons.shopping_bag_outlined,
    'slack' => Icons.tag,
    'discord' => Icons.forum_outlined,
    'custom_api' => Icons.hub_outlined,
    _ => Icons.link,
  };
}

String _connectionTypeLabel(String connectionType) {
  return switch (connectionType) {
    'oauth' => 'OAuth',
    'api_key' => 'API key',
    'webhook' => 'Webhook',
    'manual' => 'Manual',
    _ => 'Connection',
  };
}
