$ErrorActionPreference = 'Stop'

Write-Host 'Checking compose and SQL bootstrap...'

$composePath = Join-Path $PSScriptRoot '..\docker-compose.backend.yml'
$sqlPath = Join-Path $PSScriptRoot '..\sql\init\001_schema.sql'

if (-not (Test-Path $composePath)) { throw 'docker-compose.backend.yml not found' }
if (-not (Test-Path $sqlPath)) { throw 'sql/001_schema.sql not found' }

$compose = Get-Content $composePath -Raw
$sql = Get-Content $sqlPath -Raw

$requiredServices = @('db:', 'kong:', 'auth:', 'rest:', 'studio:')
foreach ($svc in $requiredServices) {
  if ($compose -notmatch [regex]::Escape($svc)) {
    throw "Missing service in compose: $svc"
  }
}

$requiredTables = @('create table if not exists tenants', 'create table if not exists pratiche', 'create table if not exists audit_log')
foreach ($tbl in $requiredTables) {
  if ($sql.ToLower() -notmatch [regex]::Escape($tbl)) {
    throw "Missing schema definition: $tbl"
  }
}

Write-Host 'backend-ci-test: OK'
