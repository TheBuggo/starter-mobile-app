# Architecture

This repo now targets Flutter + Supabase.

## Mobile app

- Flutter for native iOS and Android builds from one codebase.
- `supabase_flutter` for automatic app accounts, profile data, saved themes, and entitlement reads.
- `in_app_purchase` for Apple App Store and Google Play purchases.
- First-party ad campaign placements for banner, click-through, and rewarded-video flows.
- App telemetry events for screen views, screen duration, scroll depth, lifecycle state, purchases,
  and ad interactions.
- Optional Tools area for QR scanner, camera, microphone, OAuth provider, and custom API setup.
- Material 3 theme generation from saved `ThemeSettings`, with quick switching available from the
  signed-in app shell.

## Starter setup

New app workspaces should run `node scripts/configure_starter_app.mjs` before adding product-specific
SDKs. The setup asks for a product description, target platforms, core features, phone capabilities,
and external service connections. It writes `starter_app.config.json`, regenerates
`lib/app/starter_manifest.dart`, and creates `docs/app-setup-plan.md`.

The generated manifest is intentionally small and contains no secrets. It controls the app name and
which optional phone tools or service connections appear in the Tools screen. Native dependencies,
platform permissions, OAuth redirect handling, and provider credentials should be added only after
the setup output says the product needs them.

## Backend

- Supabase Auth mints an automatic session on first launch. The app treats that as a device-backed
  account, so users do not need an email or password to enter the app.
- Supabase Postgres stores profile rows, saved themes, user entitlements, ad campaigns, ad events,
  app telemetry events, capability events, and service connection state.
- Supabase Row Level Security lets users read and update their own account data.
- Supabase Edge Functions verify purchase receipts and write entitlements.
- Owner dashboard access is controlled by the `profiles.is_app_owner` flag. Normal users cannot
  write that flag from the app.

## Payments

Digital subscriptions, app themes, and in-app items should use Apple/Google in-app purchases. The
client should never grant permanent access by itself. It starts the purchase, sends receipt data to
`verify_purchase`, and then reads the entitlement table after the server validates the purchase.
The entitlement table uses a global store purchase key, not a per-account purchase key, so the same
store transaction cannot be replayed as multiple paid entitlements after reinstall. Stripe can be
layered in later for non-digital goods, real-world services, or web billing flows.

## Device Identity

The app captures a hashed platform-scoped device signal during automatic account setup. Android uses
`ANDROID_ID`; iOS uses `identifierForVendor`. Raw platform IDs are not stored. These values are
useful for account continuity and abuse heuristics, but payments must remain anchored to validated
store purchases. Android Play Integrity should be layered in before making hard enforcement
decisions about device trust.

## Analytics and ads

The starter captures only app-owned analytics rows. It does not add an external ad SDK yet. That
keeps the default app lightweight while preserving the places where an SDK can be connected later:
banner impressions, click-through ads, and rewarded video completions.

## Optional capabilities and integrations

Camera, QR scanning, and microphone support are represented as optional capabilities before adding
native permissions or SDK dependencies. The app can record that a user prepared one of those
capabilities, and the database keeps those events separate from general telemetry.

Spotify, Instagram, TikTok, and custom API hooks use `service_connections` rows. The starter records
connection requests and status, while real OAuth/client credential setup should live behind backend
configuration and provider-specific token exchange before a row is marked connected.

## Scaling path

Start with Supabase Free while validating. Move to Supabase Pro when the project needs production
stability. If file storage or image bandwidth becomes the cost driver later, move heavy files to
Cloudflare R2 while keeping Supabase for auth and relational data.
