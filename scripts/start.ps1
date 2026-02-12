param()
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
docker compose -f docker-compose.backend.yml --env-file .env up -d
Write-Host 'Supabase backend avviato.' -ForegroundColor Green
