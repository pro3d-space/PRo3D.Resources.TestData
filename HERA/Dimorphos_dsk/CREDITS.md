# Dimorphos global shape model — credits and provenance

## What this is

`g_00243mm_spc_obj_dimo_0000n00000_v004.obj.gz` is the **ASCII vertex–facet export of the
Dimorphos Digital Shape Kernel** shipped with the Hera SPICE Kernel Dataset, gzipped. It is
the file `kernels/dsk/g_00243mm_spc_obj_dimo_0000n00000_v004.obj` of that dataset, byte for
byte, with nothing added or removed.

| | |
|---|---|
| surface | `HERA_DIMORPHOS_M003_V01`, NAIF surface ID −658031004 |
| body / frame | `DIMORPHOS` (−658031) / `DIMORPHOS_FIXED` |
| vertices / plates | 1 579 014 / 3 145 728 |
| mean facet size | 0.243 m |
| extent | 179.5 × 169.4 × 115.2 m |
| **units** | **kilometres** (`INPUT_DATA_UNITS = DISTANCES = KM` in the DSK's own MKDSK setup) |
| method | stereophotoclinometry from DRACO images |
| built | DART Science Operations Center, 2023-05-30; made into a DSK by ESS, 2023-07-31 |
| compressed | gzip, 175 MB → 39 MB. GitHub refuses a file over 100 MB, and 175 MB of 15-digit decimals is not a thing to store raw |

`pro3d-tool` reads the `.obj.gz` directly — no need to unpack it:

```
pro3d-tool simulate-image --obj <this file> --obj-scale 1000 --time <epoch> ...
```

`--obj-scale 1000` converts the file's kilometres to the metres everything downstream uses.
It is the tool's default; the tool logs the resulting extent in metres so that a wrong
scale is visible in the first three lines of output.

## The `-preview.png` is NOT a texture

`g_00243mm_spc_obj_dimo_0000n00000_v004-preview.png` is the picture the ESA SPICE Service
ships next to each DSK — its own `aareadme.txt` calls it "an image example in png format
for convenience". It is a **rendering of the model from one viewpoint**, not a map, and it
has no relation to the mesh's (non-existent) texture coordinates.

The OBJ carries `v` and `f` lines only: no `vt`, no `vn`, no `mtllib`. There is no surface
texture for this shape model anywhere in the kernel dataset, which is why
`simulate-series --obj` can render the `micro` and `smooth` variants and refuses `delit`
and `baked` unless you supply your own `--obj-texture`.

## Why it is in this repository

It is the shape model that lets a simulated AFC frame be checked against renderers outside
PRo3D. At 5 km an AFC-1 pixel covers 0.48 m while the posts of `HERA/Dimorphos_opc` are
1.96 m apart — one post spans about 4 × 4 detector pixels, so frames rendered from that OPC
are limited by the shape model rather than by the sensor. This mesh is twice as fine as a
pixel.

It is also the model the metakernel's own DSK is built from, which makes one comparison
exact rather than approximate: `scripts/check-renderers.py` in the PRo3D repository
measures the silhouette of a PRo3D render of this OBJ against a `spiceypy` ray-cast of
`g_00243mm_spc_obj_dimo_0000n00000_v004.bds`, and the two agree at IoU **1.000** — 79 836
covered pixels against 79 837, uncentred and unscaled. Two renderers sharing nothing but
the kernels, on the same shape, drawing the same outline.

## Credit and licence

Source: **Hera Operational SPICE Kernel Dataset**, ESA SPICE Service (ESAC),
<https://doi.org/10.57780/esa-k25x2cv>, directory `kernels/dsk/`. Underlying shape model by
the **DART Science Operations Center** (JHU/APL).

> European Space Agency, ESA SPICE Service, HERA Operational SPICE Kernel Dataset,
> https://doi.org/10.57780/esa-k25x2cv

**Licence: [CC BY-NC 3.0 IGO](https://creativecommons.org/licenses/by-nc/3.0/igo/)** — the
licence of the ESA SPICE kernel dataset, *not* the licence of the rest of this repository.
Attribution as above, **no commercial use**. This file and the preview image are the only
files here under that licence.

Questions about the kernels themselves go to `spice@sciops.esa.int` (ESA SPICE Service),
not to the PRo3D maintainers.
