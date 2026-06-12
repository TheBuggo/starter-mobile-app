import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../app/app_controller.dart';
import '../services/payment_service.dart';
import '../widgets/action_button.dart';
import '../widgets/ad_placement.dart';
import '../widgets/screen_frame.dart';
import '../widgets/section_card.dart';
import '../widgets/tracked_list_view.dart';

class StoreScreen extends StatelessWidget {
  const StoreScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return ScreenFrame(
      child: TrackedListView(
        controller: controller,
        screenName: 'Store',
        children: [
          Text(
            'Store',
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          _StoreItemCard(
            controller: controller,
            fallbackPrice: 'Theme purchase',
            icon: Icons.palette,
            product: controller.productById(StoreProductIds.proThemePack),
            productId: StoreProductIds.proThemePack,
            title: 'Pro theme pack',
          ),
          const SizedBox(height: 12),
          _StoreItemCard(
            controller: controller,
            fallbackPrice: 'Consumable item',
            icon: Icons.bolt,
            product: controller.productById(StoreProductIds.creditPack),
            productId: StoreProductIds.creditPack,
            title: '100 item credits',
          ),
          const SizedBox(height: 12),
          AdPlacement(controller: controller, placementKey: 'store_rewarded'),
          const SizedBox(height: 12),
          AdPlacement(controller: controller, placementKey: 'store_click'),
        ],
      ),
    );
  }
}

class _StoreItemCard extends StatelessWidget {
  const _StoreItemCard({
    required this.controller,
    required this.fallbackPrice,
    required this.icon,
    required this.product,
    required this.productId,
    required this.title,
  });

  final AppController controller;
  final String fallbackPrice;
  final IconData icon;
  final ProductDetails? product;
  final String productId;
  final String title;

  @override
  Widget build(BuildContext context) {
    final owned = controller.hasActiveEntitlement(productId);

    return SectionCard(
      title: title,
      subtitle: owned ? 'Owned' : product?.price ?? fallbackPrice,
      icon: icon,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(product?.description ??
              'Create this product in App Store Connect and Play Console.'),
          const SizedBox(height: 12),
          ActionButton(
            icon: owned ? Icons.check_circle : Icons.shopping_bag,
            label: owned ? 'Owned' : 'Buy',
            onPressed: owned || product == null
                ? null
                : () => controller.buyProduct(product!),
          ),
        ],
      ),
    );
  }
}
