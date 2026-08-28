-- Asıl kök neden: tutanaklar.utt_no globalde UNIQUE idi, ama generate_utt_no()
-- numarayı proje bazlı üretiyor (proje_utt_sayaclari — proje_id, yil, son_sira).
-- Yani farklı iki proje aynı yıl içinde ilk raporunu gönderdiğinde ikisi de
-- "YY/1" üretip global kısıt yüzünden "duplicate key value violates unique
-- constraint tutanaklar_utt_no_key" hatası veriyordu. Kısıt, üretim mantığıyla
-- tutarlı olacak şekilde (proje_id, utt_no) bileşik hale getirilir.

alter table public.tutanaklar drop constraint if exists tutanaklar_utt_no_key;
alter table public.tutanaklar add constraint tutanaklar_proje_utt_no_key unique (proje_id, utt_no);
