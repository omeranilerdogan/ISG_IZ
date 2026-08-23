-- Faz 5 — Push bildirim: aynı cihaz (aynı FCM token) farklı bir hesapla
-- tekrar giriş yaptığında token'ın önceki kullanıcıya bağlı kalmaması için
-- (aksi halde paylaşılan bir tablet/telefonda eski kullanıcı da bildirim
-- almaya devam eder). RLS `push_tokens_all_own` yalnızca kendi satırını
-- silmeye izin verdiğinden, başka bir kullanıcıya ait aynı token satırını
-- silebilmek için security definer bir RPC gerekir.

create or replace function public.claim_push_token(
  p_token text,
  p_platform public.cihaz_platformu
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  delete from public.push_tokens
  where token = p_token
    and kullanici_id is distinct from auth.uid();

  insert into public.push_tokens (kullanici_id, token, platform)
  values (auth.uid(), p_token, p_platform)
  on conflict (kullanici_id, token) do update set platform = excluded.platform;
end;
$$;

revoke all on function public.claim_push_token(text, public.cihaz_platformu) from public;
grant execute on function public.claim_push_token(text, public.cihaz_platformu) to authenticated;
