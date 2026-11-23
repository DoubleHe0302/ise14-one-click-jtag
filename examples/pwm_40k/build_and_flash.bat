@echo off
setlocal
cd /d "%~dp0"
set "ISE_SETTINGS=D:\FPGA\14.7\ISE_DS\settings64.bat"
if not exist "%ISE_SETTINGS%" goto settings_error
if not exist "auto_build.tcl" goto settings_error
if not exist "auto_flash.cmd" goto settings_error
echo Close ISE and iMPACT GUI before continuing.
echo [1/3] Loading ISE and compiling the current source...
call "%ISE_SETTINGS%" >nul
if errorlevel 1 goto build_error
xtclsh auto_build.tcl
if errorlevel 1 goto build_error
if not exist "pwm_40k.bit" goto build_error
echo [2/3] Generating SPI x1 MCS file...
promgen -w -p mcs -c FF -o "pwm_40k_auto_flash" -s 16384 -u 0000 "pwm_40k.bit" -spi
if errorlevel 1 goto build_error
if not exist "pwm_40k_auto_flash.mcs" goto build_error
if /i "%~1"=="--build-only" exit /b 0
echo.
echo ====================================================================
echo WARNING: This ERASES and OVERWRITES the existing SPI Flash program.
echo Target: xc6slx16 position 1, W25Q128BV, SPI x1.
echo Turn OFF the MIC4428 VS supply before continuing.
echo Keep FPGA board and JTAG cable powered. Do NOT interrupt Flash writing.
echo The FPGA pins can change state during Flash programming.
echo Type FLASH and press Enter only after checking all of the above.
echo Close this window or type anything else to cancel.
echo ====================================================================
set "CONFIRM_FLASH="
set /p "CONFIRM_FLASH=Type FLASH to erase and program: "
if not "%CONFIRM_FLASH%"=="FLASH" goto cancelled
echo [3/3] Erasing, programming and verifying Flash. Please wait...
impact -batch auto_flash.cmd > auto_flash.log 2>&1
set "IMPACT_EXIT=%errorlevel%"
type auto_flash.log
if not "%IMPACT_EXIT%"=="0" goto flash_error
findstr /i /c:"ERROR:iMPACT" /c:"Program Failed" /c:"Verification failed" /c:"Verify Failed" auto_flash.log >nul
if not errorlevel 1 goto flash_error
findstr /i /c:"Program Succeeded" /c:"Programmed successfully" /c:"Programming completed successfully" auto_flash.log >nul
if errorlevel 1 goto flash_error
echo.
echo [CHECK] iMPACT reported programming success. Verify was requested.
echo Inspect auto_flash.log to confirm Flash verification succeeded.
echo Then power-cycle the board with MIC4428 VS OFF and check outputs.
echo Do not enable VS until the four 40 kHz outputs are verified.
pause
exit /b 0
:cancelled
echo Cancelled. Flash programming was not started.
pause
exit /b 1
:settings_error
echo [ERROR] ISE settings or companion script missing.
pause
exit /b 1
:build_error
echo [ERROR] Build or MCS generation failed. Flash was not programmed.
pause
exit /b 1
:flash_error
echo [ERROR] Flash programming was not confirmed. Check auto_flash.log.
echo Keep MIC4428 VS OFF. Do not assume old or new Flash contents are valid.
pause
exit /b 1
