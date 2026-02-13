create extension if not exists pgcrypto;

create table if not exists tenants (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  codice_fiscale_ente text unique,
  created_at timestamptz not null default now()
);

create table if not exists roles (
  id uuid primary key default gen_random_uuid(),
  code text unique not null,
  name text not null
);

create table if not exists user_profiles (
  id uuid primary key,
  tenant_id uuid not null references tenants(id) on delete cascade,
  full_name text,
  created_at timestamptz not null default now()
);

create table if not exists user_roles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references user_profiles(id) on delete cascade,
  role_id uuid not null references roles(id) on delete cascade,
  unique(user_id, role_id)
);

create table if not exists pratiche (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references tenants(id) on delete cascade,
  codice text not null,
  titolo text not null,
  descrizione text,
  stato text not null default 'bozza',
  created_by uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(tenant_id, codice)
);

create table if not exists pratica_events (
  id uuid primary key default gen_random_uuid(),
  pratica_id uuid not null references pratiche(id) on delete cascade,
  event_type text not null,
  payload jsonb not null default '{}'::jsonb,
  created_by uuid,
  created_at timestamptz not null default now()
);

create table if not exists audit_log (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid references tenants(id) on delete cascade,
  actor_id uuid,
  action text not null,
  entity_type text not null,
  entity_id uuid,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

-- Civic reporting domain (segnalazioni)
create table if not exists segnalazione_categories (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references tenants(id) on delete cascade,
  slug text not null,
  name text not null,
  description text,
  color text,
  icon text,
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_by uuid,
  updated_by uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(tenant_id, slug)
);

create table if not exists segnalazione_neighborhoods (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references tenants(id) on delete cascade,
  code text not null,
  name text not null,
  description text,
  geojson jsonb,
  centroid_lat numeric(9,6),
  centroid_lng numeric(9,6),
  is_active boolean not null default true,
  created_by uuid,
  updated_by uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(tenant_id, code)
);

create table if not exists segnalazioni (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references tenants(id) on delete cascade,
  codice text not null,
  titolo text not null,
  descrizione text not null,
  stato text not null default 'in_attesa',
  visibilita text not null default 'pubblica',
  priorita text not null default 'media',
  severita text not null default 'media',
  source text not null default 'cittadino_web',
  category_id uuid references segnalazione_categories(id) on delete set null,
  neighborhood_id uuid references segnalazione_neighborhoods(id) on delete set null,
  address text,
  lat numeric(9,6),
  lng numeric(9,6),
  attachments jsonb not null default '[]'::jsonb,
  tags text[] not null default '{}',
  metadata jsonb not null default '{}'::jsonb,
  moderation_flags jsonb not null default '{}'::jsonb,
  public_response text,
  created_by uuid,
  assigned_to uuid,
  resolved_at timestamptz,
  closed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(tenant_id, codice)
);

create table if not exists segnalazione_votes (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references tenants(id) on delete cascade,
  segnalazione_id uuid not null references segnalazioni(id) on delete cascade,
  user_id uuid not null,
  created_at timestamptz not null default now(),
  unique(tenant_id, segnalazione_id, user_id)
);

create table if not exists segnalazione_follows (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references tenants(id) on delete cascade,
  segnalazione_id uuid not null references segnalazioni(id) on delete cascade,
  user_id uuid not null,
  created_at timestamptz not null default now(),
  unique(tenant_id, segnalazione_id, user_id)
);

create table if not exists segnalazione_timeline_events (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references tenants(id) on delete cascade,
  segnalazione_id uuid not null references segnalazioni(id) on delete cascade,
  event_type text not null,
  visibility text not null default 'public',
  message text,
  payload jsonb not null default '{}'::jsonb,
  created_by uuid,
  created_at timestamptz not null default now()
);

create table if not exists segnalazione_report_snapshots (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references tenants(id) on delete cascade,
  segnalazione_id uuid not null references segnalazioni(id) on delete cascade,
  status text not null,
  severity text,
  priority text,
  assigned_to uuid,
  is_public boolean not null default true,
  snapshot_data jsonb not null default '{}'::jsonb,
  changed_by uuid,
  created_at timestamptz not null default now()
);

create index if not exists idx_pratiche_tenant on pratiche(tenant_id);
create index if not exists idx_pratica_events_pratica on pratica_events(pratica_id);
create index if not exists idx_audit_tenant_created on audit_log(tenant_id, created_at desc);

create index if not exists idx_segnalazioni_tenant_created on segnalazioni(tenant_id, created_at desc);
create index if not exists idx_segnalazioni_tenant_stato on segnalazioni(tenant_id, stato);
create index if not exists idx_segnalazioni_tenant_category on segnalazioni(tenant_id, category_id);
create index if not exists idx_segnalazioni_tenant_neighborhood on segnalazioni(tenant_id, neighborhood_id);
create index if not exists idx_segnalazioni_tags on segnalazioni using gin(tags);
create index if not exists idx_segnalazioni_metadata on segnalazioni using gin(metadata);
create index if not exists idx_segnalazioni_moderation_flags on segnalazioni using gin(moderation_flags);

create index if not exists idx_segnalazione_votes_lookup on segnalazione_votes(tenant_id, segnalazione_id, user_id);
create index if not exists idx_segnalazione_follows_lookup on segnalazione_follows(tenant_id, segnalazione_id, user_id);
create index if not exists idx_segnalazione_timeline_created on segnalazione_timeline_events(segnalazione_id, created_at desc);
create index if not exists idx_segnalazione_snapshots_created on segnalazione_report_snapshots(segnalazione_id, created_at desc);

insert into roles(code, name)
values
  ('super_admin', 'Super Admin'),
  ('tenant_admin', 'Tenant Admin'),
  ('operatore', 'Operatore'),
  ('cittadino', 'Cittadino')
on conflict (code) do nothing;

-- Phase 4: localization + branding + RBAC-safe schema extensions
alter table if exists user_profiles
  add column if not exists language text not null default 'it',
  add column if not exists updated_at timestamptz not null default now();

alter table if exists user_profiles
  drop constraint if exists user_profiles_language_check;
alter table if exists user_profiles
  add constraint user_profiles_language_check check (language in ('it', 'en'));

create table if not exists tenant_branding (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null unique references tenants(id) on delete cascade,
  logo_url text,
  primary_color text not null default '#0055A4',
  secondary_color text not null default '#FFFFFF',
  font_family text,
  header_variant text,
  footer_text text,
  theme jsonb not null default '{}'::jsonb,
  updated_by uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table if exists tenant_branding
  drop constraint if exists tenant_branding_primary_color_check;
alter table if exists tenant_branding
  add constraint tenant_branding_primary_color_check check (primary_color ~ '^#[A-Fa-f0-9]{6}$');

alter table if exists tenant_branding
  drop constraint if exists tenant_branding_secondary_color_check;
alter table if exists tenant_branding
  add constraint tenant_branding_secondary_color_check check (secondary_color ~ '^#[A-Fa-f0-9]{6}$');

alter table if exists tenant_branding
  drop constraint if exists tenant_branding_header_variant_check;
alter table if exists tenant_branding
  add constraint tenant_branding_header_variant_check check (header_variant is null or header_variant in ('standard', 'compact'));

create index if not exists idx_user_profiles_tenant_language on user_profiles(tenant_id, language);
create index if not exists idx_user_roles_user on user_roles(user_id);
create index if not exists idx_tenant_branding_tenant on tenant_branding(tenant_id);

alter table if exists user_profiles
  add column if not exists email text;

create table if not exists bug_reports (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references tenants(id) on delete cascade,
  reported_by uuid not null references user_profiles(id) on delete cascade,
  title text not null,
  description text not null,
  page_url text,
  status text not null default 'open',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table if exists bug_reports
  drop constraint if exists bug_reports_status_check;
alter table if exists bug_reports
  add constraint bug_reports_status_check check (status in ('open', 'in_review', 'resolved', 'closed'));

create table if not exists admin_email_notifications (
  id uuid primary key default gen_random_uuid(),
  bug_report_id uuid not null references bug_reports(id) on delete cascade,
  recipient_user_id uuid not null references user_profiles(id) on delete cascade,
  recipient_email text not null,
  subject text not null,
  body text not null,
  delivery_status text not null default 'queued',
  created_at timestamptz not null default now()
);

alter table if exists admin_email_notifications
  drop constraint if exists admin_email_notifications_delivery_status_check;
alter table if exists admin_email_notifications
  add constraint admin_email_notifications_delivery_status_check check (delivery_status in ('queued', 'sent', 'failed'));

create table if not exists global_docs (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  title text not null,
  content_md text not null,
  is_published boolean not null default true,
  sort_order integer not null default 0,
  updated_by uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists tenant_docs (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references tenants(id) on delete cascade,
  slug text not null,
  title text not null,
  content_md text not null,
  is_published boolean not null default true,
  sort_order integer not null default 0,
  updated_by uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(tenant_id, slug)
);

create index if not exists idx_bug_reports_tenant_created on bug_reports(tenant_id, created_at desc);
create index if not exists idx_admin_email_notifications_bug on admin_email_notifications(bug_report_id);
create index if not exists idx_global_docs_published on global_docs(is_published, sort_order);
create index if not exists idx_tenant_docs_tenant_published on tenant_docs(tenant_id, is_published, sort_order);
