-- Önceki migration'daki `current_setting('app.settings.webhook_secret')`
-- yaklaşımı Supabase'in yönetilen veritabanında "permission denied to set
-- parameter" hatası verdi (custom GUC'lar client rolüyle set edilemiyor).
-- Bunun yerine Supabase Vault kullanılır: sır `vault.decrypted_secrets`
-- görünümünden okunur, gerçek değer ayrı bir (repoya işlenmeyen) komutla
-- `vault.create_secret(...)` ile kurulur.

create extension if not exists supabase_vault;

create or replace function public.bildirimler_push_gonder()
returns trigger
language plpgsql
security definer
set search_path = public, net, vault
as $$
declare
  v_secret text;
begin
  select decrypted_secret into v_secret
  from vault.decrypted_secrets
  where name = 'push_webhook_secret'
  limit 1;

  -- Sır henüz kurulmadıysa (yerel geliştirme / ilk kurulum) sessizce atla.
  if v_secret is null or v_secret = '' then
    return new;
  end if;

  perform net.http_post(
    url := 'https://iotunmotnzfekzuuyido.supabase.co/functions/v1/send-push',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-webhook-secret', v_secret
    ),
    body := jsonb_build_object('record', to_jsonb(new))
  );

  return new;
end;
$$;
