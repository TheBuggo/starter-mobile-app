# Starter App

A Flutter + Supabase starter for iOS, Android, macOS, and web apps. It starts as a
working app shell with automatic device-backed accounts, account management,
theme tools, purchase hooks, first-party ad placements, app-owned telemetry, and
an owner dashboard.

The native Android, iOS, and macOS project folders are already generated. The
starter is intentionally conservative about optional SDKs and permissions: add
camera, contacts, push notifications, OAuth providers, ads, or billing SDKs only
after the app you are building needs them.

## What is included

- Flutter app shell for iOS, Android, macOS, and Chrome/web.
- Supabase Auth session creation for no-login, device-backed accounts.
- Profile editing for display name, city, profile picture URL, privacy settings,
  and local data clearing.
- Supabase tables for profiles, saved themes, entitlements, app events, ad
  events, optional capabilities, and service connections.
- Subscription and one-time purchase screens wired to placeholder Apple/Google
  in-app purchase product IDs.
- Supabase Edge Function stub for server-side purchase verification.
- Theme builder with saved palettes, seed colors, and light/dark mode.
- First-party ad placement scaffolding for banner, click-through, and rewarded
  flows before an external ad network is added.
- Usage telemetry for screen views, time on screen, navigation, scroll depth,
  lifecycle state, purchases, and ad events.
- Owner dashboard for screen, usage, and ad performance summaries.
- Tools screen for optional QR scanner, camera, microphone, OAuth providers, and
  custom API connection placeholders.
- Riverpod state-management foundation for sharing app-level state.
- Dependency age checker that blocks registry versions published less than 30
  days ago.

## Prerequisites

Install these before the first run:

- Flutter SDK
- Node.js 18 or newer
- Xcode and CocoaPods for iOS/macOS targets
- Android Studio for Android targets
- Docker
- Supabase CLI

## Quick start

Install Flutter packages:

```sh
flutter pub get
```

Start local Supabase:

```sh
npm run supabase:start
```

Create a local Flutter env file:

```sh
cp .env.example .env
```

Keep the local URL from `.env.example`:

```text
SUPABASE_URL=http://127.0.0.1:54321
```

Then set `SUPABASE_ANON_KEY` in `.env` to the local publishable/anon key from
the Supabase CLI output. You can print the current local values with:

```sh
supabase status
```

Run the dependency policy check:

```sh
node scripts/check_dependency_age.mjs
```

Run the app:

```sh
scripts/run_app.sh macos
```

Other targets:

```sh
scripts/run_app.sh chrome
scripts/run_app.sh android
scripts/run_app.sh ios
scripts/run_app.sh phones
scripts/run_app.sh desktop
scripts/run_app.sh all
```

`phones` runs Android and iPhone. `desktop` runs macOS and Chrome. `all` runs
Android, iPhone, macOS, and Chrome.

## State management

Riverpod is included as the starter's state-management foundation. The current
app still keeps cross-cutting app shell state in `AppController`, then exposes
that controller through `appControllerProvider` in `lib/app/app_providers.dart`.
`main.dart` creates a `ProviderContainer`, overrides the provider with the
bootstrapped controller, and `StarterApp` reads the controller from that
container.

This uses the framework-independent `riverpod` package, not `flutter_riverpod`.
That keeps the initial integration small while giving future features a clear
place to add providers for screen, repository, and workflow state. If a feature
needs widgets to watch providers directly, add the Flutter Riverpod integration
under the dependency policy and migrate that feature deliberately.

## Environment files and secrets

Local runtime values belong in `.env`, which is ignored by Git. Commit
`.env.example`, not `.env`.

The Flutter app should only receive:

```text
SUPABASE_URL=
SUPABASE_ANON_KEY=
ENABLE_IN_APP_PURCHASES=false
```

Do not put the Supabase service role key, OAuth client secrets, private API keys,
signing keys, or provider refresh tokens in Flutter code or committed files.
Backend-only credentials belong in Supabase project secrets or your deployment
environment.

For a physical phone, `127.0.0.1` and `10.0.2.2` will not reach your Mac. Use a
LAN address or a tunnel in `.env` so the device can reach Supabase.

The app automatically maps `SUPABASE_URL=http://127.0.0.1:54321` to `10.0.2.2`
when running on an Android emulator.

## Starter setup flow

When adapting this starter into a new app, run the guided setup before adding
optional SDKs or native permissions:

```sh
node scripts/configure_starter_app.mjs
```

For a non-interactive default manifest:

```sh
node scripts/configure_starter_app.mjs --defaults
```

The setup asks for the app description, target platforms, core features, phone
capabilities, and external services. It writes:

- `starter_app.config.json`
- `lib/app/starter_manifest.dart`
- `docs/app-setup-plan.md`

Use those generated files as the current starter decisions. Camera, QR/barcode
scanner, microphone, NFC, location, push notifications, photo library, file
picker, contacts, calendar, Bluetooth, OAuth providers, API-key providers,
webhooks, ads, telemetry, subscriptions, purchases, and owner dashboards should
only receive extra native packages and permissions after this setup says they
are needed.

