#!/usr/bin/env node

import fs from 'node:fs/promises';
import path from 'node:path';
import process from 'node:process';
import { createInterface } from 'node:readline/promises';
import { fileURLToPath } from 'node:url';

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(scriptDir, '..');
const args = new Set(process.argv.slice(2));
const nonInteractive = args.has('--defaults') || !process.stdin.isTTY;

const defaultDescription =
  'A basic mobile starter with automatic device-backed accounts, payments, themes, telemetry, ads, optional phone tools, and external service connection placeholders.';

const featureCatalog = [
  {
    defaultSelected: true,
    key: 'automatic_accounts',
    label: 'Device-backed automatic accounts',
    prompt: 'Keep no-login device-backed accounts?',
  },
  {
    defaultSelected: true,
    key: 'subscriptions',
    label: 'Subscriptions',
    prompt: 'Will the app sell subscriptions?',
  },
  {
    defaultSelected: true,
    key: 'one_time_purchases',
    label: 'One-time purchases',
    prompt: 'Will the app sell one-time digital items?',
  },
  {
    defaultSelected: true,
    key: 'themes',
    label: 'Theme switching',
    prompt: 'Should theme switching stay baked in?',
  },
  {
    defaultSelected: true,
    key: 'advertising',
    label: 'Advertising placements',
    prompt: 'Will the app need advertising placements?',
  },
  {
    defaultSelected: true,
    key: 'telemetry',
    label: 'Usage telemetry',
    prompt: 'Will the app collect usage telemetry?',
  },
  {
    defaultSelected: true,
    key: 'owner_dashboard',
    label: 'Owner dashboard',
    prompt: 'Should app-owner analytics stay available?',
  },
];

const capabilityCatalog = [
  {
    body: 'Capture images for profiles, posts, tickets, or records.',
    defaultSelected: true,
    key: 'camera',
    keywords: ['camera', 'photo', 'picture', 'image', 'scan', 'receipt', 'avatar'],
    label: 'Camera',
    prompt: 'Do users need to take photos or use the camera?',
    status: 'Optional permission',
  },
  {
    body: 'Scan codes and open app-specific actions.',
    defaultSelected: true,
    key: 'qr_scanner',
    keywords: ['qr', 'barcode', 'scanner', 'scan code', 'ticket'],
    label: 'QR scanner',
    prompt: 'Do users need QR or barcode scanning?',
    status: 'Camera permission',
  },
  {
    body: 'Record voice notes, search prompts, or short audio clips.',
    defaultSelected: true,
    key: 'microphone',
    keywords: ['microphone', 'mic', 'voice', 'audio', 'recording', 'speech'],
    label: 'Microphone',
    prompt: 'Do users need microphone access?',
    status: 'Optional permission',
  },
  {
    body: 'Read nearby tags, passes, badges, or tap-based actions.',
    defaultSelected: false,
    key: 'nfc',
    keywords: ['nfc', 'near field', 'badge', 'tap card', 'rfid'],
    label: 'NFC',
    prompt: 'Do users need NFC scanning or tap-to-read behavior?',
    status: 'Optional permission',
  },
  {
    body: 'Use current position, maps, geofencing, or local discovery.',
    defaultSelected: false,
    key: 'location',
    keywords: ['location', 'map', 'nearby', 'gps', 'geofence', 'route'],
    label: 'Location',
    prompt: 'Do users need location or map-aware behavior?',
    status: 'Optional permission',
  },
  {
    body: 'Send reminders, alerts, or background follow-ups.',
    defaultSelected: false,
    key: 'push_notifications',
    keywords: ['push', 'notification', 'reminder', 'alert'],
    label: 'Push notifications',
    prompt: 'Do users need push notifications?',
    status: 'Optional permission',
  },
  {
    body: 'Pick images or videos already stored on the device.',
    defaultSelected: false,
    key: 'photo_library',
    keywords: ['gallery', 'photo library', 'upload photo', 'media picker'],
    label: 'Photo library',
    prompt: 'Do users need photo library or media picker access?',
    status: 'Optional permission',
  },
  {
    body: 'Attach documents, imports, exports, or local files.',
    defaultSelected: false,
    key: 'file_picker',
    keywords: ['file', 'document', 'attachment', 'import', 'export', 'pdf'],
    label: 'File picker',
    prompt: 'Do users need to attach or import files?',
    status: 'Optional permission',
  },
  {
    body: 'Find or invite people from the device address book.',
    defaultSelected: false,
    key: 'contacts',
    keywords: ['contacts', 'address book', 'invite friends'],
    label: 'Contacts',
    prompt: 'Do users need contact access?',
    status: 'Optional permission',
  },
  {
    body: 'Read, create, or sync calendar events.',
    defaultSelected: false,
    key: 'calendar',
    keywords: ['calendar', 'schedule', 'booking', 'appointment', 'event'],
    label: 'Calendar',
    prompt: 'Do users need calendar access?',
    status: 'Optional permission',
  },
  {
    body: 'Connect to nearby devices or accessories.',
    defaultSelected: false,
    key: 'bluetooth',
    keywords: ['bluetooth', 'ble', 'beacon', 'nearby device', 'accessory'],
    label: 'Bluetooth',
    prompt: 'Do users need Bluetooth or nearby device access?',
    status: 'Optional permission',
  },
];

