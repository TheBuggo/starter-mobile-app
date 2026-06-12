import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/ad_campaign.dart';
import '../models/app_user_profile.dart';
import '../models/owner_dashboard_summary.dart';
import '../models/service_connection.dart';
import '../models/theme_settings.dart';
import '../models/user_entitlement.dart';
import '../services/account_repository.dart';
import '../services/capability_repository.dart';
import '../services/device_identity_service.dart';
import '../services/engagement_repository.dart';
import '../services/payment_service.dart';

enum AppTab { home, plans, store, tools, themes, account, dashboard }

class AppController extends ChangeNotifier {
  AppController({
    required AccountRepository accountRepository,
    required CapabilityRepository capabilityRepository,
    required DeviceIdentityService deviceIdentityService,
    required EngagementRepository engagementRepository,
    required PaymentService paymentService,
  })  : _accountRepository = accountRepository,
        _capabilityRepository = capabilityRepository,
        _deviceIdentityService = deviceIdentityService,
        _engagementRepository = engagementRepository,
        _paymentService = paymentService;

  final AccountRepository _accountRepository;
  final CapabilityRepository _capabilityRepository;
  final DeviceIdentityService _deviceIdentityService;
  final EngagementRepository _engagementRepository;
  final PaymentService _paymentService;

  StreamSubscription<AuthState>? _authSubscription;
  final String _sessionId = DateTime.now().microsecondsSinceEpoch.toString();
  bool _restoreSyncRequested = false;
  AppTab? _trackedTab;
  DateTime? _screenEnteredAt;

  AppTab activeTab = AppTab.home;
  List<AdCampaign> adCampaigns = const [];
  AppUserProfile? profile;
  ThemeSettings activeTheme = ThemeSettings.defaultThemes.first;
  List<ThemeSettings> savedThemes = ThemeSettings.defaultThemes;
  List<UserEntitlement> entitlements = const [];
  OwnerDashboardSummary? ownerDashboard;
  List<ProductDetails> products = const [];
  Set<String> preparedCapabilities = const {};
  List<ServiceConnection> serviceConnections = const [];
  bool accountReady = false;
  bool busy = false;
  bool paymentsAvailable = false;
  String? statusMessage;

  bool get isSignedIn => _accountRepository.currentUser != null;
  bool get isAppOwner => profile?.isAppOwner ?? false;
  bool get telemetryEnabled => profile?.telemetryEnabled ?? false;
  User? get currentUser => _accountRepository.currentUser;
  List<AppTab> get visibleTabs {
    return [
      AppTab.home,
      AppTab.plans,
      AppTab.store,
      AppTab.tools,
      AppTab.themes,
      AppTab.account,
      if (isAppOwner) AppTab.dashboard,
    ];
  }

  String get accountIdentity {
    final currentProfile = profile;
    if (currentProfile == null) {
      return '';
    }
    if (currentProfile.phone.isNotEmpty) {
      return currentProfile.phone;
    }
    if (currentProfile.email.isEmpty) {
      return 'This device';
    }
    return currentProfile.email;
  }

  String labelForTab(AppTab tab) {
    return switch (tab) {
      AppTab.home => 'Home',
      AppTab.plans => 'Plans',
      AppTab.store => 'Store',
      AppTab.tools => 'Tools',
      AppTab.themes => 'Themes',
      AppTab.account => 'Account',
      AppTab.dashboard => 'Dashboard',
    };
  }

  ProductDetails? productById(String productId) {
    for (final product in products) {
      if (product.id == productId) {
        return product;
      }
    }
    return null;
  }

  bool hasActiveEntitlement(String productId) {
    return entitlements
        .any((item) => item.productId == productId && item.active);
  }

  AdCampaign? campaignForPlacement(String placementKey) {
    for (final campaign in adCampaigns) {
      if (campaign.placementKey == placementKey && campaign.active) {
        return campaign;
      }
    }
    return null;
  }

  ServiceConnection? serviceConnectionFor(String providerKey) {
    for (final connection in serviceConnections) {
      if (connection.providerKey == providerKey) {
        return connection;
      }
    }
    return null;
  }

  bool capabilityPrepared(String capabilityKey) {
    return preparedCapabilities.contains(capabilityKey);
  }

