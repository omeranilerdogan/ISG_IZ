-- İSG Uygunsuzluk Tespit Tutanağı — Uzantılar ve Enum Tipleri
-- Teknik Analiz Bölüm 9

create extension if not exists "pgcrypto";

create type public.kullanici_rolu as enum (
  'admin',
  'isg_uzmani',
  'santiye_sefi',
  'personel'
);

create type public.tehlike_sinifi as enum ('A', 'B', 'C');

create type public.tutanak_durumu as enum (
  'taslak',
  'gonderildi',
  'incelemede',
  'revizyon_istendi',
  'onaylandi',
  'reddedildi',
  'kapatildi'
);

create type public.firma_turu as enum ('ana_yuklenici', 'taseron');

create type public.cihaz_platformu as enum ('android', 'ios', 'web');
