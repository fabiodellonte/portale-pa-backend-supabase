begin;

-- keep roles/tenant/user bootstrap from 001_schema.sql, reset business demo data deterministically
truncate table
  admin_email_notifications,
  bug_reports,
  segnalazione_report_snapshots,
  segnalazione_timeline_events,
  segnalazione_follows,
  segnalazione_votes,
  segnalazioni,
  tenant_address_catalog,
  tenant_tag_catalog,
  segnalazione_categories,
  segnalazione_neighborhoods,
  global_docs,
  tenant_docs,
  tenant_branding,
  pratiche,
  pratica_events,
  audit_log
restart identity cascade;

insert into tenant_branding (tenant_id, primary_color, secondary_color, footer_text)
values ('00000000-0000-0000-0000-000000000001', '#0055A4', '#FFFFFF', 'Demo mode attivo')
on conflict (tenant_id) do update set
  primary_color = excluded.primary_color,
  secondary_color = excluded.secondary_color,
  footer_text = excluded.footer_text,
  updated_at = now();

insert into segnalazione_categories (id, tenant_id, slug, name, color, sort_order)
values
  ('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'viabilita', 'Viabilità', '#EF4444', 1),
  ('10000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', 'illuminazione', 'Illuminazione', '#F59E0B', 2),
  ('10000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000001', 'decoro', 'Decoro urbano', '#10B981', 3);

insert into tenant_tag_catalog (tenant_id, slug, label, sort_order)
values
  ('00000000-0000-0000-0000-000000000001', 'viabilita', 'Viabilità', 1),
  ('00000000-0000-0000-0000-000000000001', 'illuminazione', 'Illuminazione', 2),
  ('00000000-0000-0000-0000-000000000001', 'decoro_urbano', 'Decoro urbano', 3),
  ('00000000-0000-0000-0000-000000000001', 'verde_pubblico', 'Verde pubblico', 4);

insert into tenant_address_catalog (id, tenant_id, reference_code, address, lat, lng, source_dataset)
values
  ('11000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'VRM24', 'Via Roma 24', 41.900100, 12.500200, 'demo_local'),
  ('11000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', 'PZM1', 'Piazza Municipio 1', 41.901000, 12.498500, 'demo_local'),
  ('11000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000001', 'VVD11', 'Via Verdi 11', 41.899400, 12.502000, 'demo_local');

insert into segnalazioni (id, tenant_id, codice, titolo, descrizione, stato, priorita, severita, category_id, address, lat, lng, tags, validated_address_catalog_id, address_validation, created_by, updated_at)
values
  ('20000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'SGN-DEMO-001', 'Buche via Roma', 'Manto stradale danneggiato vicino al civico 24.', 'in_attesa', 'alta', 'media', '10000000-0000-0000-0000-000000000001', 'Via Roma 24', 41.900100, 12.500200, '{viabilita}', '11000000-0000-0000-0000-000000000001', '{"validated": true, "source": "tenant_address_catalog", "reference_code": "VRM24"}'::jsonb, '00000000-0000-0000-0000-000000000111', now() - interval '1 day'),
  ('20000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', 'SGN-DEMO-002', 'Lampione spento in piazza', 'Illuminazione assente in piazza centrale dopo le 20:00.', 'presa_in_carico', 'media', 'media', '10000000-0000-0000-0000-000000000002', 'Piazza Municipio 1', 41.901000, 12.498500, '{illuminazione}', '11000000-0000-0000-0000-000000000002', '{"validated": true, "source": "tenant_address_catalog", "reference_code": "PZM1"}'::jsonb, '00000000-0000-0000-0000-000000000111', now() - interval '2 day'),
  ('20000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000001', 'SGN-DEMO-003', 'Rifiuti abbandonati al parco', 'Sacchi e materiali ingombranti vicino area giochi.', 'in_lavorazione', 'media', 'alta', '10000000-0000-0000-0000-000000000003', 'Via Verdi 11', 41.899400, 12.502000, '{decoro_urbano}', '11000000-0000-0000-0000-000000000003', '{"validated": true, "source": "tenant_address_catalog", "reference_code": "VVD11"}'::jsonb, '00000000-0000-0000-0000-000000000222', now() - interval '4 day');

insert into segnalazione_votes (tenant_id, segnalazione_id, user_id)
values
  ('00000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000111'),
  ('00000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000222'),
  ('00000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000333'),
  ('00000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000111');

insert into segnalazione_timeline_events (tenant_id, segnalazione_id, event_type, message, created_by)
values
  ('00000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', 'created', 'Segnalazione demo creata', '00000000-0000-0000-0000-000000000111'),
  ('00000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000002', 'assigned', 'Assegnata al team illuminazione', '00000000-0000-0000-0000-000000000222');

insert into global_docs (slug, title, content_md, is_published, sort_order)
values ('demo-faq', 'FAQ Demo', 'Documentazione globale in demo mode.', true, 1);

insert into tenant_docs (tenant_id, slug, title, content_md, is_published, sort_order)
values ('00000000-0000-0000-0000-000000000001', 'demo-territorio', 'Linee guida territorio', 'Documento tenant in demo mode.', true, 1);

commit;
