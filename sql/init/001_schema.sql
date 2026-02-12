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

create index if not exists idx_pratiche_tenant on pratiche(tenant_id);
create index if not exists idx_pratica_events_pratica on pratica_events(pratica_id);
create index if not exists idx_audit_tenant_created on audit_log(tenant_id, created_at desc);

insert into roles(code, name)
values
  ('super_admin', 'Super Admin'),
  ('tenant_admin', 'Tenant Admin'),
  ('operatore', 'Operatore'),
  ('cittadino', 'Cittadino')
on conflict (code) do nothing;
