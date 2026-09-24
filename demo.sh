#!/usr/bin/env bash
# ===========================================================================================
#  pro3d-tool demo: runs every pro3d-tool feature on the data in this folder.
#  What you need and what comes out: see DEMO.md.
# ===========================================================================================
set -u
cd "$(dirname "$0")"

# The pro3d-tool to run. Installed with `dotnet tool install PRo3D.Tool --global`, it is
# simply `pro3d-tool`. Set PRO3D_TOOL to a full path to try a different build instead.
TOOL="${PRO3D_TOOL:-pro3d-tool}"

OUT=demo-output
DIDYMOS=HERA/Didymos_ASPECT
ASPECT_IMAGES="HERA/Instrument Data"
DIMORPHOS=HERA/Dimorphos_opc/Dimorphos_DRACO1_DRACO2_Earth/Dimorphos
SIM="$OUT/4-simulated-images"
FAILED=0

# Runs one pro3d-tool command, its full output in a log file, and says whether it worked.
# LABEL, when set, names the command in steps that run several.
LABEL=""
run() {
    local log="$1"; shift
    local what=""
    [ -n "$LABEL" ] && what="$LABEL: "
    if "$TOOL" "$@" > "$log" 2>&1; then
        echo "       ${what}OK"
    else
        FAILED=$((FAILED + 1))
        echo "       ${what}FAILED. Last lines of $log:"
        tail -n 12 "$log" | sed 's/^/          /'
    fi
}

echo
echo " pro3d-tool demo"
echo " ==============="
echo " Results go to $OUT/ (replaced on every run)."

if ! command -v "$TOOL" > /dev/null 2>&1; then
    echo
    echo " pro3d-tool was not found. Install it with"
    echo "     dotnet tool install PRo3D.Tool --global"
    echo " and make sure ~/.dotnet/tools is on your PATH. See DEMO.md."
    exit 1
fi
if [ ! -d "$DIMORPHOS" ]; then
    echo
    echo " This does not look like the test data folder: $DIMORPHOS is missing."
    exit 1
fi

rm -rf "$OUT"
mkdir -p "$OUT"

# -------------------------------------------------------------------------------------------
echo
echo " [1/5] Check a shape model"
echo "       Validates the Didymos shape model and its search trees, which the other steps"
echo "       need to find where a line of sight meets the surface."
run "$OUT/1-check-shape-model.log" kdtree "$DIDYMOS"

if [ -z "${PRO3D_SPICE_KERNELS:-}" ]; then
    echo
    echo " The remaining steps need the SPICE kernels of the HERA mission (where the spacecraft,"
    echo " the sun and the asteroids are at a given time), and PRO3D_SPICE_KERNELS is not set."
    echo " Get them once with"
    echo "     git clone https://spiftp.esac.esa.int/git/hera.git"
    echo " and point PRO3D_SPICE_KERNELS at that folder, e.g. in ~/.bashrc or ~/.zshrc:"
    echo "     export PRO3D_SPICE_KERNELS=\$HOME/data/hera"
    echo " then open a new terminal and run ./demo.sh again. See DEMO.md."
    exit 1
fi

# -------------------------------------------------------------------------------------------
echo
echo " [2/5] Lighting angles of a real image"
echo "       For every pixel of an ASPECT image of Didymos: the angle of the sun, of the"
echo "       camera, and between the two, as images you can open."
run "$OUT/2-lighting-angles.log" sun-angles --opc "$DIDYMOS" --images "$ASPECT_IMAGES" --out "$OUT/2-lighting-angles" --false-color

# -------------------------------------------------------------------------------------------
echo
echo " [3/5] Where image points land on the surface"
echo "       Turns three points picked in the ASPECT image (demo/aspect-points.csv) into"
echo "       positions on Didymos, with latitude and longitude."
run "$OUT/3-image-points-on-surface.log" unproject --opc "$DIDYMOS" --images "$ASPECT_IMAGES" --input demo/aspect-points.csv --out "$OUT/3-image-points-on-surface.csv"

# -------------------------------------------------------------------------------------------
echo
echo " [4/5] Simulate what the instruments would see"
echo "       Dimorphos on 2027-03-21 at 14:00 and 20:00 UTC, as seen by HERA's AFC camera"
echo "       and HyperScout spectral camera and by Milani's ASPECT spectral camera, each"
echo "       pointed at Dimorphos. Then one image is projected back onto the shape model as"
echo "       a check: the result must look like the image itself."
for T in 14 20; do
    LABEL="AFC        $T:00"
    run "$OUT/4-simulate-AFC-${T}00.log" simulate-image --opc "$DIMORPHOS" --time "2027-03-21T$T:00:00Z" --aim DIMORPHOS \
        --instrument HERA_AFC-1 --write-mbi --gain 4.5 --out "$SIM/AFC/AFC1_SIM_20270321_${T}0000.png"
    LABEL="HyperScout $T:00"
    run "$OUT/4-simulate-HyperScout-${T}00.log" simulate-image --opc "$DIMORPHOS" --time "2027-03-21T$T:00:00Z" --aim DIMORPHOS \
        --instrument HERA_HSH --product --out "$SIM/HyperScout/HSH_SIM_20270321_${T}0000.tif"
    LABEL="ASPECT     $T:00"
    run "$OUT/4-simulate-ASPECT-${T}00.log" simulate-image --opc "$DIMORPHOS" --time "2027-03-21T$T:00:00Z" --aim DIMORPHOS \
        --instrument MILANI_ASPECT_NIR1 --product --out "$SIM/ASPECT/ASP_SIM_20270321_${T}0000.tif"
done
LABEL="projection check"
run "$OUT/4-projection-check.log" simulate-image --opc "$DIMORPHOS" --project "$SIM/AFC/AFC1_SIM_20270321_200000.png" --out "$OUT/4-projection-check.png"

LABEL=""

# -------------------------------------------------------------------------------------------
echo
echo " [5/5] Bring all instruments together on the surface"
echo "       For every point of the Dimorphos shape model: which of the six simulated images"
echo "       see it, where, under which light, and the value of every colour band, plus the"
echo "       slope and gravity of the surface there."
run "$OUT/5-all-instruments-on-surface.log" sample-layers --opc "$DIMORPHOS" \
    --images "$SIM/AFC" "$SIM/HyperScout" "$SIM/ASPECT" --attributes Slope,Gravity --out "$OUT/5-all-instruments-on-surface"

# -------------------------------------------------------------------------------------------
echo
if [ "$FAILED" -eq 0 ]; then
    echo " All steps succeeded. Have a look at:"
else
    echo " $FAILED step(s) failed -- see the messages above and the .log files. Results so far:"
fi
echo "   $OUT/2-lighting-angles/                  false-colour images of the three angles"
echo "   $OUT/3-image-points-on-surface.csv      the three points, now on Didymos"
echo "   $OUT/4-simulated-images/                 AFC, HyperScout and ASPECT images of Dimorphos"
echo "   $OUT/4-projection-check.png             a simulated image projected back onto the model"
echo "   $OUT/5-all-instruments-on-surface/       one table per image, one row per surface point"
echo " What the files mean: DEMO.md."
exit "$FAILED"
