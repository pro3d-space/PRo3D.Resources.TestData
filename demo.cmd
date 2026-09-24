@echo off
setlocal EnableExtensions
REM ===========================================================================================
REM  pro3d-tool demo: runs every pro3d-tool feature on the data in this folder.
REM  What you need and what comes out: see DEMO.md.
REM ===========================================================================================
cd /d "%~dp0"

REM The pro3d-tool to run. Installed with `dotnet tool install PRo3D.Tool --global`, it is
REM simply `pro3d-tool`. Set PRO3D_TOOL to a full path to try a different build instead.
if not defined PRO3D_TOOL set "PRO3D_TOOL=pro3d-tool"

set "OUT=demo-output"
set "DIDYMOS=HERA\Didymos_ASPECT"
set "ASPECT_IMAGES=HERA\Instrument Data"
set "DIMORPHOS=HERA\Dimorphos_opc\Dimorphos_DRACO1_DRACO2_Earth\Dimorphos"
set "SIM=%OUT%\4-simulated-images"
set FAILED=0

echo.
echo  pro3d-tool demo
echo  ===============
echo  Results go to %OUT%\ (replaced on every run).

"%PRO3D_TOOL%" --version >nul 2>nul
if errorlevel 9009 goto :no_tool
if not exist "%DIMORPHOS%" (
    echo.
    echo  This does not look like the test data folder: %DIMORPHOS% is missing.
    exit /b 1
)

if exist "%OUT%" rd /s /q "%OUT%"
mkdir "%OUT%"

REM -------------------------------------------------------------------------------------------
echo.
echo  [1/5] Check a shape model
echo        Validates the Didymos shape model and its search trees, which the other steps
echo        need to find where a line of sight meets the surface.
"%PRO3D_TOOL%" kdtree "%DIDYMOS%" > "%OUT%\1-check-shape-model.log" 2>&1
call :result "%OUT%\1-check-shape-model.log"

if not defined PRO3D_SPICE_KERNELS goto :no_kernels

REM -------------------------------------------------------------------------------------------
echo.
echo  [2/5] Lighting angles of a real image
echo        For every pixel of an ASPECT image of Didymos: the angle of the sun, of the
echo        camera, and between the two, as images you can open.
"%PRO3D_TOOL%" sun-angles --opc "%DIDYMOS%" --images "%ASPECT_IMAGES%" --out "%OUT%\2-lighting-angles" --false-color > "%OUT%\2-lighting-angles.log" 2>&1
call :result "%OUT%\2-lighting-angles.log"

REM -------------------------------------------------------------------------------------------
echo.
echo  [3/5] Where image points land on the surface
echo        Turns three points picked in the ASPECT image (demo\aspect-points.csv) into
echo        positions on Didymos, with latitude and longitude.
"%PRO3D_TOOL%" unproject --opc "%DIDYMOS%" --images "%ASPECT_IMAGES%" --input demo\aspect-points.csv --out "%OUT%\3-image-points-on-surface.csv" > "%OUT%\3-image-points-on-surface.log" 2>&1
call :result "%OUT%\3-image-points-on-surface.log"

