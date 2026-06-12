import 'package:flutter/material.dart';

import '../app/app_controller.dart';
import '../services/payment_service.dart';
import '../widgets/action_button.dart';
import '../widgets/ad_placement.dart';
import '../widgets/screen_frame.dart';
import '../widgets/section_card.dart';
import '../widgets/tracked_list_view.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final profile = controller.profile;
    final hasPlus =
        controller.hasActiveEntitlement(StoreProductIds.monthlySubscription) ||
            controller.hasActiveEntitlement(StoreProductIds.yearlySubscription);

    return ScreenFrame(
      child: TrackedListView(
        controller: controller,
        screenName: 'Home',
        children: [
          Text(
            'Welcome${profile?.displayName.isEmpty == false ? ', ${profile!.displayName}' : ''}',
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Starter status',
            subtitle: hasPlus ? 'Subscription active' : 'Free account',
            icon: Icons.auto_awesome,
            child: Text(
              hasPlus
                  ? 'Premium gates are wired. Add product-specific features as the app grows.'
                  : 'Upgrade paths, item purchases, account data, and theme preferences are scaffolded.',
            ),
          ),
          const SizedBox(height: 12),
          AdPlacement(controller: controller, placementKey: 'home_banner'),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Current theme',
            subtitle: controller.activeTheme.name,
            icon: Icons.palette,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    controller.activeTheme.darkMode
                        ? 'Dark mode palette'
                        : 'Light mode palette',
                  ),
                ),
                ActionButton(
                  compact: true,
                  icon: Icons.tune,
                  label: 'Edit',
                  onPressed: () => controller.setActiveTab(AppTab.themes),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Account',
            subtitle: controller.accountIdentity,
            icon: Icons.person,
            child: ActionButton(
              icon: Icons.manage_accounts,
              label: 'Manage account',
              onPressed: () => controller.setActiveTab(AppTab.account),
            ),
          ),
        ],
      ),
    );
  }
}
