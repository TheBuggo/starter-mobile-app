import 'package:flutter/material.dart';
import 'package:riverpod/riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app_config.dart';
import 'app/app_controller.dart';
import 'app/app_providers.dart';
import 'app/starter_app.dart';
import 'services/account_repository.dart';
import 'services/capability_repository.dart';
import 'services/device_identity_service.dart';
import 'services/engagement_repository.dart';
import 'services/payment_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!AppConfig.isSupabaseConfigured) {
    runApp(const SetupRequiredApp());
    return;
  }

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  final SupabaseClient supabase = Supabase.instance.client;
  final AppController controller = AppController(
    accountRepository: AccountRepository(supabase),
    capabilityRepository: CapabilityRepository(supabase),
    deviceIdentityService: const DeviceIdentityService(),
    engagementRepository: EngagementRepository(supabase),
    paymentService: PaymentService(
      supabase,
      inAppPurchasesEnabled: AppConfig.inAppPurchasesEnabled,
    ),
  );

  await controller.bootstrap();

  final ProviderContainer container = ProviderContainer(
    overrides: [
      appControllerProvider.overrideWith((ref) {
        ref.onDispose(controller.dispose);
        return controller;
      }),
    ],
  );

  runApp(StarterApp(container: container));
}
