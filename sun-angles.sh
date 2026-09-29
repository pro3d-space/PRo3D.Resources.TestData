#!/usr/bin/env bash
cd "$(dirname "$0")"
# HERA SPICE kernels: your clone of https://spiftp.esac.esa.int/git/hera.git
# (the folder holding kernels/, or kernels/ itself, the one with mk/ inside)
export PRO3D_SPICE_KERNELS=$HOME/data/hera
pro3d-tool sun-angles --opc HERA/Didymos_ASPECT --images "HERA/Instrument Data" --out demo-output/sun-angles --false-color
