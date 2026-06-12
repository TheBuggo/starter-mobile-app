import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.49.1';

type PurchaseRequest = {
  product_id: string;
  product_type: 'subscription' | 'one_time' | 'consumable';
  purchase_id?: string;
  status: string;
  transaction_date?: string;
  verification_data: {
    local?: string;
    server?: string;
    source?: string;
  };
};

Deno.serve(async (request) => {
  const authHeader = request.headers.get('Authorization');

  if (!authHeader) {
    return json({ error: 'Missing authorization header' }, 401);
  }

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  );

  const userClient = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_ANON_KEY')!,
    { global: { headers: { Authorization: authHeader } } },
  );

  const { data: authData, error: authError } = await userClient.auth.getUser();
  if (authError || !authData.user) {
    return json({ error: 'Invalid user session' }, 401);
  }

  const body = (await request.json()) as PurchaseRequest;
  const provider = body.verification_data.source ?? 'app_store_or_play';
  const purchaseProof =
    body.purchase_id ??
    body.verification_data.server ??
    body.verification_data.local;

  if (!purchaseProof) {
    return json({ error: 'Missing purchase proof' }, 400);
  }

  const purchaseKey = await sha256(`${provider}:${body.product_id}:${purchaseProof}`);

  // Production work belongs here:
  // - Validate Apple App Store receipts against Apple's API.
  // - Validate Google Play purchase tokens against Google's API.
  // - Reject mismatched product IDs and suspicious account transfers.
  // - Set real subscription expiration dates from provider response.
  const expiresAt =
    body.product_type === 'subscription'
      ? new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString()
      : null;

  const { error } = await supabase.from('user_entitlements').upsert(
    {
      active: body.status === 'purchased' || body.status === 'restored',
      expires_at: expiresAt,
      product_id: body.product_id,
      product_type: body.product_type,
      provider,
      purchase_id: body.purchase_id ?? null,
      purchase_key: purchaseKey,
      updated_at: new Date().toISOString(),
      user_id: authData.user.id,
    },
    { onConflict: 'provider,purchase_key' },
  );

  if (error) {
    return json({ error: error.message }, 500);
  }

  return json({ ok: true });
});

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    headers: { 'Content-Type': 'application/json' },
    status,
  });
}

async function sha256(value: string) {
  const data = new TextEncoder().encode(value);
  const digest = await crypto.subtle.digest('SHA-256', data);
  return [...new Uint8Array(digest)]
    .map((byte) => byte.toString(16).padStart(2, '0'))
    .join('');
}
