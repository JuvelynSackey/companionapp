<#
    Mirrors the USB-connected phone on this computer's screen with scrcpy,
    for presenting the app on a projector. You can click and type in the
    window to control the phone.

    Usage (from the campus-companion-app folder):
      .\show-phone.ps1

    Install scrcpy once with:  winget install Genymobile.scrcpy
#>
$ErrorActionPreference = 'Stop'

# scrcpy ships its own adb; use the Android SDK's one instead, so the two
# don't keep restarting each other's adb server (Flutter uses the SDK one).
$sdkAdb = Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe'
if (Test-Path $sdkAdb) { $env:ADB = $sdkAdb }

$scrcpy = (Get-Command scrcpy -ErrorAction SilentlyContinue).Source
if (-not $scrcpy) {
    $scrcpy = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Recurse -Filter scrcpy.exe -ErrorAction SilentlyContinue |
        Select-Object -First 1 -ExpandProperty FullName
}
if (-not $scrcpy) {
    Write-Host 'scrcpy is not installed. Run: winget install Genymobile.scrcpy' -ForegroundColor Red
    exit 1
}

$devices = & $env:ADB devices 2>$null | Select-String -Pattern '\tdevice$'
if (-not $devices) {
    Write-Host 'No phone found. Plug it in, turn on USB debugging, and tap Allow on the phone.' -ForegroundColor Red
    exit 1
}

# --stay-awake: the phone screen doesn't lock while plugged in.
# --no-audio:   keep sound on the phone; avoids audio errors on some PCs.
& $scrcpy --stay-awake --no-audio --window-title 'Campus Companion' --max-size 1600
