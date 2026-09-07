# Gera o projeto Android do Flutter e aplica permissões de câmera/rede.
$ErrorActionPreference = "Stop"

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host "Flutter nao encontrado. Instale: https://docs.flutter.dev/get-started/install/windows"
    exit 1
}

Set-Location $PSScriptRoot

if (-not (Test-Path "android")) {
    flutter create --project-name object_detector_yolo --org br.ufpi.sd --platforms android .
}

$manifestPath = Join-Path $PSScriptRoot "android\app\src\main\AndroidManifest.xml"
if (-not (Test-Path $manifestPath)) {
    Write-Host "AndroidManifest.xml nao encontrado em $manifestPath"
    exit 1
}

$manifest = Get-Content $manifestPath -Raw

if ($manifest -notmatch "android.permission.CAMERA") {
    $permissions = @"
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-feature android:name="android.hardware.camera" android:required="false" />

"@
    $manifest = $manifest -replace "<application", ($permissions + "    <application")
}

if ($manifest -notmatch "usesCleartextTraffic") {
    $manifest = $manifest -replace "<application", '<application android:usesCleartextTraffic="true"'
}

Set-Content -Path $manifestPath -Value $manifest -NoNewline
Write-Host "Projeto Android pronto. Rode: flutter pub get && flutter run"
