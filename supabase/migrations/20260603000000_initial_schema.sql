create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  phone text not null default '',
  display_name text not null default '',
  avatar_url text,
  city text,
  device_platform text,
  device_identifier_kind text,
  device_identifier_hash text,
  telemetry_enabled boolean not null default true,
  is_app_owner boolean not null default false,
  theme_name text not null default 'Ocean',
  theme_seed_color bigint not null default 4280649451,
  theme_dark_mode boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.theme_presets (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  seed_color bigint not null,
  dark_mode boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, name)
);

create table if not exists public.user_entitlements (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  product_id text not null,
  product_type text not null check (product_type in ('subscription', 'one_time', 'consumable')),
  active boolean not null default true,
  expires_at timestamptz,
  purchase_id text,
  purchase_key text not null,
  provider text not null default 'app_store_or_play',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (provider, purchase_key)
);

create table if not exists public.ad_campaigns (
  id bigint generated always as identity primary key,
  slug text not null unique,
  placement_key text not null,
  campaign_type text not null check (campaign_type in ('banner', 'click_out', 'rewarded_video')),
  title text not null,
  body text not null default '',
  cta_label text not null default 'Learn more',
  image_url text,
  target_url text,
  reward_key text,
  reward_quantity integer not null default 0,
  active boolean not null default true,
  priority integer not null default 100,
  starts_at timestamptz,
  ends_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.ad_events (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  campaign_id bigint not null references public.ad_campaigns(id) on delete cascade,
  placement_key text not null,
  event_type text not null check (event_type in ('impression', 'click', 'reward_earned', 'dismissed')),
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.app_events (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  session_id text not null,
  event_type text not null,
  screen_name text,
  target text,
  duration_ms integer,
  scroll_depth integer,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.capability_events (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  capability_key text not null,
  event_type text not null check (
    event_type in ('opened', 'prepared', 'permission_requested')
  ),
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.service_connections (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  provider_key text not null,
  provider_name text not null,
  connection_type text not null check (
    connection_type in ('oauth', 'api_key', 'webhook', 'manual')
  ),
  status text not null default 'needs_setup' check (
    status in ('needs_setup', 'requested', 'connected', 'disconnected')
  ),
  external_account_label text,
  scopes text[] not null default '{}',
  metadata jsonb not null default '{}'::jsonb,
  connected_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, provider_key)
);

create index if not exists ad_campaigns_active_placement_idx
  on public.ad_campaigns (active, placement_key, priority);

create index if not exists ad_events_campaign_created_idx
  on public.ad_events (campaign_id, created_at desc);

create index if not exists app_events_user_created_idx
  on public.app_events (user_id, created_at desc);

create index if not exists app_events_screen_created_idx
  on public.app_events (screen_name, created_at desc);

create index if not exists capability_events_user_created_idx
  on public.capability_events (user_id, created_at desc);

create index if not exists service_connections_user_provider_idx
  on public.service_connections (user_id, provider_key);

alter table public.profiles enable row level security;
alter table public.theme_presets enable row level security;
alter table public.user_entitlements enable row level security;
alter table public.ad_campaigns enable row level security;
alter table public.ad_events enable row level security;
alter table public.app_events enable row level security;
alter table public.capability_events enable row level security;
alter table public.service_connections enable row level security;

create policy "Profiles are readable by owner"
  on public.profiles for select
  using (auth.uid() = id);

create policy "Profiles are insertable by owner"
  on public.profiles for insert
  with check (auth.uid() = id);

create policy "Profiles are updateable by owner"
  on public.profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

create policy "Theme presets are readable by owner"
  on public.theme_presets for select
  using (auth.uid() = user_id);

create policy "Theme presets are insertable by owner"
  on public.theme_presets for insert
  with check (auth.uid() = user_id);

create policy "Theme presets are updateable by owner"
  on public.theme_presets for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Entitlements are readable by owner"
  on public.user_entitlements for select
  using (auth.uid() = user_id);

create policy "Active ad campaigns are readable by users"
  on public.ad_campaigns for select
  using (
    active
    and (starts_at is null or starts_at <= now())
    and (ends_at is null or ends_at >= now())
  );

create policy "App owners can manage ad campaigns"
  on public.ad_campaigns for all
  using (
    exists (
      select 1 from public.profiles
      where profiles.id = auth.uid()
        and profiles.is_app_owner
    )
  )
  with check (
    exists (
      select 1 from public.profiles
      where profiles.id = auth.uid()
        and profiles.is_app_owner
    )
  );

create policy "Users can record ad events"
  on public.ad_events for insert
  with check (auth.uid() = user_id);

create policy "Users can read their ad events"
  on public.ad_events for select
  using (auth.uid() = user_id);

create policy "App owners can read ad events"
  on public.ad_events for select
  using (
    exists (
      select 1 from public.profiles
      where profiles.id = auth.uid()
        and profiles.is_app_owner
    )
  );

create policy "Users can record app events"
  on public.app_events for insert
  with check (
    auth.uid() = user_id
    and exists (
      select 1 from public.profiles
      where profiles.id = auth.uid()
        and profiles.telemetry_enabled
    )
  );

create policy "Users can read their app events"
  on public.app_events for select
  using (auth.uid() = user_id);

create policy "App owners can read app events"
  on public.app_events for select
  using (
    exists (
      select 1 from public.profiles
      where profiles.id = auth.uid()
        and profiles.is_app_owner
    )
  );

create policy "Users can record capability events"
  on public.capability_events for insert
  with check (auth.uid() = user_id);

create policy "Users can read their capability events"
  on public.capability_events for select
  using (auth.uid() = user_id);

create policy "App owners can read capability events"
  on public.capability_events for select
  using (
    exists (
      select 1 from public.profiles
      where profiles.id = auth.uid()
        and profiles.is_app_owner
    )
  );

create policy "Service connections are readable by owner"
  on public.service_connections for select
  using (auth.uid() = user_id);

create policy "Service connections are insertable by owner"
  on public.service_connections for insert
  with check (auth.uid() = user_id);

create policy "Service connections are updateable by owner"
  on public.service_connections for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "App owners can read service connections"
  on public.service_connections for select
  using (
    exists (
      select 1 from public.profiles
      where profiles.id = auth.uid()
        and profiles.is_app_owner
    )
  );

revoke all on all tables in schema public from anon, authenticated, service_role;
revoke all on all sequences in schema public from anon, authenticated, service_role;

grant usage on schema public to anon, authenticated, service_role;
grant select on public.profiles to authenticated;
grant insert (
  id,
  email,
  phone,
  display_name,
  avatar_url,
  city,
  device_platform,
  device_identifier_kind,
  device_identifier_hash,
  telemetry_enabled,
  theme_name,
  theme_seed_color,
  theme_dark_mode,
  updated_at
) on public.profiles to authenticated;
grant update (
  email,
  phone,
  display_name,
  avatar_url,
  city,
  device_platform,
  device_identifier_kind,
  device_identifier_hash,
  telemetry_enabled,
  theme_name,
  theme_seed_color,
  theme_dark_mode,
  updated_at
) on public.profiles to authenticated;
grant select, insert, update, delete on public.profiles to service_role;
grant select, insert, update, delete on public.theme_presets to authenticated;
grant select on public.user_entitlements to authenticated;
grant select, insert, update, delete on public.user_entitlements to service_role;
grant select, insert, update, delete on public.ad_campaigns to authenticated;
grant select, insert, update, delete on public.ad_campaigns to service_role;
grant select, insert on public.ad_events to authenticated;
grant select, insert, update, delete on public.ad_events to service_role;
grant select, insert on public.app_events to authenticated;
grant select, insert, update, delete on public.app_events to service_role;
grant select, insert on public.capability_events to authenticated;
grant select, insert, update, delete on public.capability_events to service_role;
grant select, insert, update on public.service_connections to authenticated;
grant select, insert, update, delete on public.service_connections to service_role;
grant usage, select on all sequences in schema public to authenticated, service_role;
