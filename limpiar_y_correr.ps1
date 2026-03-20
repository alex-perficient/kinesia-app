Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "🧹 INICIANDO MANTENIMIENTO DE KINES.IA..." -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

Write-Host "`n1. Limpiando cache viejo..." -ForegroundColor Yellow
flutter clean

Write-Host "`n2. Descargando dependencias frescas..." -ForegroundColor Yellow
flutter pub get

Write-Host "`n3. Levantando el proyecto en Chrome..." -ForegroundColor Yellow
flutter run -d chrome

Write-Host "`n==========================================" -ForegroundColor Green
Write-Host "✅ PROCESO TERMINADO." -ForegroundColor Green