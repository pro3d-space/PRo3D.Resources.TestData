# Multi-instrument test set — Dimorphos, 2027-03-21

Simulated observations of Dimorphos by three HERA instruments at the same four epochs
(14:00, 17:00, 20:00, 23:00 UTC), each in the layout its delivered product has, with
`.mbi.json` sidecars describing the exact render camera. Input for
[`pro3d-tool sample-layers`](https://github.com/pro3d-space/PRo3D/blob/develop/docs/Pro3DTool-SampleLayers.md),
and projectable in the viewer like delivered data.

Rendered against **`../Dimorphos_DRACO1_DRACO2_Earth/Dimorphos`**, the OPC next to this
folder, with `pro3d-tool simulate-image` and the `hera_plan` metakernel (v182, 2026-08-20).
The frames are only meaningful on the shape model they came from.

> **⚠ Aimed, not planned.** Every instrument is aimed at Dimorphos
> (`simulate-image --aim DIMORPHOS`) instead of left on its planned pointing: Milani's plan
> puts Dimorphos 2–3° off ASPECT's boresight, at the frame edge and at 14:00 partly
> outside it. The epochs, spacecraft positions, sun and roll are the planned ones; the
> pointing is not. Every sidecar says so with `PRO3DAIM = DIMORPHOS`. Do not use these
> frames to study what the mission will actually capture.

| Folder | Instrument | Spacecraft | Per epoch |
|---|---|---|---|
| `AFC/` | AFC-1 | Hera | `AFC1_SIM_<epoch>.png` — 1020x1020, 8-bit, lit render (Lommel-Seeliger, micro-structure, cast shadows), gain 4.5 |
| `ASPECT/` | ASPECT 2B | Milani | `ASP_SIM_<epoch>_<band>.tif` — 37 single-band float TIFFs, 640x512, `Vis_0`…`NIR2_12` (675–1575 nm) |
| `HSH/` | HyperScout 1B | Hera | `HSH_SIM_<epoch>_Stacked.tif` — one float TIFF of 25 planes, 409x217 (661–952 nm) |

Each image has a `.json` statistics sidecar (size, and for the cubes the band labels and
wavelengths), and each observation one `.mbi.json` declaring all its band files.

**Self-referential, like `../AFC_2027-03-21`.** Each observation was rendered *from* the
shape model and its sidecar is *the camera that render used*, so projecting it back onto the
same body from its own viewpoint must reproduce it. Measured through the viewer's stack
projection shader: AFC exact, ASPECT and HyperScout correlation 0.9998, p95 error below 1 DN.

**The spectra are made up.** The ASPECT and HyperScout band values are the render's I/F
times a synthetic reflectance curve (a red slope with a shallow 1 µm band). The curve makes
the bands differ, so a band read from the wrong file or plane shows up as a wrong value. It
is useless as spectroscopy. Sky is 0.

**Compressed.** The float TIFFs are Deflate-compressed (the frames are mostly sky), unlike
a delivered cube. PRo3D, GDAL and any LibTiff reader decompress them transparently.

## Using it

```
pro3d-tool sample-layers --opc ..\Dimorphos_DRACO1_DRACO2_Earth\Dimorphos --images AFC ASPECT HSH --out sample-layers
```

In the viewer: open `../Dimorphos_DRACO1_DRACO2_Earth/Dimorphos`, bind it to entity *Dimorphos* / frame
*DIMORPHOS_FIXED* (GIS tab → Surfaces), set the observed body to *Dimorphos*, then GIS tab →
**Projected Images** → *Import Directory* on one of the three folders. ASPECT is observed
from Milani at about 19 km and HyperScout at 7–8 km with 8.6 m pixels, so Dimorphos is only
40–50 pixels across in both: that is the real geometry.

## Regenerating

```
python scripts/make-sample-layers-test-data.py --opc <this repo>/HERA/Dimorphos_opc/Dimorphos_DRACO1_DRACO2_Earth/Dimorphos --out <this folder>
```

(the script lives in the PRo3D repository).
