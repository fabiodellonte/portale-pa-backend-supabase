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

## Note
- Questa base è pensata per prototipo scalabile e distribuibile.
- Gli endpoint e host sono parametrizzati via variabili ambiente.
