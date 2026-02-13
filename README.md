# portale-pa-backend-supabase

Backend dati self-hosted per Portale PA (Supabase stack minima) con focus multi-tenant e audit.

## Stack minima inclusa
- PostgreSQL
- Kong Gateway
- GoTrue (Auth)
- PostgREST
- Supabase Studio

## Avvio rapido
```powershell
cp .env.example .env
./scripts/start.ps1
```

## Stop
```powershell
./scripts/stop.ps1
```

## Reset (attenzione: distruttivo)
```powershell
./scripts/reset.ps1
```

## Healthcheck
- Postgres: `localhost:54322`
- Kong: `http://localhost:54321/health`
- Studio: `http://localhost:54323`

## Demo DB mode (safe switch)
> Richiede stack avviato almeno con `./scripts/start.ps1`.

```powershell
# 1) DEMO ON: backup automatico DB corrente + seed demo deterministico
./scripts/demo-mode.ps1 on

# 2) DEMO OFF: restore dal backup automatico precedente
./scripts/demo-mode.ps1 off
```

Opzionale:
```powershell
./scripts/demo-mode.ps1 status
```

Dettagli:
- backup REAL salvato in `.demo-state/backups/real-YYYYMMDD-HHMMSS.sql`
- seed demo: `sql/seeds/demo.sql`
- restore reale usa l'ultimo backup registrato in `.demo-state/last-real-backup.txt`

## Note
- Questa base è pensata per prototipo scalabile e distribuibile.
- Gli endpoint e host sono parametrizzati via variabili ambiente.
