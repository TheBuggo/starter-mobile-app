insert into public.ad_campaigns (
  slug,
  placement_key,
  campaign_type,
  title,
  body,
  cta_label,
  target_url,
  reward_key,
  reward_quantity,
  priority
) values
  (
    'starter-home-banner',
    'home_banner',
    'banner',
    'Featured partner',
    'Reserve this space for a sponsor, internal promotion, or house ad.',
    'View offer',
    'https://example.com',
    null,
    0,
    10
  ),
  (
    'starter-store-click',
    'store_click',
    'click_out',
    'Click-through placement',
    'Track impressions and clicks before wiring a paid ad network.',
    'Open sponsor',
    'https://example.com',
    null,
    0,
    20
  ),
  (
    'starter-rewarded-video',
    'store_rewarded',
    'rewarded_video',
    'Rewarded video',
    'Use this placement for watch-to-earn flows after an ad SDK is connected.',
    'Watch',
    null,
    'item_credit',
    1,
    30
  )
on conflict (slug) do nothing;
