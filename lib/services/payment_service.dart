import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StoreProductIds {
  static const monthlySubscription = 'starter_plus_monthly';
  static const yearlySubscription = 'starter_plus_yearly';
  static const proThemePack = 'theme_pack_pro';
  static const creditPack = 'item_credit_pack_100';

  static const subscriptions = {
    monthlySubscription,
    yearlySubscription,
  };

  static const oneTimePurchases = {
    proThemePack,
    creditPack,
  };

  static const all = {
    ...subscriptions,
    ...oneTimePurchases,
  };

  static bool isConsumable(String productId) => productId == creditPack;
  static bool isSubscription(String productId) =>
      subscriptions.contains(productId);
}

class PaymentService {
  PaymentService(
    this._supabase, {
    bool inAppPurchasesEnabled = true,
  }) : _inAppPurchasesEnabled = inAppPurchasesEnabled;

  final SupabaseClient _supabase;
  final bool _inAppPurchasesEnabled;

  InAppPurchase? _inAppPurchase;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  Future<void> Function()? _onEntitlementsChanged;
  void Function(String message)? _onStatus;

  bool available = false;
  List<ProductDetails> products = const [];

  Future<void> initialize({
    required Future<void> Function() onEntitlementsChanged,
    required void Function(String message) onStatus,
  }) async {
    _onEntitlementsChanged = onEntitlementsChanged;
    _onStatus = onStatus;

    if (!_inAppPurchasesEnabled) {
      available = false;
      products = const [];
      return;
    }

    final inAppPurchase = InAppPurchase.instance;
    _inAppPurchase = inAppPurchase;

    try {
      available = await inAppPurchase.isAvailable();
    } catch (_) {
      available = false;
      products = const [];
      _onStatus?.call('In-app purchases are unavailable on this device.');
      return;
    }

    _purchaseSubscription = inAppPurchase.purchaseStream.listen(
      _handlePurchases,
      onError: (Object error) => _onStatus?.call(error.toString()),
    );

    if (!available) {
      products = const [];
      return;
    }

    try {
      final response =
          await inAppPurchase.queryProductDetails(StoreProductIds.all);
      if (response.error != null) {
        _onStatus?.call(
          response.error!.message.isEmpty
              ? 'In-app purchases are unavailable on this device.'
              : response.error!.message,
        );
      }
      products = response.productDetails;
    } catch (_) {
      available = false;
      products = const [];
      _onStatus?.call('In-app purchases are unavailable on this device.');
    }
  }

  Future<void> buy(ProductDetails product) async {
    final inAppPurchase = _activeInAppPurchase();
    if (inAppPurchase == null) {
      return;
    }

    final purchaseParam = PurchaseParam(productDetails: product);

    if (StoreProductIds.isConsumable(product.id)) {
      await inAppPurchase.buyConsumable(
        autoConsume: true,
        purchaseParam: purchaseParam,
      );
    } else {
      await inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    }
  }

  Future<void> restorePurchases() async {
    final inAppPurchase = _activeInAppPurchase();
    if (inAppPurchase == null) {
      return;
    }

    await inAppPurchase.restorePurchases();
  }

  Future<void> _handlePurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.pending) {
        _onStatus?.call('Purchase pending.');
        continue;
      }

      if (purchase.status == PurchaseStatus.error) {
        _onStatus?.call(purchase.error?.message ?? 'Purchase failed.');
        continue;
      }

      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        await _verifyPurchase(purchase);
        await _onEntitlementsChanged?.call();
      }

      if (purchase.pendingCompletePurchase) {
        await _inAppPurchase?.completePurchase(purchase);
      }
    }
  }

  Future<void> _verifyPurchase(PurchaseDetails purchase) async {
    final productType = StoreProductIds.isSubscription(purchase.productID)
        ? 'subscription'
        : StoreProductIds.isConsumable(purchase.productID)
            ? 'consumable'
            : 'one_time';

    await _supabase.functions.invoke(
      'verify_purchase',
      body: {
        'product_id': purchase.productID,
        'product_type': productType,
        'purchase_id': purchase.purchaseID,
        'status': purchase.status.name,
        'transaction_date': purchase.transactionDate,
        'verification_data': {
          'local': purchase.verificationData.localVerificationData,
          'server': purchase.verificationData.serverVerificationData,
          'source': purchase.verificationData.source,
        },
      },
    );
  }

  void dispose() {
    _purchaseSubscription?.cancel();
  }

  InAppPurchase? _activeInAppPurchase() {
    final inAppPurchase = _inAppPurchase;
    if (!_inAppPurchasesEnabled || !available || inAppPurchase == null) {
      _onStatus?.call('In-app purchases are not available in this build.');
      return null;
    }

    return inAppPurchase;
  }
}
