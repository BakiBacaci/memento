# Memento'yu bağlı Android telefonda çalıştırır.
#   powershell -ExecutionPolicy Bypass -File scripts\run_phone.ps1
$env:ANDROID_HOME = 'C:\dev\android-sdk'
$env:ANDROID_SDK_ROOT = 'C:\dev\android-sdk'
# Android Studio'nun kendi Java'sı (25) Gradle 8.14 ile uyumsuz; JDK 21 kullanılıyor.
$env:JAVA_HOME = 'C:\Program Files\Eclipse Adoptium\jdk-21.0.13.9-hotspot'
$env:Path = "C:\dev\flutter\bin;C:\dev\android-sdk\platform-tools;$env:JAVA_HOME\bin;$env:Path"
Set-Location (Split-Path $PSScriptRoot -Parent)
flutter config --android-sdk C:\dev\android-sdk --jdk-dir $env:JAVA_HOME | Out-Null
flutter pub get
adb devices
flutter run --debug -d R68R8008B6V