  Future<void> bootstrap() async {
    _authSubscription = _accountRepository.authState.listen((event) async {
      if (event.session?.user == null) {
        _clearAccountState();
      } else {
        await refreshAccount();
      }
      notifyListeners();
    });

    await _paymentService.initialize(
      onEntitlementsChanged: refreshEntitlements,
      onStatus: setStatus,
    );

    paymentsAvailable = _paymentService.available;
    products = _paymentService.products;

    await ensureAutomaticAccount();

    notifyListeners();
  }

  Future<void> ensureAutomaticAccount() async {
    await _runBusy(() async {
      final deviceIdentity = await _deviceIdentityService.load();
      await _accountRepository.ensureSignedIn(deviceIdentity: deviceIdentity);
      await refreshAccount();
      await _syncRestorablePurchases();
      accountReady = true;
      statusMessage = null;
      _startScreenTracking(activeTab);
    });
  }

  Future<void> refreshAccount() async {
    final user = currentUser;
    if (user == null) {
      _clearAccountState();
      return;
    }

    profile = await _accountRepository.ensureProfile(user);
    savedThemes = [
      ...ThemeSettings.defaultThemes,
      ...await _accountRepository.loadThemePresets(user.id),
    ];
    activeTheme = profile?.theme ?? activeTheme;
    await refreshEntitlements();
    await refreshAds();
    await refreshCapabilityData();
    if (isAppOwner) {
      await refreshOwnerDashboard();
    } else {
      ownerDashboard = null;
      if (activeTab == AppTab.dashboard) {
        activeTab = AppTab.home;
      }
    }
    _startScreenTracking(activeTab);
  }

  Future<void> refreshEntitlements() async {
    final user = currentUser;
    if (user == null) {
      entitlements = const [];
    } else {
      entitlements = await _accountRepository.loadEntitlements(user.id);
    }
    notifyListeners();
  }

  Future<void> updateProfile({
    required String displayName,
    required String city,
    required String avatarUrl,
  }) async {
    await _runBusy(() async {
      final nextProfile = profile?.copyWith(
        avatarUrl: avatarUrl.trim().isEmpty ? null : avatarUrl.trim(),
        city: city.trim().isEmpty ? null : city.trim(),
        displayName: displayName.trim(),
        theme: activeTheme,
      );

      if (nextProfile == null) {
        return;
      }

      profile = await _accountRepository.updateProfile(nextProfile);
      statusMessage = 'Account updated.';
    });
  }

  Future<void> updateTelemetryEnabled(bool enabled) async {
    await _runBusy(() async {
      final currentProfile = profile;
      if (currentProfile == null) {
        return;
      }

      if (!enabled && currentProfile.telemetryEnabled) {
        await trackEvent('telemetry_disabled', screenName: 'Account');
        _recordScreenExit();
      }

      profile = await _accountRepository.updateProfile(
        currentProfile.copyWith(telemetryEnabled: enabled),
      );

      if (enabled) {
        await trackEvent('telemetry_enabled', screenName: 'Account');
        _startScreenTracking(activeTab);
      }

      statusMessage =
          enabled ? 'Usage analytics enabled.' : 'Usage analytics disabled.';
    });
  }

  Future<void> clearCachedData() async {
    await _runBusy(() async {
      entitlements = const [];
      adCampaigns = const [];
      preparedCapabilities = const {};
      serviceConnections = const [];
      ownerDashboard = null;
      savedThemes = ThemeSettings.defaultThemes;
      activeTheme = ThemeSettings.defaultThemes.first;
      await refreshAccount();
      statusMessage = 'Cached app data cleared.';
    });
  }

  Future<void> saveTheme(ThemeSettings theme) async {
    await _runBusy(() async {
      activeTheme = theme;
      if (profile != null) {
        profile = await _accountRepository
            .updateProfile(profile!.copyWith(theme: theme));
      }
      await _accountRepository.saveThemePreset(theme);
      savedThemes = [
        ...ThemeSettings.defaultThemes,
        ...await _accountRepository.loadThemePresets(currentUser!.id),
      ];
      statusMessage = 'Theme saved.';
    });
  }

  Future<void> selectTheme(ThemeSettings theme) async {
    await _runBusy(() async {
      activeTheme = theme;
      if (profile != null) {
        profile = await _accountRepository
            .updateProfile(profile!.copyWith(theme: theme));
      }
    });
  }

