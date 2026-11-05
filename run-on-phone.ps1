<#
    Builds the app and installs it on the phone connected by USB.

    Usage (from the campus-companion-app folder):
      .\run-on-phone.ps1           # app talks to the live server (Render)
      .\run-on-phone.ps1 -Local    # app talks to this laptop's API (start-dev.ps1)

    The phone needs USB debugging on (Settings > Developer options) and must
    allow this computer when it asks. With the live server, the phone can be
    unplugged afterwards and works anywhere with internet.
#>
param([switch]$Local)

$ErrorActionPreference = 'Stop'
$LiveApi = 'https://campus-companion-backend-1bye.onrender.com/api'
$Mobile = Join-Path $PSScriptRoot 'mobile'
$EnvFile = Join-Path $PSScriptRoot 'backend\.env'

Write-Host 'Looking for the phone...' -ForegroundColor Cyan
$devices = adb devices | Select-String -Pattern '\tdevice$'
if (-not $devices) {
    Write-Host '  No phone found. Plug it in, turn on USB debugging, and tap Allow on the phone.' -ForegroundColor Red
    exit 1
}
Write-Host "  found $($devices.Count) device(s)" -ForegroundColor Green

if ($Local) {
    $api = 'http://localhost:4000/api'
    adb reverse tcp:4000 tcp:4000 | Out-Null
    Write-Host '  Using this laptop''s API (keep start-dev.ps1 running and the cable plugged in).' -ForegroundColor Yellow
} else {
    $api = $LiveApi
    Write-Host 'Waking the live server (can take up to a minute after it has been idle)...' -ForegroundColor Cyan
    try {
        $health = Invoke-RestMethod "$LiveApi/health" -TimeoutSec 90
        Write-Host "  server: $($health.status), database: $($health.database), Google sign-in: $($health.googleSignIn)" -ForegroundColor Green
    } catch {
        Write-Host "  The live server did not answer: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

# The Gemini key is read from backend/.env and never printed.
$gemini = ''
if (Test-Path $EnvFile) {
    $line = Get-Content $EnvFile | Where-Object { $_ -like 'GEMINI_API_KEY=*' } | Select-Object -First 1
    if ($line) { $gemini = $line.Substring('GEMINI_API_KEY='.Length).Trim().Trim("'").Trim('"') }
}

Write-Host 'Building the app (a few minutes)...' -ForegroundColor Cyan
Set-Location $Mobile
flutter build apk --debug `
    "--dart-define=API_BASE_URL=$api" `
    '--dart-define=GOOGLE_SIGN_IN_ENABLED=true' `
    '--dart-define=GOOGLE_SERVER_CLIENT_ID=696171773446-d7i37n33smtb6qcjqlha1alfd8uqvfjs.apps.googleusercontent.com' `
    '--dart-define=FCM_ENABLED=true' `
    "--dart-define=GEMINI_API_KEY=$gemini"
if ($LASTEXITCODE -ne 0) { Write-Host 'Build failed.' -ForegroundColor Red; exit 1 }

Write-Host 'Installing on the phone...' -ForegroundColor Cyan
adb install -r build\app\outputs\flutter-apk\app-debug.apk
if ($LASTEXITCODE -ne 0) { Write-Host 'Install failed.' -ForegroundColor Red; exit 1 }

adb shell monkey -p com.example.mobile -c android.intent.category.LAUNCHER 1 | Out-Null
Write-Host ''
Write-Host 'Done: Campus Companion is open on the phone.' -ForegroundColor Green
