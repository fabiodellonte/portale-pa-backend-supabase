begin;

alter table if exists user_profiles
  add column if not exists avatar_url text,
  add column if not exists avatar_meta jsonb not null default '{}'::jsonb;

commit;
