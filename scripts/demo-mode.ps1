param(
  [Parameter(Mandatory = $true)]
  [ValidateSet('on', 'off', 'status')]
  [string]$Mode
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$composeFile = Join-Path $root 'docker-compose.backend.yml'
$seedFile = Join-Path $root 'sql\seeds\demo.sql'
$stateDir = Join-Path $root '.demo-state'
$backupDir = Join-Path $stateDir 'backups'
$lastBackupFile = Join-Path $stateDir 'last-real-backup.txt'

if (!(Test-Path $stateDir)) { New-Item -ItemType Directory -Path $stateDir | Out-Null }
if (!(Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir | Out-Null }

$envFile = Join-Path $root '.env'
if (!(Test-Path $envFile)) { throw '.env not found. Copy .env.example -> .env first.' }
$envMap = @{}
Get-Content $envFile | ForEach-Object {
  if ($_ -match '^\s*#' -or $_ -notmatch '=') { return }
  $parts = $_.Split('=', 2)
  $envMap[$parts[0].Trim()] = $parts[1].Trim().Trim('"')
}
$pgPassword = $envMap['POSTGRES_PASSWORD']
if ([string]::IsNullOrWhiteSpace($pgPassword)) { throw 'POSTGRES_PASSWORD missing in .env' }

function Ensure-DbUp {
  docker compose -f $composeFile up -d db | Out-Null
}

function Exec-InDb([string]$cmd) {
  docker exec pa-supabase-db sh -lc "PGPASSWORD='$pgPassword' $cmd"
}

function Backup-Current {
  $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
  $backupPath = Join-Path $backupDir "real-$stamp.sql"
  Exec-InDb "pg_dump -U postgres -d postgres --clean --if-exists --no-owner --no-privileges" | Set-Content -Path $backupPath
  Set-Content -Path $lastBackupFile -Value $backupPath
  return $backupPath
}

function Restore-FromFile([string]$path) {
  if (!(Test-Path $path)) { throw "SQL file not found: $path" }
  Get-Content $path -Raw | docker exec -i pa-supabase-db sh -lc "PGPASSWORD='$pgPassword' psql -v ON_ERROR_STOP=1 -U postgres -d postgres"
}

Ensure-DbUp

switch ($Mode) {
  'status' {
    if (Test-Path $lastBackupFile) {
      Write-Host "Last REAL backup: $(Get-Content $lastBackupFile -Raw)"
      Write-Host 'Current mode cannot be inferred with certainty; last switch captured above.'
    } else {
      Write-Host 'No REAL backup recorded yet. Demo mode likely never enabled from this script.'
    }
  }
  'on' {
    $backup = Backup-Current
    Write-Host "REAL backup saved to: $backup"
    Restore-FromFile $seedFile
    Write-Host 'DEMO mode ON (deterministic demo dataset loaded).'
  }
  'off' {
    if (!(Test-Path $lastBackupFile)) {
      throw 'No backup found to restore REAL mode. Enable demo mode once to create a safety backup first.'
    }
    $backupPath = (Get-Content $lastBackupFile -Raw).Trim()
    Restore-FromFile $backupPath
    Write-Host "DEMO mode OFF (restored REAL DB from: $backupPath)."
  }
}