const providerCatalog = [
  {
    body: 'Music account, library, and playback-adjacent data.',
    connectionType: 'oauth',
    defaultSelected: true,
    key: 'spotify',
    keywords: ['spotify'],
    label: 'Spotify',
  },
  {
    body: 'Creator profile and media connection.',
    connectionType: 'oauth',
    defaultSelected: true,
    key: 'instagram',
    keywords: ['instagram', 'insta'],
    label: 'Instagram',
  },
  {
    body: 'Creator profile and short-form media connection.',
    connectionType: 'oauth',
    defaultSelected: true,
    key: 'tiktok',
    keywords: ['tiktok', 'tik tok'],
    label: 'TikTok',
  },
  {
    body: 'Video account, channel, or publishing connection.',
    connectionType: 'oauth',
    defaultSelected: false,
    key: 'youtube',
    keywords: ['youtube'],
    label: 'YouTube',
  },
  {
    body: 'Google account, Drive, Sheets, Calendar, or profile connection.',
    connectionType: 'oauth',
    defaultSelected: false,
    key: 'google',
    keywords: ['google', 'gmail', 'drive', 'sheets'],
    label: 'Google',
  },
  {
    body: 'Apple account, Sign in with Apple, or Apple service connection.',
    connectionType: 'oauth',
    defaultSelected: false,
    key: 'apple',
    keywords: ['apple', 'icloud'],
    label: 'Apple',
  },
  {
    body: 'Billing, checkout, or customer portal connection for allowed flows.',
    connectionType: 'api_key',
    defaultSelected: false,
    key: 'stripe',
    keywords: ['stripe', 'checkout', 'invoice'],
    label: 'Stripe',
  },
  {
    body: 'Commerce catalog, store, product, or order connection.',
    connectionType: 'api_key',
    defaultSelected: false,
    key: 'shopify',
    keywords: ['shopify', 'commerce', 'storefront'],
    label: 'Shopify',
  },
  {
    body: 'Team notifications, workspace actions, or message-based workflows.',
    connectionType: 'oauth',
    defaultSelected: false,
    key: 'slack',
    keywords: ['slack'],
    label: 'Slack',
  },
  {
    body: 'Community account, guild, or bot-backed workflows.',
    connectionType: 'oauth',
    defaultSelected: false,
    key: 'discord',
    keywords: ['discord'],
    label: 'Discord',
  },
  {
    body: 'Private partner, webhook, or API-key service.',
    connectionType: 'api_key',
    defaultSelected: true,
    key: 'custom_api',
    keywords: ['api', 'webhook', 'integration'],
    label: 'Custom API',
  },
];

