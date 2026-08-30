<#
    Stops the local PostgreSQL server.

    The API is stopped with Ctrl+C in its own window; PostgreSQL runs in the
    background and needs stopping explicitly (or it just keeps running, which
    is harmless).

    Usage:  .\stop-dev.ps1
#>

$PgBin  = "C:\Users\Makel\pgsql-portable\pgsql\bin"
$PgData = "C:\Users\Makel\pgsql-portable\pgdata"

& "$PgBin\pg_isready.exe" -p 5433 -h 127.0.0.1 | Out-Null

if ($LASTEXITCODE -ne 0) {
    Write-Host 'PostgreSQL is not running.' -ForegroundColor Yellow
    exit 0
}

Write-Host 'Stopping PostgreSQL...' -ForegroundColor Cyan
& "$PgBin\pg_ctl.exe" -D $PgData -m fast stop
Write-Host 'Stopped.' -ForegroundColor Green
