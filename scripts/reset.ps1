param()
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
docker compose -f docker-compose.backend.yml --env-file .env down -v --remove-orphans
Write-Host 'Supabase backend resettato (volumi rimossi).' -ForegroundColor Red