async function main() {
  const rl = nonInteractive
    ? null
    : createInterface({ input: process.stdin, output: process.stdout });

  try {
    const configPath = path.join(repoRoot, 'starter_app.config.json');
    if (!nonInteractive && (await exists(configPath)) && !args.has('--force')) {
      const overwrite = await askYesNo(
        rl,
        'starter_app.config.json already exists. Replace it?',
        false,
      );
      if (!overwrite) {
        console.log('Starter setup cancelled.');
        return;
      }
    }

    const appName = await askText(rl, 'App name', 'Starter App');
    const appDescription = await askText(
      rl,
      'Plain-language app description',
      defaultDescription,
    );
    const platformText = await askText(
      rl,
      'Target platforms',
      'ios, android',
    );
    const platforms = splitList(platformText);

    const inferredCapabilityKeys = inferKeys(capabilityCatalog, appDescription);
    const inferredProviderKeys = inferKeys(providerCatalog, appDescription);

    printSuggestions('Suggested phone tools', inferredCapabilityKeys, capabilityCatalog);
    printSuggestions('Suggested service connections', inferredProviderKeys, providerCatalog);

    const features = await askFeatureSelection(rl);
    const capabilities = await askCapabilitySelection(rl, inferredCapabilityKeys);
    const serviceProviders = await askProviderSelection(rl, inferredProviderKeys);

    const config = {
      generatedAt: new Date().toISOString(),
      app: {
        description: appDescription,
        name: appName,
        platforms,
      },
      features,
      capabilities,
      serviceProviders,
    };

    await fs.writeFile(configPath, `${JSON.stringify(config, null, 2)}\n`);
    await fs.writeFile(
      path.join(repoRoot, 'lib/app/starter_manifest.dart'),
      renderDartManifest(config),
    );
    await fs.mkdir(path.join(repoRoot, 'docs'), { recursive: true });
    await fs.writeFile(
      path.join(repoRoot, 'docs/app-setup-plan.md'),
      renderSetupPlan(config),
    );

    console.log('');
    console.log('Starter setup complete.');
    console.log('- starter_app.config.json');
    console.log('- lib/app/starter_manifest.dart');
    console.log('- docs/app-setup-plan.md');
  } finally {
    rl?.close();
  }
}

async function askFeatureSelection(rl) {
  const selected = [];
  for (const feature of featureCatalog) {
    const enabled = await askYesNo(rl, feature.prompt, feature.defaultSelected);
    if (enabled) {
      selected.push({ key: feature.key, label: feature.label });
    }
  }
  return selected;
}

async function askCapabilitySelection(rl, inferredKeys) {
  const selected = [];
  for (const capability of capabilityCatalog) {
    const defaultValue = nonInteractive
      ? capability.defaultSelected
      : inferredKeys.has(capability.key);
    const enabled = await askYesNo(rl, capability.prompt, defaultValue);
    if (enabled) {
      selected.push(toCapabilityConfig(capability));
    }
  }
  return selected;
}

async function askProviderSelection(rl, inferredKeys) {
  const defaultProviders = nonInteractive
    ? providerCatalog.filter((provider) => provider.defaultSelected)
    : providerCatalog.filter((provider) => inferredKeys.has(provider.key));
  const defaultList = defaultProviders.map((provider) => provider.label).join(', ');
  const hasConnections = await askYesNo(
    rl,
    'Will the app connect to external services?',
    defaultProviders.length > 0,
  );

  if (!hasConnections) {
    return [];
  }

  const providerText = await askText(
    rl,
    'External services, comma separated',
    defaultList || 'Custom API',
  );

  const providers = [];
  for (const name of splitList(providerText)) {
    const provider = providerFromName(name);
    if (!providers.some((item) => item.key === provider.key)) {
      providers.push(provider);
    }
  }
  return providers;
}

function toCapabilityConfig(capability) {
  return {
    body: capability.body,
    key: capability.key,
    name: capability.label,
    status: capability.status,
  };
}

function providerFromName(name) {
  const normalized = normalizeKey(name);
  const matched = providerCatalog.find((provider) => {
    return (
      provider.key === normalized ||
      normalizeKey(provider.label) === normalized ||
      provider.keywords.some((keyword) => normalizeKey(keyword) === normalized)
    );
  });

  if (matched) {
    return {
      body: matched.body,
      connectionType: matched.connectionType,
      key: matched.key,
      name: matched.label,
    };
  }

  return {
    body: 'External service connection selected during starter setup.',
    connectionType: 'oauth',
    key: normalized || 'external_service',
    name,
  };
}

async function askText(rl, prompt, defaultValue) {
  if (nonInteractive) {
    return defaultValue;
  }

  const answer = await rl.question(`${prompt} [${defaultValue}]: `);
  return answer.trim() || defaultValue;
}

