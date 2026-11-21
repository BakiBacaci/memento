# Memento — Firebase kurulumu (ücretsiz Spark planında kalır).
#  1) Yeni paket adı (com.bakibacaci.memento) için Android + iOS uygulama kaydı
#  2) Firestore ve Storage güvenlik kurallarını + indeksleri yayınlama
# Çalıştırma:  powershell -ExecutionPolicy Bypass -File scripts\firebase_setup.ps1
$ErrorActionPreference = 'Stop'
$env:Path = "C:\dev\npm;C:\dev\flutter\bin;$env:LOCALAPPDATA\Pub\Cache\bin;$env:Path"
Set-Location (Split-Path $PSScriptRoot -Parent)

Write-Host "`n== Firebase hesabi ==" -ForegroundColor Yellow
firebase login:list

Write-Host "`n== FlutterFire CLI ==" -ForegroundColor Yellow
dart pub global activate flutterfire_cli | Out-Null

Write-Host "`n== Uygulama kaydi (com.bakibacaci.memento) ==" -ForegroundColor Yellow
flutterfire configure `
  --project=memento-60cce `
  --platforms=android,ios,web `
  --android-package-name=com.bakibacaci.memento `
  --ios-bundle-id=com.bakibacaci.memento `
  --yes

Write-Host "`n== Guvenlik kurallari ==" -ForegroundColor Yellow
firebase deploy --project memento-60cce --only "firestore:rules,firestore:indexes,storage"

Write-Host "`nTAMAM" -ForegroundColor Green
