@echo off
setlocal
cd /d "%~dp0"
set "ISE_SETTINGS=D:\FPGA\14.7\ISE_DS\settings64.bat"
if not exist "%ISE_SETTINGS%" (
  echo [ERROR] ISE settings not found: %ISE_SETTINGS%
  pause
  exit /b 1
)
echo Close ISE Project Navigator before running this script.
echo [1/3] Loading ISE environment...
call "%ISE_SETTINGS%" >nul
if errorlevel 1 goto build_error
echo [2/3] Building PWM_40k.xise. This may take several minutes...
xtclsh auto_build.tcl
if errorlevel 1 goto build_error
if not exist "pwm_40k.bit" goto build_error
if /i "%~1"=="--build-only" exit /b 0
echo.
echo =============================================================
echo  BUILD COMPLETE. This programs volatile FPGA SRAM only.
echo  WARNING: Turn OFF the MIC4428 VS driver supply NOW.
echo  Keep FPGA board and JTAG cable powered.
echo  Press any key only after VS is OFF. Close this window to cancel.
echo =============================================================
pause
(echo setMode -bs
 echo setCable -port auto
 echo Identify -inferir
 echo assignFile -p 1 -file "pwm_40k.bit"
 echo Program -p 1
 echo quit) > _auto_jtag.cmd
echo [3/3] Programming JTAG device 1...
impact -batch _auto_jtag.cmd > auto_jtag.log 2>&1
set "IMPACT_EXIT=%errorlevel%"
type auto_jtag.log
del _auto_jtag.cmd >nul 2>&1
if not "%IMPACT_EXIT%"=="0" goto jtag_error
findstr /i /c:"Program Succeeded" /c:"'1': Programmed successfully." auto_jtag.log >nul
if errorlevel 1 goto jtag_error
echo [DONE] Programming confirmed. Verify four 40 kHz outputs before enabling VS.
pause
exit /b 0
:build_error
echo [ERROR] Build failed. Check the messages above; close ISE and check the source.
pause
exit /b 1
:jtag_error
echo [ERROR] Programming was not confirmed. Check auto_jtag.log, cable and JTAG device position.
echo Keep the MIC4428 VS supply OFF.
pause
exit /b 1
