class StarterManifest {
  const StarterManifest._();

  static const appName = 'Starter App';
  static const appDescription =
      'A basic mobile starter with automatic device-backed accounts, payments, themes, telemetry, ads, optional phone tools, and external service connection placeholders.';

  static const enabledFeatureKeys = <String>[
    'automatic_accounts',
    'subscriptions',
    'one_time_purchases',
    'themes',
    'advertising',
    'telemetry',
    'owner_dashboard',
  ];

  static const capabilities = <StarterCapability>[
    StarterCapability(
      body: 'Scan codes and open app-specific actions.',
      key: 'qr_scanner',
      name: 'QR scanner',
      status: 'Camera permission',
    ),
    StarterCapability(
      body: 'Capture images for profiles, posts, tickets, or records.',
      key: 'camera',
      name: 'Camera',
      status: 'Optional permission',
    ),
    StarterCapability(
      body: 'Record voice notes, search prompts, or short audio clips.',
      key: 'microphone',
      name: 'Microphone',
      status: 'Optional permission',
    ),
  ];

  static const serviceProviders = <StarterServiceProvider>[
    StarterServiceProvider(
      body: 'Music account, library, and playback-adjacent data.',
      connectionType: 'oauth',
      key: 'spotify',
      name: 'Spotify',
    ),
    StarterServiceProvider(
      body: 'Creator profile and media connection.',
      connectionType: 'oauth',
      key: 'instagram',
      name: 'Instagram',
    ),
    StarterServiceProvider(
      body: 'Creator profile and short-form media connection.',
      connectionType: 'oauth',
      key: 'tiktok',
      name: 'TikTok',
    ),
    StarterServiceProvider(
      body: 'Private partner, webhook, or API-key service.',
      connectionType: 'api_key',
      key: 'custom_api',
      name: 'Custom API',
    ),
  ];
}

class StarterCapability {
  const StarterCapability({
    required this.body,
    required this.key,
    required this.name,
    required this.status,
  });

  final String body;
  final String key;
  final String name;
  final String status;
}

class StarterServiceProvider {
  const StarterServiceProvider({
    required this.body,
    required this.connectionType,
    required this.key,
    required this.name,
  });

  final String body;
  final String connectionType;
  final String key;
  final String name;
}
