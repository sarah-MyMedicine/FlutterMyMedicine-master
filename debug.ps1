Write-Host "=== Flutter Debug Helper ===" -ForegroundColor Cyan
Write-Host "`nChecking for devices..." -ForegroundColor Yellow
flutter devices

Write-Host "`nLaunching emulator..." -ForegroundColor Yellow
Start-Job -ScriptBlock { flutter emulators --launch Medium_Phone_API_36.1 } | Out-Null

Write-Host "Waiting for emulator to boot (30 seconds)..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

Write-Host "`nChecking devices again..." -ForegroundColor Yellow
flutter devices

Write-Host "`nStarting Flutter app on emulator..." -ForegroundColor Green
flutter run -d emulator-5554
