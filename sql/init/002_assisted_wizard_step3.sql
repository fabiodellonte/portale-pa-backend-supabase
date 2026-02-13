-- Assisted wizard step 3: controlled tags + deterministic address validation catalog

create table if not exists tenant_tag_catalog (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references tenants(id) on delete cascade,
  slug text not null,
  label text not null,
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (tenant_id, slug)
);

create table if not exists tenant_address_catalog (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references tenants(id) on delete cascade,
  reference_code text not null,
  address text not null,
  lat numeric(9,6) not null,
  lng numeric(9,6) not null,
  source_dataset text not null default 'local',
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (tenant_id, reference_code)
);

create index if not exists idx_tenant_tag_catalog_tenant on tenant_tag_catalog(tenant_id, is_active, sort_order);
create index if not exists idx_tenant_address_catalog_tenant on tenant_address_catalog(tenant_id, is_active, address);

alter table if exists segnalazioni
  add column if not exists validated_address_catalog_id uuid references tenant_address_catalog(id) on delete set null,
  add column if not exists address_validation jsonb not null default '{}'::jsonb;

insert into tenant_tag_catalog (tenant_id, slug, label, sort_order)
select t.id, tag.slug, tag.label, tag.sort_order
from tenants t
cross join (
  values
    ('viabilita', 'Viabilità', 1),
    ('illuminazione', 'Illuminazione', 2),
    ('decoro_urbano', 'Decoro urbano', 3),
    ('sicurezza', 'Sicurezza', 4),
    ('verde_pubblico', 'Verde pubblico', 5)
) as tag(slug, label, sort_order)
on conflict (tenant_id, slug) do update set
  label = excluded.label,
  sort_order = excluded.sort_order,
  updated_at = now();

insert into tenant_address_catalog (tenant_id, reference_code, address, lat, lng, source_dataset)
values
  ('00000000-0000-0000-0000-000000000001', 'VRM24', 'Via Roma 24', 41.900100, 12.500200, 'demo_local'),
  ('00000000-0000-0000-0000-000000000001', 'PZM1', 'Piazza Municipio 1', 41.901000, 12.498500, 'demo_local'),
  ('00000000-0000-0000-0000-000000000001', 'VVD11', 'Via Verdi 11', 41.899400, 12.502000, 'demo_local'),
  ('00000000-0000-0000-0000-000000000001', 'CORSO10', 'Corso Italia 10', 41.902200, 12.497100, 'demo_local')
on conflict (tenant_id, reference_code) do update set
  address = excluded.address,
  lat = excluded.lat,
  lng = excluded.lng,
  source_dataset = excluded.source_dataset,
  updated_at = now();
