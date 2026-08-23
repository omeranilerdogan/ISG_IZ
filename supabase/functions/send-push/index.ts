// Faz 5 — Push bildirim gönderimi.
// `bildirimler` tablosuna yeni satır eklendiğinde Postgres trigger'ı
// (bkz. 20260823000010_push_gonderim_trigger.sql) bu fonksiyonu pg_net ile
// çağırır ve alıcının kayıtlı push_tokens'larına FCM HTTP v1 API üzerinden
// bildirim gönderilir. Trigger, ortak bir sır (x-webhook-secret) ile
// doğrulanır; bu fonksiyon Supabase Auth JWT'si beklemez (verify_jwt=false).

import { createClient } from "jsr:@supabase/supabase-js@2";

const PROJECT_ID = "isg-uygunsuzluk-tespit";

interface BildirimPayload {
  record: {
    id: string;
    alici_id: string;
    tutanak_id: string | null;
    baslik: string;
    icerik: string | null;
  };
}

function base64UrlEncode(bytes: Uint8Array | string): string {
  const raw = typeof bytes === "string" ? btoa(bytes) : btoa(String.fromCharCode(...bytes));
  return raw.replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

async function getAccessToken(serviceAccount: {
  client_email: string;
  private_key: string;
}): Promise<string> {
  const header = { alg: "RS256", typ: "JWT" };
  const now = Math.floor(Date.now() / 1000);
  const claim = {
    iss: serviceAccount.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  };

  const unsigned = `${base64UrlEncode(JSON.stringify(header))}.${base64UrlEncode(JSON.stringify(claim))}`;

  const pemBody = serviceAccount.private_key
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s/g, "");
  const binaryKey = Uint8Array.from(atob(pemBody), (c) => c.charCodeAt(0));

  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    binaryKey,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );

  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    cryptoKey,
    new TextEncoder().encode(unsigned),
  );

  const jwt = `${unsigned}.${base64UrlEncode(new Uint8Array(signature))}`;

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });

  if (!res.ok) {
    throw new Error(`OAuth token alınamadı: ${res.status} ${await res.text()}`);
  }
  const data = await res.json();
  return data.access_token as string;
}

Deno.serve(async (req) => {
  const beklenenSir = Deno.env.get("WEBHOOK_SECRET");
  if (!beklenenSir || req.headers.get("x-webhook-secret") !== beklenenSir) {
    return new Response("Unauthorized", { status: 401 });
  }

  try {
    const { record: bildirim } = (await req.json()) as BildirimPayload;

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const { data: tokenSatirlari, error } = await supabase
      .from("push_tokens")
      .select("token")
      .eq("kullanici_id", bildirim.alici_id);

    if (error) throw error;
    if (!tokenSatirlari || tokenSatirlari.length === 0) {
      return new Response(JSON.stringify({ gonderildi: 0, toplam: 0 }), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      });
    }

    const serviceAccount = JSON.parse(Deno.env.get("FCM_SERVICE_ACCOUNT_JSON")!);
    const accessToken = await getAccessToken(serviceAccount);

    let basarili = 0;
    for (const { token } of tokenSatirlari) {
      const res = await fetch(
        `https://fcm.googleapis.com/v1/projects/${PROJECT_ID}/messages:send`,
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${accessToken}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            message: {
              token,
              notification: {
                title: bildirim.baslik,
                body: bildirim.icerik ?? "",
              },
              data: {
                tutanak_id: bildirim.tutanak_id ?? "",
                bildirim_id: bildirim.id,
              },
            },
          }),
        },
      );

      if (res.ok) {
        basarili++;
      } else {
        const govde = await res.text();
        // FCM token artık geçersizse (uygulama silinmiş, izin kaldırılmış vb.) temizle.
        if (res.status === 404 || govde.includes("UNREGISTERED")) {
          await supabase.from("push_tokens").delete().eq("token", token);
        }
      }
    }

    return new Response(
      JSON.stringify({ gonderildi: basarili, toplam: tokenSatirlari.length }),
      { status: 200, headers: { "Content-Type": "application/json" } },
    );
  } catch (e) {
    return new Response(JSON.stringify({ hata: String(e) }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
