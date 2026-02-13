$ErrorActionPreference = 'Stop'

Write-Host 'Checking compose, kong and SQL bootstrap...'

$composePath = Join-Path $PSScriptRoot '..\docker-compose.backend.yml'
$sqlPath = Join-Path $PSScriptRoot '..\sql\init\001_schema.sql'
$kongPath = Join-Path $PSScriptRoot '..\kong\kong.yml'

if (-not (Test-Path $composePath)) { throw 'docker-compose.backend.yml not found' }
if (-not (Test-Path $sqlPath)) { throw 'sql/001_schema.sql not found' }
if (-not (Test-Path $kongPath)) { throw 'kong/kong.yml not found' }

$compose = Get-Content $composePath -Raw
$sql = Get-Content $sqlPath -Raw
$kong = Get-Content $kongPath -Raw

$requiredServices = @('db:', 'kong:', 'auth:', 'rest:', 'studio:')
foreach ($svc in $requiredServices) {
  if ($compose -notmatch [regex]::Escape($svc)) {
    throw "Missing service in compose: $svc"
  }
}

$requiredAuthVars = @('GOTRUE_MAILER_AUTOCONFIRM', 'GOTRUE_DISABLE_SIGNUP', 'API_EXTERNAL_URL')
foreach ($varName in $requiredAuthVars) {
  if ($compose -notmatch [regex]::Escape($varName)) {
    throw "Missing auth hardening env var in compose: $varName"
  }
}

$requiredTables = @(
  'create table if not exists tenants',
  'create table if not exists pratiche',
  'create table if not exists audit_log',
  'create table if not exists segnalazioni'
)
foreach ($tbl in $requiredTables) {
  if ($sql.ToLower() -notmatch [regex]::Escape($tbl)) {
    throw "Missing schema definition: $tbl"
  }
}

$requiredGovernanceColumns = @('moderation_flags jsonb', 'public_response text', 'assigned_to uuid')
foreach ($col in $requiredGovernanceColumns) {
  if ($sql.ToLower() -notmatch [regex]::Escape($col)) {
    throw "Missing governance column: $col"
  }
}

$requiredKongPaths = @('/auth/v1', '/auth/v1/', '/rest/v1', '/rest/v1/')
foreach ($path in $requiredKongPaths) {
  if ($kong -notmatch [regex]::Escape($path)) {
    throw "Missing kong route path: $path"
  }
}

Write-Host 'backend-ci-test: OK'
