# Adds common Flutter SDK locations to PATH for this PowerShell session.
# Python subprocesses on Windows often cannot find `flutter` / `dart` even when
# interactive shells can — run this before release / preflight if needed:
#
#   . .\tool\env_windows.ps1
#   python tool/ci_preflight.py

$candidates = @(
    (Join-Path $HOME "dev\flutter\bin"),
    (Join-Path $HOME "flutter\bin"),
    "C:\flutter\bin",
    (Join-Path $env:LOCALAPPDATA "flutter\bin")
)

$resolved = $null
foreach ($dir in $candidates) {
    if (Test-Path (Join-Path $dir "flutter.bat")) {
        $resolved = $dir
        break
    }
}

if ($null -eq $resolved) {
    Write-Error "Flutter SDK not found in known locations. Install Flutter or add it to PATH."
    return
}

if ($env:PATH -notlike "*$resolved*") {
    $env:PATH = "$resolved;$env:PATH"
}

Write-Host "Flutter PATH ready: $resolved"
& (Join-Path $resolved "flutter.bat") --version
