-- Faz 5 — `bildirimler` tablosuna yeni satır eklendiğinde (bkz.
-- tutanaklar_notify() trigger'ı) `send-push` Edge Function'ını pg_net ile
-- çağırıp FCM push bildirimi tetikler. Fonksiyon çağrısı, Postgres'ten
-- gelen isteği doğrulamak için ortak bir sır (x-webhook-secret) taşır; bu
-- sır güvenlik nedeniyle bu dosyada DEĞİL, ayrı bir `alter database ...
-- set app.settings.webhook_secret` komutuyla (repoya işlenmeden) kurulur —
-- bkz. README "Push Bildirim (Faz 5) Kurulumu".

create extension if not exists pg_net;

create or replace function public.bildirimler_push_gonder()
returns trigger
language plpgsql
security definer
set search_path = public, net
as $$
declare
  v_secret text := current_setting('app.settings.webhook_secret', true);
begin
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

drop trigger if exists bildirimler_after_insert_push on public.bildirimler;
create trigger bildirimler_after_insert_push
  after insert on public.bildirimler
  for each row execute function public.bildirimler_push_gonder();