  Future<void> buyProduct(ProductDetails product) async {
    await _runBusy(() async {
      await trackEvent(
        'purchase_started',
        screenName: labelForTab(activeTab),
        target: product.id,
      );
      await _paymentService.buy(product);
      statusMessage = 'Purchase started.';
    });
  }

  Future<void> restorePurchases() async {
    await _runBusy(() async {
      await trackEvent('purchase_restore_requested',
          screenName: labelForTab(activeTab));
      await _paymentService.restorePurchases();
      statusMessage = 'Restore requested.';
    });
  }

  Future<void> _syncRestorablePurchases() async {
    if (_restoreSyncRequested || !paymentsAvailable) {
      return;
    }

    _restoreSyncRequested = true;

    try {
      await _paymentService.restorePurchases();
    } catch (error) {
      debugPrint('Store restore sync failed: $error');
    }
  }

  Future<void> refreshAds() async {
    if (!isSignedIn) {
      adCampaigns = const [];
      return;
    }

    adCampaigns = await _engagementRepository.loadActiveCampaigns();
    notifyListeners();
  }

  Future<void> refreshCapabilityData() async {
    final user = currentUser;
    if (user == null) {
      preparedCapabilities = const {};
      serviceConnections = const [];
      return;
    }

    preparedCapabilities =
        await _capabilityRepository.loadPreparedCapabilities(user.id);
    serviceConnections =
        await _capabilityRepository.loadServiceConnections(user.id);
    notifyListeners();
  }

  Future<void> prepareCapability({
    required String capabilityKey,
    required String capabilityName,
  }) async {
    await _runBusy(() async {
      await _capabilityRepository.recordCapabilityEvent(
        capabilityKey: capabilityKey,
        eventType: 'prepared',
        metadata: {'capability_name': capabilityName},
      );
      await trackEvent(
        'capability_prepared',
        metadata: {'capability_name': capabilityName},
        screenName: labelForTab(activeTab),
        target: capabilityKey,
      );
      preparedCapabilities = {...preparedCapabilities, capabilityKey};
      statusMessage = '$capabilityName is marked as ready to add.';
    });
  }

  Future<void> requestServiceConnection({
    required String connectionType,
    required String providerKey,
    required String providerName,
    List<String> scopes = const [],
  }) async {
    await _runBusy(() async {
      final connection = await _capabilityRepository.requestServiceConnection(
        connectionType: connectionType,
        providerKey: providerKey,
        providerName: providerName,
        scopes: scopes,
      );

      if (connection != null) {
        serviceConnections = [
          connection,
          for (final item in serviceConnections)
            if (item.providerKey != providerKey) item,
        ];
      }

      await trackEvent(
        'service_connection_requested',
        metadata: {
          'connection_type': connectionType,
          'provider_name': providerName,
        },
        screenName: labelForTab(activeTab),
        target: providerKey,
      );
      statusMessage = '$providerName connection saved for setup.';
    });
  }

  Future<void> refreshOwnerDashboard() async {
    if (!isAppOwner) {
      ownerDashboard = null;
      notifyListeners();
      return;
    }

    ownerDashboard = await _engagementRepository.loadOwnerDashboard();
    notifyListeners();
  }

  Future<void> recordAdImpression(AdCampaign campaign) async {
    try {
      await _engagementRepository.recordAdEvent(
        campaign: campaign,
        eventType: 'impression',
      );
    } catch (error) {
      debugPrint('Ad impression event failed: $error');
    }
  }

