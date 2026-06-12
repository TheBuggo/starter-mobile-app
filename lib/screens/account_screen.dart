import 'package:flutter/material.dart';

import '../app/app_controller.dart';
import '../widgets/action_button.dart';
import '../widgets/screen_frame.dart';
import '../widgets/section_card.dart';
import '../widgets/tracked_list_view.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _displayName = TextEditingController();
  final _city = TextEditingController();
  final _avatarUrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final profile = widget.controller.profile;
    _displayName.text = profile?.displayName ?? '';
    _city.text = profile?.city ?? '';
    _avatarUrl.text = profile?.avatarUrl ?? '';
  }

  @override
  void dispose() {
    _displayName.dispose();
    _city.dispose();
    _avatarUrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.controller.profile;
    final avatarUrl = profile?.avatarUrl;

    return ScreenFrame(
      child: TrackedListView(
        controller: widget.controller,
        screenName: 'Account',
        children: [
          SectionCard(
            title: 'Account information',
            subtitle: widget.controller.accountIdentity,
            icon: Icons.manage_accounts,
            child: Column(
              children: [
                CircleAvatar(
                  backgroundImage: avatarUrl == null || avatarUrl.isEmpty
                      ? null
                      : NetworkImage(avatarUrl),
                  radius: 34,
                  child: avatarUrl == null || avatarUrl.isEmpty
                      ? const Icon(Icons.person, size: 34)
                      : null,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _displayName,
                  decoration: const InputDecoration(labelText: 'Display name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _city,
                  decoration: const InputDecoration(labelText: 'City'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _avatarUrl,
                  decoration:
                      const InputDecoration(labelText: 'Profile picture URL'),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 16),
                ActionButton(
                  icon: Icons.save,
                  label: 'Save account',
                  onPressed: widget.controller.busy ? null : _save,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Privacy',
            subtitle: 'Usage analytics',
            icon: Icons.privacy_tip,
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Share app usage analytics'),
              value: profile?.telemetryEnabled ?? false,
              onChanged: widget.controller.busy
                  ? null
                  : widget.controller.updateTelemetryEnabled,
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Local data',
            subtitle: 'This device',
            icon: Icons.storage,
            child: ActionButton(
              icon: Icons.cleaning_services,
              label: 'Clear cached data',
              onPressed: widget.controller.busy
                  ? null
                  : widget.controller.clearCachedData,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() {
    return widget.controller.updateProfile(
      avatarUrl: _avatarUrl.text,
      city: _city.text,
      displayName: _displayName.text,
    );
  }
}
