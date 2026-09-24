# pro3d-tool demo

One script that shows everything `pro3d-tool` can do, on the data in this folder. It checks
a shape model, measures the lighting in a real image, finds where image points lie on an
asteroid, simulates what three instruments would see, and finally brings all of those images
together on the asteroid's surface. It takes about five minutes.

## What you need

| | How |
|---|---|
| **This folder** | `git clone https://github.com/pro3d-space/PRo3D.Resources.TestData.git` |
| **.NET 9** | [dotnet.microsoft.com/download](https://dotnet.microsoft.com/download) (the SDK) |
| **pro3d-tool** | `dotnet tool install PRo3D.Tool --global`, then open a new terminal |
| **The HERA mission's SPICE kernels** — the data that says where the spacecraft, the sun and the asteroids are at any moment | `git clone https://spiftp.esac.esa.int/git/hera.git`, then set `PRO3D_SPICE_KERNELS` to that folder (below) |
| **A graphics card with OpenGL** | for steps 2 and 4, which render images; any desktop or laptop GPU will do |

Set `PRO3D_SPICE_KERNELS` once, then open a new terminal:

```
setx PRO3D_SPICE_KERNELS C:\data\hera                          (Windows)
echo 'export PRO3D_SPICE_KERNELS=$HOME/data/hera' >> ~/.zshrc  (macOS; ~/.bashrc on Linux)
```

Without it, the demo runs step 1 and then tells you what is missing.

## Run it

In this folder:

```
demo.cmd          (Windows)
./demo.sh         (macOS, Linux)
```

Every step prints what it does and `OK` or `FAILED`. Results go to `demo-output/`, which is
replaced on every run; each step's full messages are in a `.log` file next to its results.

## What each step does

Each step below shows the command the script runs, so you can run it on its own or change
it. Run the commands in this folder. They are written with `\` at the end of a line to
continue on the next one; in the Windows command prompt use `^` instead, or put everything
on one line. The paths work unchanged on Windows.

### 1 · Check a shape model — `kdtree`

Checks the Didymos shape model (`HERA/Didymos_ASPECT`) and the search trees that let the other
steps find where a line of sight meets the surface. Shape models without them get them built.

```
pro3d-tool kdtree HERA/Didymos_ASPECT
```

**Look at:** `demo-output/1-check-shape-model.log`.

### 2 · Lighting angles of a real image — `sun-angles`

Takes a real ASPECT image of Didymos (`HERA/Instrument Data`) and works out, for every pixel,
three angles: how high the sun stands over the surface there (**incidence**), how steeply the
camera looks at it (**emission**), and the angle between sun and camera (**phase**). These
are what you need to compare the brightness of different places fairly.

```
pro3d-tool sun-angles \
    --opc         HERA/Didymos_ASPECT \
    --images      "HERA/Instrument Data" \
    --out         demo-output/2-lighting-angles \
    --false-color
```

**Look at:** `demo-output/2-lighting-angles/` — one image per angle, blue for small and red
for large angles, plus the exact values as TIFF files, pixel for pixel on top of the original.

### 3 · Where image points land on the surface — `unproject`

Three points were picked in the ASPECT image (`demo/aspect-points.csv`: the image centre, a
boulder, a point near the edge of the asteroid). This step finds where each lies on Didymos.

```
pro3d-tool unproject \
    --opc    HERA/Didymos_ASPECT \
    --images "HERA/Instrument Data" \
    --input  demo/aspect-points.csv \
    --out    demo-output/3-image-points-on-surface.csv
```

**Look at:** `demo-output/3-image-points-on-surface.csv` — per point its position on the
asteroid in metres, latitude, longitude and height, and its distance from the camera. A point
that misses the asteroid (off its edge) is marked as such rather than invented.

### 4 · Simulate what the instruments would see — `simulate-image`

Renders Dimorphos, the small moon of Didymos, on 21 March 2027 at 14:00 and 20:00 UTC, as
three instruments would see it: HERA's **AFC** camera, HERA's **HyperScout** spectral camera
(25 colour bands), and the **ASPECT** spectral camera on HERA's small companion Milani
(37 bands). Spacecraft positions, sun and camera orientation come from the SPICE kernels, and
each image comes with the same description file (`.mbi.json`) real instrument images have.

The spectral images use a made-up spectrum: they are for trying out tools, not for science.
The cameras are turned towards Dimorphos (`--aim`), whereas the mission plan points some of
them slightly elsewhere; see the [simulate-image documentation](https://github.com/pro3d-space/PRo3D/blob/develop/docs/Pro3DTool-SimulateImage.md).

Then one of the AFC images is projected back onto the shape model and rendered again from the
same camera. If everything is consistent, the result looks exactly like the image itself.

The three instruments at 14:00, and the projection check (the script also renders 20:00, and
checks that image):

```
pro3d-tool simulate-image \
    --opc        HERA/Dimorphos_opc/Dimorphos_DRACO1_DRACO2_Earth/Dimorphos \
    --time       2027-03-21T14:00:00Z \
    --aim        DIMORPHOS \
    --instrument HERA_AFC-1 \
    --write-mbi \
    --gain       4.5 \
    --out        demo-output/4-simulated-images/AFC/AFC1_SIM_20270321_140000.png

pro3d-tool simulate-image \
    --opc        HERA/Dimorphos_opc/Dimorphos_DRACO1_DRACO2_Earth/Dimorphos \
    --time       2027-03-21T14:00:00Z \
    --aim        DIMORPHOS \
    --instrument HERA_HSH \
    --product \
    --out        demo-output/4-simulated-images/HyperScout/HSH_SIM_20270321_140000.tif

pro3d-tool simulate-image \
    --opc        HERA/Dimorphos_opc/Dimorphos_DRACO1_DRACO2_Earth/Dimorphos \
    --time       2027-03-21T14:00:00Z \
    --aim        DIMORPHOS \
    --instrument MILANI_ASPECT_NIR1 \
    --product \
    --out        demo-output/4-simulated-images/ASPECT/ASP_SIM_20270321_140000.tif

pro3d-tool simulate-image \
    --opc     HERA/Dimorphos_opc/Dimorphos_DRACO1_DRACO2_Earth/Dimorphos \
    --project demo-output/4-simulated-images/AFC/AFC1_SIM_20270321_140000.png \
    --out     demo-output/4-projection-check.png
```

`--write-mbi` adds the description file to the AFC image; the spectral images (`--product`)
always get one. `--gain` sets the brightness of the AFC image, the same for every time, so
images of different times can be compared.

**Look at:** `demo-output/4-simulated-images/` (`AFC/` holds PNG images; `HyperScout/` and
`ASPECT/` hold multi-band TIFF images, which image tools such as QGIS can open) and
`demo-output/4-projection-check.png` next to
`demo-output/4-simulated-images/AFC/AFC1_SIM_20270321_200000.png`. These images can also be
loaded into the PRo3D viewer and projected onto Dimorphos.

### 5 · Bring all instruments together on the surface — `sample-layers`

The six images from step 4 come from different cameras, with different pixel sizes, views and
orientations, so their pixels cannot be compared directly. This step compares them on the
asteroid instead: for every point of the Dimorphos shape model (2.3 million) it records which
images see that point, where in each image it lies, the lighting angles there, and the value
of every colour band — plus the surface's slope and gravity at that point.

```
pro3d-tool sample-layers \
    --opc        HERA/Dimorphos_opc/Dimorphos_DRACO1_DRACO2_Earth/Dimorphos \
    --images     demo-output/4-simulated-images/AFC \
                 demo-output/4-simulated-images/HyperScout \
                 demo-output/4-simulated-images/ASPECT \
    --attributes Slope,Gravity \
    --out        demo-output/5-all-instruments-on-surface
```

**Look at:** `demo-output/5-all-instruments-on-surface/`:

| File | Contents |
|---|---|
| `vertices.csv` | every surface point: an id and its position |
| `images/<image>.csv` | per image, one row per point it sees: position in the image, the three angles, all colour bands |
| `attributes/Slope.csv`, `attributes/Gravity.csv` | the surface property per point |
| `manifest.json` | which image is which: instrument, time, colour band wavelengths |

The files share the point id, so one point's values from every instrument can be put side by
side, e.g. in a spreadsheet or with Python. Details:
[sample-layers documentation](https://github.com/pro3d-space/PRo3D/blob/develop/docs/Pro3DTool-SampleLayers.md).

## If something goes wrong

| Message | What to do |
|---|---|
| `pro3d-tool was not found` | Install it (see above) and open a **new** terminal. On macOS/Linux, `~/.dotnet/tools` must be on your `PATH`. |
| `PRO3D_SPICE_KERNELS is not set` | Set it (see above) and open a new terminal. |
| a step says `FAILED` | Its last lines are shown; the whole story is in its `.log` file. Steps 2 and 4 need a working graphics driver. |
| `no kernel found` / `no ephemeris` | The kernel folder is incomplete or too old; `git pull` inside it. |

## Using another build

To run the demo with a `pro3d-tool` other than the installed one, set `PRO3D_TOOL` to its full
path before starting the script.

More about each command: [pro3d-tool documentation](https://github.com/pro3d-space/PRo3D/blob/develop/docs/Pro3DTool.md).
