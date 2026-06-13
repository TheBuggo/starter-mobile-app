import 'package:flutter/material.dart';
import 'package:riverpod/riverpod.dart';

import '../models/theme_settings.dart';
import '../screens/account_bootstrap_screen.dart';
import '../screens/account_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/home_screen.dart';
import '../screens/setup_required_app.dart';
import '../screens/store_screen.dart';
import '../screens/subscription_screen.dart';
import '../screens/theme_builder_screen.dart';
import '../screens/tools_screen.dart';
import 'app_controller.dart';
import 'app_providers.dart';
import 'starter_manifest.dart';
import 'theme_factory.dart';

class StarterApp extends StatefulWidget {
  const StarterApp({super.key, required this.container});

  final ProviderContainer container;

  @override
  State<StarterApp> createState() => _StarterAppState();
}

class _StarterAppState extends State<StarterApp> {
  late final AppController controller;

  @override
  void initState() {
    super.initState();
    controller = widget.container.read(appControllerProvider);
  }

  @override
  void dispose() {
    widget.container.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: controller.accountReady
              ? SignedInShell(controller: controller)
              : AccountBootstrapScreen(controller: controller),
          theme: ThemeFactory.fromSettings(controller.activeTheme),
          title: StarterManifest.appName,
        );
      },
    );
  }
}

class SetupRequiredApp extends StatelessWidget {
  const SetupRequiredApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const SetupRequiredScreen(),
      theme: ThemeFactory.fromSettings(ThemeSettings.defaultThemes.first),
    );
  }
}

class SignedInShell extends StatefulWidget {
  const SignedInShell({super.key, required this.controller});

  final AppController controller;

  @override
  State<SignedInShell> createState() => _SignedInShellState();
}

class _SignedInShellState extends State<SignedInShell>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    widget.controller.trackAppLifecycle(state.name);
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final tabs = controller.visibleTabs;
    final activeTab = tabs.contains(controller.activeTab)
        ? controller.activeTab
        : AppTab.home;
    final screen = switch (activeTab) {
      AppTab.home => HomeScreen(controller: controller),
      AppTab.plans => SubscriptionScreen(controller: controller),
      AppTab.store => StoreScreen(controller: controller),
      AppTab.tools => ToolsScreen(controller: controller),
      AppTab.themes => ThemeBuilderScreen(controller: controller),
      AppTab.account => AccountScreen(controller: controller),
      AppTab.dashboard => DashboardScreen(controller: controller),
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text(StarterManifest.appName),
        actions: [
          _ThemeMenuButton(controller: controller),
          if (controller.busy)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                  child: SizedBox.square(
                      dimension: 18, child: CircularProgressIndicator())),
            ),
        ],
      ),
      body: SafeArea(child: screen),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tabs.indexOf(activeTab),
        onDestinationSelected: (index) => controller.setActiveTab(tabs[index]),
        destinations: [
          for (final tab in tabs) _destinationFor(tab),
        ],
      ),
    );
  }

  NavigationDestination _destinationFor(AppTab tab) {
    return switch (tab) {
      AppTab.home => const NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
      AppTab.plans => const NavigationDestination(
          icon: Icon(Icons.workspace_premium_outlined),
          selectedIcon: Icon(Icons.workspace_premium),
          label: 'Plans',
        ),
      AppTab.store => const NavigationDestination(
          icon: Icon(Icons.storefront_outlined),
          selectedIcon: Icon(Icons.storefront),
          label: 'Store',
        ),
      AppTab.tools => const NavigationDestination(
          icon: Icon(Icons.extension_outlined),
          selectedIcon: Icon(Icons.extension),
          label: 'Tools',
        ),
      AppTab.themes => const NavigationDestination(
          icon: Icon(Icons.palette_outlined),
          selectedIcon: Icon(Icons.palette),
          label: 'Themes',
        ),
      AppTab.account => const NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Account',
        ),
      AppTab.dashboard => const NavigationDestination(
          icon: Icon(Icons.analytics_outlined),
          selectedIcon: Icon(Icons.analytics),
          label: 'Dashboard',
        ),
    };
  }
}

class _ThemeMenuButton extends StatelessWidget {
  const _ThemeMenuButton({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ThemeSettings>(
      icon: const Icon(Icons.palette_outlined),
      onSelected: controller.selectTheme,
      tooltip: 'Switch theme',
      itemBuilder: (context) {
        return [
          for (final theme in controller.savedThemes)
            PopupMenuItem(
              value: theme,
              child: Row(
                children: [
                  _ThemeMenuSwatch(theme: theme),
                  const SizedBox(width: 12),
                  Expanded(child: Text(theme.name)),
                  if (theme.sameLookAs(controller.activeTheme))
                    const Icon(Icons.check, size: 18),
                ],
              ),
            ),
        ];
      },
    );
  }
}

class _ThemeMenuSwatch extends StatelessWidget {
  const _ThemeMenuSwatch({required this.theme});

  final ThemeSettings theme;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
        color: Color(theme.seedColor),
      ),
      child: SizedBox.square(
        dimension: 22,
        child: theme.darkMode
            ? const Icon(Icons.dark_mode, color: Colors.white, size: 14)
            : null,
      ),
    );
  }
}
