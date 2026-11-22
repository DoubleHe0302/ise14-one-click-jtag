@echo off
setlocal
set "ISE_GENERIC_SCRIPT=%~f0"
set "ISE_GENERIC_MODE=flash"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$s=[IO.File]::ReadAllText($env:ISE_GENERIC_SCRIPT); $p=$s.LastIndexOf('# POWERSHELL_BODY_BEGIN'); if($p -lt 0){exit 1}; $code=$s.Substring($p+23); & ([scriptblock]::Create($code)) %*"
exit /b %errorlevel%
# POWERSHELL_BODY_BEGIN
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $env:ISE_GENERIC_SCRIPT
Set-Location -LiteralPath $root
$mode = $env:ISE_GENERIC_MODE
$buildOnly = $args -contains '--build-only'
$settings = 'D:\FPGA\14.7\ISE_DS\settings64.bat'
$token = [guid]::NewGuid().ToString('N')
$tempPaths = @()
function TempFile([string]$extension) {
    $p = Join-Path $root ("_ise_generic_" + $token + $extension)
    $script:tempPaths += $p
    return $p
}
function RunISE([string]$command, [string]$log) {
    $runner = TempFile '.bat'
    [IO.File]::WriteAllText($runner, "@echo off`r`ncall `"$settings`" >nul`r`nif errorlevel 1 exit /b 1`r`n$command >`"$log`" 2>&1`r`nexit /b %errorlevel%`r`n", [Text.Encoding]::ASCII)
    & $env:ComSpec /d /c "`"$runner`""
    $code = $LASTEXITCODE
    Get-Content -LiteralPath $log | ForEach-Object { Write-Host $_ }
    return $code
}
function Ask([string]$label, [string]$default) {
    $value = Read-Host "$label [$default]"
    if ([string]::IsNullOrWhiteSpace($value)) { return $default }
    return $value.Trim()
}
try {
    if ($root -match '[^ -~]' -or $root -match '[&|<>%!^]') { throw 'Project path must use ASCII characters and must not contain CMD special characters.' }
    if (-not (Test-Path -LiteralPath $settings)) { throw "ISE settings not found: $settings. Edit the settings path inside the bat file." }
    $projects = @(Get-ChildItem -LiteralPath $root -Filter '*.xise' -File)
    if ($projects.Count -eq 0) { throw 'No .xise project in this folder.' }
    if ($projects.Count -gt 1) {
        for ($i=0; $i -lt $projects.Count; $i++) { Write-Host ("{0}: {1}" -f ($i+1), $projects[$i].Name) }
        $selected = Read-Host 'Choose project number'
        $n = 0
        if (-not [int]::TryParse($selected,[ref]$n) -or $n -lt 1 -or $n -gt $projects.Count) { throw 'Invalid project selection.' }
        $project = $projects[$n-1]
    } else { $project = $projects[0] }
    if ($project.Name -match '[^ -~]' -or $project.Name -match '[&|<>%!^]') { throw 'Project filename must use ASCII characters without CMD special characters.' }
    [xml]$xml = Get-Content -LiteralPath $project.FullName -Raw
    $props = @{}
    foreach ($item in $xml.SelectNodes("//*[local-name()='property']")) {
        $name = $item.GetAttribute('name','http://www.xilinx.com/XMLSchema')
        $props[$name] = $item.GetAttribute('value','http://www.xilinx.com/XMLSchema')
    }
    $topValue = $props['Implementation Top']
    $device = $props['Device']
    if ($topValue -notmatch '^Module\|([A-Za-z_][A-Za-z0-9_$]*)$') { throw 'Cannot determine top module. Set Implementation Top in ISE and save the project.' }
    $top = $Matches[1]
    if ($device -notmatch '^xc[0-9a-z]+$') { throw 'Cannot determine FPGA device from project.' }
    $bit = Join-Path $root ($top + '.bit')
    Write-Host "Project: $($project.Name)   Top: $top   FPGA: $device"
    Write-Host 'Close ISE Project Navigator and iMPACT GUI before running.'
    $env:ISE_GENERIC_PROJECT = $project.Name
    $tcl = TempFile '.tcl'
    $tclBody = @"
if {[catch {
    project open `$::env(ISE_GENERIC_PROJECT)
    process run "Generate Programming File" -force rerun_all
    project close
} message]} {
    puts stderr "BUILD ERROR: `$message"
    catch {project close}
    exit 1
}
puts "BUILD COMPLETE"
exit 0
"@
    [IO.File]::WriteAllText($tcl, $tclBody, [Text.Encoding]::ASCII)
    $start = Get-Date
    $buildLog = Join-Path $root 'ise_generic_build.log'
    $rc = RunISE "xtclsh `"$tcl`"" $buildLog
    if ($rc -ne 0 -or -not (Test-Path -LiteralPath $bit)) { throw 'Build failed or bit file missing. See ise_generic_build.log.' }
    if ((Get-Item -LiteralPath $bit).LastWriteTime -lt $start.AddSeconds(-2)) { throw 'Bit file was not updated. Refusing to use an old bit file.' }
    Write-Host "Built bit file: $bit"
    if ($mode -eq 'flash') {
        Write-Host 'SPI Flash settings must match the actual board and bitstream boot configuration.'
        if ($buildOnly) { $flashType='W25Q128BV'; $size='16384'; $width='1' }
        else {
            $flashType = Read-Host 'Enter exact iMPACT SPI Flash name (example W25Q128BV)'
            $size = Read-Host 'Enter Flash capacity in KiB (example 16384 for 128 Mbit)'
            $width = Read-Host 'Enter configured SPI bus width (1, 2 or 4)'
        }
        if ($flashType -notmatch '^[A-Za-z0-9_/-]+$' -or $size -notmatch '^[1-9][0-9]*$' -or $width -notmatch '^(1|2|4)$') { throw 'Invalid Flash settings.' }
        if ($width -ne '1') { throw 'This template supports SPI x1 only. Other widths require board-specific settings.' }
        $mcsBase = Join-Path $root ($top + '_generic_flash')
        $mcs = $mcsBase + '.mcs'
        $startMcs = Get-Date
        $rc = RunISE "promgen -w -p mcs -c FF -o `"$mcsBase`" -s $size -u 0000 `"$bit`" -spi" (Join-Path $root 'ise_generic_promgen.log')
        if ($rc -ne 0 -or -not (Test-Path -LiteralPath $mcs) -or (Get-Item -LiteralPath $mcs).LastWriteTime -lt $startMcs.AddSeconds(-2)) { throw 'MCS generation failed or output was not updated.' }
        Write-Host "Generated: $mcs"
    }
    if ($buildOnly) { Write-Host 'BUILD ONLY: no JTAG action.'; exit 0 }
    $position = Ask 'FPGA JTAG chain position' '1'
    if ($position -notmatch '^[1-9][0-9]*$') { throw 'Invalid JTAG position.' }
    Write-Host ''
    Write-Host 'Turn OFF external power stages / driver VS before any JTAG action.'
    Write-Host 'Keep the FPGA board and JTAG adapter powered; close this window to cancel.'
    Write-Host "Expected FPGA: $device, JTAG position: $position"
    if ($mode -eq 'flash') { Write-Host "WARNING: Flash $flashType, $size KiB, x$width will be ERASED and OVERWRITTEN." }
    if ((Read-Host 'Type CHECK after switching external power OFF') -cne 'CHECK') { throw 'Cancelled.' }
    $idCmd = TempFile '.cmd'
    [IO.File]::WriteAllText($idCmd, "setMode -bs`r`nsetCable -port auto`r`nIdentify -inferir`r`nquit`r`n", [Text.Encoding]::ASCII)
    $idLog = Join-Path $root 'ise_generic_identify.log'
    $rc = RunISE "impact -batch `"$idCmd`"" $idLog
    $idText = Get-Content -LiteralPath $idLog -Raw
    $pattern = "(?im)'" + [regex]::Escape($position) + "': Added Device\s+" + [regex]::Escape($device) + "\b"
    if ($rc -ne 0 -or $idText -notmatch $pattern -or $idText -match '(?i)ERROR:iMPACT|Cable autodetection failed') { throw 'JTAG identification did not confirm the project FPGA at the chosen position. See ise_generic_identify.log.' }
    Write-Host 'JTAG FPGA identification matches.'
    if ($mode -eq 'flash') {
        Write-Host "FINAL WARNING: $flashType Flash will be erased. Keep external driver power OFF."
        if ((Read-Host 'Type FLASH to erase and program') -cne 'FLASH') { throw 'Cancelled; Flash was not erased.' }
    }
    $cmdfile = TempFile '.cmd'
    $bitName = [IO.Path]::GetFileName($bit)
    $lines = @('setMode -bs','setCable -port auto','Identify -inferir',("assignFile -p $position -file `"$bitName`""))
    if ($mode -eq 'flash') {
        $lines += 'identifyMPM'
        $lines += "attachflash -position $position -spi `"$flashType`""
        $lines += "assignfiletoattachedflash -position $position -file `"$([IO.Path]::GetFileName($mcs))`""
        $lines += "Program -p $position -dataWidth $width -spionly -e -v -loadfpga"
    } else { $lines += "Program -p $position" }
    $lines += 'quit'
    [IO.File]::WriteAllLines($cmdfile, $lines, [Text.Encoding]::ASCII)
    $programLog = Join-Path $root 'ise_generic_program.log'
    $rc = RunISE "impact -batch `"$cmdfile`"" $programLog
    $logText = Get-Content -LiteralPath $programLog -Raw
    if ($rc -ne 0 -or $logText -match '(?i)ERROR:iMPACT|Program Failed|Verification failed|Verify Failed|Cable autodetection failed') { throw 'Programming failed or was not confirmed; check ise_generic_program.log.' }
    if ($mode -eq 'flash') {
        Write-Host 'Flash operation completed. Verification was requested; inspect ise_generic_program.log for Flash programming AND verification success.'
        Write-Host 'Power-cycle the FPGA with external driver power OFF, then measure the outputs before enabling it.'
    } else {
        if ($logText -notmatch "(?i)'$position': Programmed successfully|Program Succeeded") { throw 'No recognizable FPGA success message; check ise_generic_program.log.' }
        Write-Host 'FPGA SRAM programming confirmed. Measure outputs before enabling external power.'
        Write-Host 'SRAM configuration is lost when FPGA power is removed.'
    }
} catch {
    Write-Host "[ERROR] $($_.Exception.Message)"
    Write-Host 'Keep external driver power OFF. If Flash writing started, its contents may be invalid.'
    $script:failed = $true
} finally {
    foreach ($p in $tempPaths) { Remove-Item -LiteralPath $p -Force -ErrorAction SilentlyContinue }
    Remove-Item Env:ISE_GENERIC_PROJECT -ErrorAction SilentlyContinue
}
if (-not $buildOnly) { [void](Read-Host 'Press Enter to close') }
if ($failed) { exit 1 }
exit 0
