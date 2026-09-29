@echo off
cd /d "%~dp0"
REM HERA SPICE kernels: your clone of https://spiftp.esac.esa.int/git/hera.git
REM (the folder holding kernels\, or kernels\ itself, the one with mk\ inside)
set "PRO3D_SPICE_KERNELS=C:\data\hera"
pro3d-tool sun-angles --opc HERA\Didymos_ASPECT --images "HERA\Instrument Data" --out demo-output\sun-angles --false-color
