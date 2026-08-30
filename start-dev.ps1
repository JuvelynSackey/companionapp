<#
    Starts the whole development stack:
      1. the local PostgreSQL server (portable install, port 5433)
      2. the Express API (port 4000)

    Usage:  .\start-dev.ps1
#>

$ErrorActionPreference = 'Stop'

$PgBin   = "C:\Users\Makel\pgsql-portable\pgsql\bin"
$PgData  = "C:\Users\Makel\pgsql-portable\pgdata"
$PgLog   = "C:\Users\Makel\pgsql-portable\pg.log"
$Backend = Join-Path $PSScriptRoot 'backend'

Write-Host 'Checking PostgreSQL...' -ForegroundColor Cyan
& "$PgBin\pg_isready.exe" -p 5433 -h 127.0.0.1 | Out-Null

if ($LASTEXITCODE -eq 0) {
    Write-Host '  already running on port 5433' -ForegroundColor Green
} else {
    Write-Host '  starting...' -ForegroundColor Yellow
    & "$PgBin\pg_ctl.exe" -D $PgData -l $PgLog -o '-p 5433' start
    Start-Sleep -Seconds 4

    & "$PgBin\pg_isready.exe" -p 5433 -h 127.0.0.1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  FAILED. Check the log: $PgLog" -ForegroundColor Red
        exit 1
    }
    Write-Host '  started' -ForegroundColor Green
}

Write-Host ''
Write-Host 'Starting the API on http://localhost:4000' -ForegroundColor Cyan
Write-Host 'Press Ctrl+C to stop the API (PostgreSQL keeps running).'
Write-Host ''

Set-Location $Backend
npm run dev
