import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../app/app_controller.dart';
import '../services/payment_service.dart';
import '../widgets/action_button.dart';
import '../widgets/screen_frame.dart';
import '../widgets/section_card.dart';
import '../widgets/tracked_list_view.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return ScreenFrame(
      child: TrackedListView(
        controller: controller,
        screenName: 'Plans',
        children: [
          Text(
            'Plans',
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          _PlanCard(
            controller: controller,
            fallbackPrice: 'Monthly',
            product:
                controller.productById(StoreProductIds.monthlySubscription),
            productId: StoreProductIds.monthlySubscription,
            title: 'Starter Plus Monthly',
          ),
          const SizedBox(height: 12),
          _PlanCard(
            controller: controller,
            fallbackPrice: 'Yearly',
            product: controller.productById(StoreProductIds.yearlySubscription),
            productId: StoreProductIds.yearlySubscription,
            title: 'Starter Plus Yearly',
          ),
          const SizedBox(height: 12),
          ActionButton(
            icon: Icons.restore,
            label: 'Restore purchases',
            onPressed: controller.paymentsAvailable
                ? controller.restorePurchases
                : null,
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.controller,
    required this.fallbackPrice,
    required this.product,
    required this.productId,
    required this.title,
  });

  final AppController controller;
  final String fallbackPrice;
  final ProductDetails? product;
  final String productId;
  final String title;

  @override
  Widget build(BuildContext context) {
    final active = controller.hasActiveEntitlement(productId);

    return SectionCard(
      title: title,
      subtitle: active ? 'Active' : product?.price ?? fallbackPrice,
      icon: Icons.workspace_premium,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
              'Unlock subscription-gated features for the app idea you build on this starter.'),
          const SizedBox(height: 12),
          ActionButton(
            icon: active ? Icons.check_circle : Icons.payment,
            label: active ? 'Active' : 'Subscribe',
            onPressed: active || product == null
                ? null
                : () => controller.buyProduct(product!),
          ),
        ],
      ),
    );
  }
}