  Future<void> recordAdClick(AdCampaign campaign) async {
    try {
      await _engagementRepository.recordAdEvent(
        campaign: campaign,
        eventType: 'click',
      );
    } catch (error) {
      debugPrint('Ad click event failed: $error');
    }
    await trackEvent(
      'ad_click',
      screenName: labelForTab(activeTab),
      target: campaign.slug,
    );

    final target = campaign.targetUrl;
    final uri = target == null ? null : Uri.tryParse(target);
    if (uri == null || !uri.hasScheme) {
      statusMessage = 'This ad does not have a destination yet.';
      notifyListeners();
      return;
    }

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> recordAdReward(AdCampaign campaign) async {
    try {
      await _engagementRepository.recordAdEvent(
        campaign: campaign,
        eventType: 'reward_earned',
        metadata: {
          'reward_key': campaign.rewardKey,
          'reward_quantity': campaign.rewardQuantity,
        },
      );
    } catch (error) {
      debugPrint('Ad reward event failed: $error');
    }
    await trackEvent(
      'ad_reward_earned',
      metadata: {
        'reward_key': campaign.rewardKey,
        'reward_quantity': campaign.rewardQuantity,
      },
      screenName: labelForTab(activeTab),
      target: campaign.slug,
    );
    statusMessage = campaign.rewardQuantity > 0
        ? 'Reward earned: ${campaign.rewardQuantity} ${campaign.rewardKey ?? 'credit'}.'
        : 'Reward earned.';
    notifyListeners();
  }

  Future<void> trackEvent(
    String eventType, {
    int? durationMs,
    Map<String, dynamic> metadata = const {},
    String? screenName,
    int? scrollDepth,
    String? target,
  }) async {
    if (!isSignedIn || !telemetryEnabled) {
      return;
    }

    try {
      await _engagementRepository.recordAppEvent(
        durationMs: durationMs,
        eventType: eventType,
        metadata: metadata,
        screenName: screenName,
        scrollDepth: scrollDepth,
        sessionId: _sessionId,
        target: target,
      );
    } catch (error) {
      debugPrint('Telemetry event failed: $error');
    }
  }

  void trackScrollDepth(String screenName, int scrollDepth) {
    unawaited(
      trackEvent(
        'scroll_depth',
        screenName: screenName,
        scrollDepth: scrollDepth,
      ),
    );
  }

  void trackAppLifecycle(String state) {
    unawaited(
      trackEvent(
        'app_lifecycle',
        metadata: {'state': state},
        screenName: labelForTab(activeTab),
      ),
    );

    if (state == 'paused' || state == 'inactive' || state == 'hidden') {
      _recordScreenExit();
    } else if (state == 'resumed') {
      _startScreenTracking(activeTab);
    }
  }

  void setActiveTab(AppTab tab) {
    if (!visibleTabs.contains(tab)) {
      tab = AppTab.home;
    }
    if (tab == activeTab) {
      return;
    }

    _recordScreenExit();
    unawaited(
      trackEvent(
        'navigation_click',
        screenName: labelForTab(activeTab),
        target: labelForTab(tab),
      ),
    );
    activeTab = tab;
    _startScreenTracking(tab);
    notifyListeners();
  }

  void setStatus(String message) {
    statusMessage = message;
    notifyListeners();
  }

  Future<void> _runBusy(Future<void> Function() action) async {
    busy = true;
    statusMessage = null;
    notifyListeners();

    try {
      await action();
    } on AuthException catch (error) {
      statusMessage = error.message;
    } on PostgrestException catch (error) {
      statusMessage = error.message;
    } catch (error) {
      statusMessage = error.toString();
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  void _clearAccountState() {
    accountReady = false;
    _screenEnteredAt = null;
    _trackedTab = null;
    adCampaigns = const [];
    profile = null;
    entitlements = const [];
    preparedCapabilities = const {};
    serviceConnections = const [];
    ownerDashboard = null;
    activeTheme = ThemeSettings.defaultThemes.first;
    savedThemes = ThemeSettings.defaultThemes;
  }

  void _startScreenTracking(AppTab tab) {
    if (!isSignedIn || !telemetryEnabled || _trackedTab == tab) {
      return;
    }

    _trackedTab = tab;
    _screenEnteredAt = DateTime.now();
    unawaited(trackEvent('screen_view', screenName: labelForTab(tab)));
  }

  void _recordScreenExit() {
    final trackedTab = _trackedTab;
    final enteredAt = _screenEnteredAt;
    if (trackedTab == null || enteredAt == null) {
      return;
    }

    _trackedTab = null;
    _screenEnteredAt = null;
    final durationMs = DateTime.now().difference(enteredAt).inMilliseconds;
    if (durationMs <= 0) {
      return;
    }

    unawaited(
      trackEvent(
        'screen_exit',
        durationMs: durationMs,
        screenName: labelForTab(trackedTab),
      ),
    );
  }

  @override
  void dispose() {
    _recordScreenExit();
    _authSubscription?.cancel();
    _paymentService.dispose();
    super.dispose();
  }
}