async function askYesNo(rl, prompt, defaultValue) {
  if (nonInteractive) {
    return defaultValue;
  }

  const suffix = defaultValue ? 'Y/n' : 'y/N';
  while (true) {
    const answer = (await rl.question(`${prompt} [${suffix}]: `))
      .trim()
      .toLowerCase();
    if (!answer) {
      return defaultValue;
    }
    if (['y', 'yes'].includes(answer)) {
      return true;
    }
    if (['n', 'no'].includes(answer)) {
      return false;
    }
  }
}

function inferKeys(catalog, description) {
  const lowerDescription = description.toLowerCase();
  return new Set(
    catalog
      .filter((item) => {
        return item.keywords.some((keyword) => {
          return lowerDescription.includes(keyword.toLowerCase());
        });
      })
      .map((item) => item.key),
  );
}

function printSuggestions(title, keys, catalog) {
  if (nonInteractive || keys.size === 0) {
    return;
  }

  const labels = catalog
    .filter((item) => keys.has(item.key))
    .map((item) => item.label)
    .join(', ');
  console.log(`${title}: ${labels}`);
}

function splitList(value) {
  return value
    .split(',')
    .map((item) => item.trim())
    .filter(Boolean);
}

function normalizeKey(value) {
  return value
    .trim()
    .toLowerCase()
    .replace(/&/g, ' and ')
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/^_+|_+$/g, '');
}

async function exists(filePath) {
  try {
    await fs.access(filePath);
    return true;
  } catch {
    return false;
  }
}

function renderDartManifest(config) {
  return `// Generated by scripts/configure_starter_app.mjs.
// Do not store secrets here. Use backend configuration for provider credentials.

class StarterManifest {
  const StarterManifest._();

  static const appName = ${dartString(config.app.name)};
  static const appDescription = ${dartString(config.app.description)};

  static const enabledFeatureKeys = <String>[
${config.features.map((feature) => `    ${dartString(feature.key)},`).join('\n')}
  ];

  static const capabilities = <StarterCapability>[
${config.capabilities.map(renderDartCapability).join('\n')}
  ];

  static const serviceProviders = <StarterServiceProvider>[
${config.serviceProviders.map(renderDartProvider).join('\n')}
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
`;
}

function renderDartCapability(capability) {
  return `    StarterCapability(
      body: ${dartString(capability.body)},
      key: ${dartString(capability.key)},
      name: ${dartString(capability.name)},
      status: ${dartString(capability.status)},
    ),`;
}

function renderDartProvider(provider) {
  return `    StarterServiceProvider(
      body: ${dartString(provider.body)},
      connectionType: ${dartString(provider.connectionType)},
      key: ${dartString(provider.key)},
      name: ${dartString(provider.name)},
    ),`;
}

function dartString(value) {
  return JSON.stringify(String(value)).replace(/\$/g, '\\$');
}

function renderSetupPlan(config) {
  const selectedCapabilities = config.capabilities.length
    ? config.capabilities
        .map((capability) => `- ${capability.name}: ${capability.status}`)
        .join('\n')
    : '- None selected';
  const selectedProviders = config.serviceProviders.length
    ? config.serviceProviders
        .map((provider) => `- ${provider.name}: ${provider.connectionType}`)
        .join('\n')
    : '- None selected';
  const selectedFeatures = config.features.length
    ? config.features.map((feature) => `- ${feature.label}`).join('\n')
    : '- None selected';

  return `# App Setup Plan

Generated: ${config.generatedAt}

## App

- Name: ${config.app.name}
- Platforms: ${config.app.platforms.join(', ') || 'Not specified'}
- Description: ${config.app.description}

## Core features

${selectedFeatures}

## Native capabilities

${selectedCapabilities}

Add native packages, Android permissions, and iOS usage descriptions only for the selected
capabilities. QR scanning requires camera access. NFC, Bluetooth, contacts, location, calendar,
photo library, file picker, push notifications, camera, and microphone each need their own
platform-specific review before release.

## External services

${selectedProviders}

OAuth and API-key providers need backend-held credentials, redirect handling, token exchange,
refresh logic, and scoped access before any connection should be marked as connected.

## Next steps

- Run \`node scripts/check_dependency_age.mjs\` before adding packages.
- Keep Supabase schema edits in \`supabase/schema.sql\` during initial setup.
- Treat this plan as the feature filter for the starter app before adding SDKs.
`;
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
