# Firestore + Storage kurallarını ve indeksleri yayınlar (ücretsiz Spark planında).
#   powershell -ExecutionPolicy Bypass -File scripts\deploy_rules.ps1
$env:Path = "C:\dev\npm;$env:Path"
Set-Location (Split-Path $PSScriptRoot -Parent)
firebase deploy --project memento-60cce --only "firestore:rules,firestore:indexes,storage"