REM -------------------------------------------------------------------------------------------
echo.
echo  [4/5] Simulate what the instruments would see
echo        Dimorphos on 2027-03-21 at 14:00 and 20:00 UTC, as seen by HERA's AFC camera
echo        and HyperScout spectral camera and by Milani's ASPECT spectral camera, each
echo        pointed at Dimorphos. Then one image is projected back onto the shape model as
echo        a check: the result must look like the image itself.
for %%T in (14 20) do (
    "%PRO3D_TOOL%" simulate-image --opc "%DIMORPHOS%" --time 2027-03-21T%%T:00:00Z --aim DIMORPHOS --instrument HERA_AFC-1 --write-mbi --gain 4.5 --out "%SIM%\AFC\AFC1_SIM_20270321_%%T0000.png" > "%OUT%\4-simulate-AFC-%%T00.log" 2>&1
    call :result "%OUT%\4-simulate-AFC-%%T00.log" "AFC        %%T:00"
    "%PRO3D_TOOL%" simulate-image --opc "%DIMORPHOS%" --time 2027-03-21T%%T:00:00Z --aim DIMORPHOS --instrument HERA_HSH --product --out "%SIM%\HyperScout\HSH_SIM_20270321_%%T0000.tif" > "%OUT%\4-simulate-HyperScout-%%T00.log" 2>&1
    call :result "%OUT%\4-simulate-HyperScout-%%T00.log" "HyperScout %%T:00"
    "%PRO3D_TOOL%" simulate-image --opc "%DIMORPHOS%" --time 2027-03-21T%%T:00:00Z --aim DIMORPHOS --instrument MILANI_ASPECT_NIR1 --product --out "%SIM%\ASPECT\ASP_SIM_20270321_%%T0000.tif" > "%OUT%\4-simulate-ASPECT-%%T00.log" 2>&1
    call :result "%OUT%\4-simulate-ASPECT-%%T00.log" "ASPECT     %%T:00"
)
"%PRO3D_TOOL%" simulate-image --opc "%DIMORPHOS%" --project "%SIM%\AFC\AFC1_SIM_20270321_200000.png" --out "%OUT%\4-projection-check.png" > "%OUT%\4-projection-check.log" 2>&1
call :result "%OUT%\4-projection-check.log" "projection check"

REM -------------------------------------------------------------------------------------------
echo.
echo  [5/5] Bring all instruments together on the surface
echo        For every point of the Dimorphos shape model: which of the six simulated images
echo        see it, where, under which light, and the value of every colour band, plus the
echo        slope and gravity of the surface there.
"%PRO3D_TOOL%" sample-layers --opc "%DIMORPHOS%" --images "%SIM%\AFC" "%SIM%\HyperScout" "%SIM%\ASPECT" --attributes Slope,Gravity --out "%OUT%\5-all-instruments-on-surface" > "%OUT%\5-all-instruments-on-surface.log" 2>&1
call :result "%OUT%\5-all-instruments-on-surface.log"

REM -------------------------------------------------------------------------------------------
echo.
if "%FAILED%"=="0" (
    echo  All steps succeeded. Have a look at:
) else (
    echo  %FAILED% step^(s^) failed -- see the messages above and the .log files. Results so far:
)
echo    %OUT%\2-lighting-angles\                  false-colour images of the three angles
echo    %OUT%\3-image-points-on-surface.csv      the three points, now on Didymos
echo    %OUT%\4-simulated-images\                 AFC, HyperScout and ASPECT images of Dimorphos
echo    %OUT%\4-projection-check.png             a simulated image projected back onto the model
echo    %OUT%\5-all-instruments-on-surface\       one table per image, one row per surface point
echo  What the files mean: DEMO.md.
exit /b %FAILED%

REM -------------------------------------------------------------------------------------------
:result
REM %1 = the step's log file, %2 = an optional label for steps that run several commands
set "RC=%errorlevel%"
set "WHAT=%~2"
if defined WHAT set "WHAT=%WHAT%: "
if not "%RC%"=="0" (
    set /a FAILED+=1
    echo        %WHAT%FAILED. Last lines of %~1:
    powershell -NoProfile -Command "Get-Content -Tail 12 '%~1' | ForEach-Object { '          ' + $_ }"
) else (
    echo        %WHAT%OK
)
exit /b 0

:no_tool
echo.
echo  pro3d-tool was not found. Install it with
echo      dotnet tool install PRo3D.Tool --global
echo  and open a new terminal, so that it is on the PATH. See DEMO.md.
exit /b 1

:no_kernels
echo.
echo  The remaining steps need the SPICE kernels of the HERA mission (where the spacecraft,
echo  the sun and the asteroids are at a given time), and PRO3D_SPICE_KERNELS is not set.
echo  Get them once with
echo      git clone https://spiftp.esac.esa.int/git/hera.git
echo  and point PRO3D_SPICE_KERNELS at that folder, e.g.
echo      setx PRO3D_SPICE_KERNELS C:\data\hera
echo  then open a new terminal and run demo.cmd again. See DEMO.md.
exit /b 1
