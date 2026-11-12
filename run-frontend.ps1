# Script khởi chạy Frontend Flutter lên máy ảo Android
param(
    [string]$DeviceId = "emulator-5554",
    [string]$EmulatorName = "Pixel_6_Pro"
)

Set-Location $PSScriptRoot

$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
$emulatorExe = "$env:LOCALAPPDATA\Android\Sdk\emulator\emulator.exe"

if (Test-Path $adb) {
    $devices = & $adb devices
    if ($devices -notmatch "$DeviceId\s+device") {
        $qemuRunning = Get-Process -Name "qemu-system-x86_64" -ErrorAction SilentlyContinue
        if (-not $qemuRunning) {
            $avdDir = "$env:USERPROFILE\.android\avd\$EmulatorName.avd"
            if (Test-Path $avdDir) {
                Remove-Item "$avdDir\*.lock" -Force -ErrorAction SilentlyContinue
            }
            $avdDir3 = "$env:USERPROFILE\.android\avd\${EmulatorName}_3.avd"
            if (Test-Path $avdDir3) {
                Remove-Item "$avdDir3\*.lock" -Force -ErrorAction SilentlyContinue
            }
            if (Test-Path $emulatorExe) {
                Write-Host "Starting Android Emulator ($EmulatorName) with DNS 8.8.8.8 and Physical Webcam..." -ForegroundColor Cyan
                Start-Process -FilePath $emulatorExe -ArgumentList "-avd", $EmulatorName, "-dns-server", "8.8.8.8,1.1.1.1", "-camera-back", "webcam0", "-camera-front", "webcam0", "-no-snapshot-load"
            }
        }
        Write-Host "Waiting for Android Emulator ($DeviceId) to come online..." -ForegroundColor Cyan
        & $adb wait-for-device
        for ($i = 0; $i -lt 30; $i++) {
            $bootCompleted = (& $adb -s $DeviceId shell getprop sys.boot_completed 2>$null).Trim()
            if ($bootCompleted -eq "1") {
                break
            }
            Start-Sleep -Seconds 2
        }
    }
}

C:\flutter\bin\flutter.bat run -d $DeviceId