## Supabase

Local Supabase Studio runs at:

```text
http://127.0.0.1:54323
```

For local automatic accounts, keep anonymous sign-ins enabled in
`supabase/config.toml`. The app treats the Supabase anonymous session as a
device-backed account.

The database model lives in:

```text
supabase/schema.sql
```

During early app setup, edit `supabase/schema.sql` directly for schema changes.
The baseline migration at
`supabase/migrations/20260603000000_initial_schema.sql` mirrors that file so
`supabase db reset` can rebuild a fresh local database. Keep those two files in
sync until you deliberately decide the project needs incremental migration
history.

Keep seed data in `supabase/seed.sql` when useful.

Reset the local database:

```sh
supabase db reset
```

Stop local Supabase:

```sh
npm run supabase:stop
```

Stop Supabase and discard local database volumes:

```sh
npm run nuke
```

You can also use:

```sh
scripts/run_app.sh nuke
```

## Before production

Before shipping an adapted app:

- Change the Android application ID and Apple bundle identifiers from starter
  values to your own app identifiers.
- Configure release signing outside the repository.
- Move hosted Supabase URL/key values into deployment or CI secrets.
- Add real Apple/Google product IDs and receipt validation.
- Add OAuth redirect handling and backend token exchange before enabling provider
  connections.

## Payments

In-app purchases are disabled by default for local development:

```text
ENABLE_IN_APP_PURCHASES=false
```

Leave this off while the starter has placeholder product IDs. Set
`ENABLE_IN_APP_PURCHASES=true` in `.env` only when testing purchases.

Placeholder product IDs:

- `starter_plus_monthly`
- `starter_plus_yearly`
- `theme_pack_pro`
- `item_credit_pack_100`

For iOS Simulator StoreKit testing, open `ios/Runner.xcworkspace` in Xcode and
run the shared `Runner` scheme. The scheme uses
`ios/Runner/Configuration.storekit`, which contains local test products for the
IDs above.

Digital subscriptions and digital items should use Apple/Google in-app
purchases. The mobile app starts purchases, then the Supabase Edge Function
validates receipts and writes entitlements. Store purchase proofs are keyed
globally so reinstalling the app cannot duplicate the same paid transaction onto
multiple accounts.

Deploy the purchase verifier after adding real Apple and Google receipt
validation:

```sh
supabase functions deploy verify_purchase
```

Stripe should be added only for allowed non-digital goods, services, or web
billing flows.

## Optional capabilities and integrations

The Tools screen keeps optional phone access and outside-service links out of the
core account flow. QR scanning, camera capture, and microphone access are listed
as prepared capabilities, but the app does not request those permissions or ship
a camera/mic SDK until a product flow needs one.

External services are tracked in `service_connections`. Spotify, Instagram,
TikTok, and custom API cards create a connection request for the device-backed
account. Add provider credentials, OAuth redirect handling, token exchange,
refresh logic, and provider-specific scopes on the backend before marking any
connection as `connected`.

## Device identity

The app stores a hashed platform device signal, not the raw platform identifier:

- Android uses `Settings.Secure.ANDROID_ID`, scoped to the app signing key,
  Android user, and device on Android 8.0 and newer.
- iOS uses `identifierForVendor`, scoped to the vendor's apps on the device.

These identifiers are account hints, not proof of payment. Paid access still
comes from Apple/Google purchase validation and store restore. For higher-risk
abuse prevention on Android, add Play Integrity API verification on the backend
before enforcing device-level blocks.

## Dependency policy

Do not add or update direct, dev, optional, override/resolution, URL-imported, or
transitive registry package versions until they have been published for at least
30 days. If the publish date cannot be verified from trustworthy registry
metadata, treat the package or version as blocked.

Run this before committing dependency changes:

```sh
flutter pub get
node scripts/check_dependency_age.mjs
```

The checker verifies `pubspec.lock`, npm lockfiles when present, and pinned npm
URL imports used by Supabase Edge Functions. The root `.npmrc` makes future npm
installs save exact versions instead of loose ranges.

## Public repo hygiene

The repo is configured to ignore local env files, build output, IDE state,
assistant instructions/state, mobile signing files, and Supabase local temp
state. Before publishing, run:

```sh
rg --hidden --no-ignore --glob '!build/**' --glob '!.dart_tool/**' --glob '!node_modules/**' "SUPABASE_SERVICE_ROLE_KEY|CLIENT_SECRET|PRIVATE_KEY|API_KEY|ACCESS_TOKEN|REFRESH_TOKEN|PASSWORD|SECRET|BEGIN .*PRIVATE KEY" .
```

Review any matches before pushing. Role names such as `service_role` in SQL and
server-side env reads such as `Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')` are
expected; actual key values are not.

## License

This project is licensed under the MIT License. See `LICENSE` for details.
