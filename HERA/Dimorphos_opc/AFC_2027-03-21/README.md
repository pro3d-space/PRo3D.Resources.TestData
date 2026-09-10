# AFC-1 projection test set — Dimorphos, 2027-03-21

Eight simulated HERA/AFC-1 frames with `.mbi.json` sidecars, plus a ready-to-open
scene, for checking that image projection lands correctly in the PRo3D viewer.

Rendered against **`../Dimorphos`**, the OPC next to this folder. The frames are
only meaningful on the shape model they came from.

**These are self-referential on purpose.** Each frame was rendered *from* the
shape model, and its sidecar describes *the camera that render actually used*. So
projecting a frame back onto the same body and looking from that frame's own
viewpoint must reproduce the frame. There is no metadata to doubt: the render and
the sidecar are the same camera. If it does not line up, the fault is in the
projection, not in the data.

## The files

| file | what it is |
|---|---|
| `ProjectionTest.pro3d` | scene with everything preset. Its paths are absolute (the machine it was generated on); PRo3D's `tests-ui` rewrites them to this checkout at runtime |
| `AFC1_DRACO2_<date>_<time>.png` | the **DRACO_2** mosaic as the camera sees it, no lighting. The frames to use for judging registration: they carry real surface detail. |
| `AFC1_SIM_<date>_<time>.png` | lit render — Lommel-Seeliger shading, micro-structure, cast shadows, constant albedo. Fixed gain 4.492 across the four. |
| `*.mbi.json` | `SC_QUAT0..3` (spacecraft→J2000, w,x,y,z) and `TRG_POSX/Y/Z` (target minus spacecraft, km, J2000). |

**Why DRACO_2 and not DRACO_1.** The two layers are different DART imaging
passes covering different hemispheres, and at these epochs HERA is looking at the
DRACO_2 side. Measured on the 14:00 frame: DRACO_1 gives mean DN 0.46 with a 99th
percentile of **0** — an essentially black image — while DRACO_2 gives mean 3.78
and a 99th percentile of 155. Correlating a projection against a black frame
scores well and proves nothing, so the DRACO_1 variants were dropped from this
set rather than left as a trap.

Epochs 14:00, 17:00, 20:00, 23:00 UTC. Dimorphos rotates in about 11.9 h, so the
four see genuinely different faces — good for a multi-image stack, and for
checking that flying between them carries the scene clock with it. Ranges
6.7–8.4 km.

## Using it

Open `ProjectionTest.pro3d`. It already has: the OPC loaded and bound to entity
*Dimorphos* / frame *DIMORPHOS_FIXED*, observed body *Dimorphos*, time
2027-03-21T20:00, texture DRACO_2, near plane 10, focal 122.563 mm, and the
camera on the 20:00 frame's axis at its own 6 706.8 m — the closest pass, and so
the frame with the most surface detail.

Then: GIS tab → **Projected Images** → *Import Directory* → this folder →
untick **Transfer Function** (*Orientation Source* is already MBI) → click a frame's
location arrow to fly to it → **+** to project.

### Starting from an empty PRo3D instead

Projection has three preconditions, and until all three are met the fly-to does
nothing (it now names whichever is missing, in the log):

1. **Observed body** — GIS tab → *Current Observation Settings* → `Dimorphos`
2. **Surface bound to a SPICE body** — GIS tab → *Surfaces* → Entity
   `Dimorphos`, Reference Frame `DIMORPHOS_FIXED`
3. **A time inside the kernels' coverage** — 2027-03-21T14:00. PRo3D's default is
   2025-03-10, where HERA has no ephemeris for Dimorphos: nothing resolves, and
   because SPICE calls serialise on a global lock the failing calls repeat every
   frame and the interface crawls.

Also set the SPICE kernel to `hera_plan.tm`.

### Settings that matter

- **Orientation Source = MBI**, which is now the default. The alternative,
  *SPICE*, ignores the pointing in the sidecar entirely — it aims at the body
  centre with a fixed roll, so frames land on the body with their features out of
  place. Check it if a frame lands but does not match.
- **Transfer Function off**, so the layer is painted as its own RGB and can be
  compared with the PNG rather than with a colour-mapped version of it.
- **Near plane 10.** At ~8 km a 0.1 near plane cannot separate the near and far
  surfaces of a 177 m body and the far side punches through.
- **Focal 122.563 mm** = AFC-1's 5.5307°. This also makes fly-to land exactly at
  the instrument: the standoff frames the footprint in the *viewer's* field of
  view, so when the two match, standoff = range.
- **Roughly square window.** The standoff fits the footprint in the *vertical*
  field of view, so a wide window stands off further (standoff ≈ range × window
  aspect) and the body looks smaller than in the source frame.
- **Visibility → RelativeCount** shows coverage directly. Trust that over
  comparing screenshots: a before/after diff counts pixels that *changed*, which
  cannot tell "not covered" from "covered by a value that happens to match".

## What "correct" measured like

Projecting `AFC1_DRACO2_20270321_200000.png` back from its own camera, viewer
window 1100×1100:

| rung | correlation at zero shift | best shift found |
|---|---|---|
| tool, single-image shader | **0.9999** | (0, 0) |
| tool, stack shader | **0.9999** | (0, 0) |
| **viewer** | **0.9705** | **(0, 0)** |

plus the checks a correlation alone cannot make: the identity beats every flip
and rotation by **0.88**, and coverage from the shader's own coverage view is
**99.2%**.

The silhouette check on a lit frame gives IoU **0.87**. Read that as a gate, not
a measurement: the source frame's unlit limb is DN 0, indistinguishable from
space, while the viewer's mask is "not the clear colour" and includes it. Across
these four epochs the disk fills 0.90–0.93 of its own bounding ellipse, which is
the size of that bias.

## Regenerating

```
pro3d-tool simulate-image --opc <...>\Dimorphos_opc\Dimorphos \
    --time 2027-03-21T20:00:00Z --body DIMORPHOS --frame DIMORPHOS_FIXED \
    --observer HERA --instrument HERA_AFC-1 \
    --texture-only --texture-layer DRACO_2 --write-mbi \
    --out AFC1_DRACO2_20270321_200000.png

# lit variant: drop --texture-only/--texture-layer, add --gain 4.492
```

`--texture-layer` takes a name or an index and lists what the OPC declares if the
name does not match. It matters: without it the tool draws the patch's *default*
layer, which is not necessarily the one a scene displays.

Or generate the whole set in one go, which is how it was made — the script also
checks every sidecar it writes and reports any render that failed:

```
python scripts/make-projection-test-data.py     --opc <...>/Dimorphos_opc/Dimorphos --out <this folder>     --texture-layer DRACO_2 --scene-template <an existing .pro3d>
```

Needs SPICE kernels — `PRO3D_SPICE_KERNELS` pointing at a clone of
`https://spiftp.esac.esa.int/git/hera.git` (or its `kernels` subdirectory).

## Sidecar convention

`SC_QUAT` is spacecraft→J2000 as (w, x, y, z); `TRG_POS` is target **minus**
spacecraft in km, J2000, centred on the **target**. With `A` the rotation matrix
from `SC_QUAT`:

```
Aᵀ · TRG_POS  ≈  (0, 0, +1)
```

Every frame here satisfies it to 1e-5, and each was round-tripped through the
projector at write time (boresight 0.000000°, worst frustum corner 0.000 px). The
residual `(0.0023, 0.0012)` is not error — it is AFC-1's real 0.145° offset from
the direction the spacecraft tracks.

Worth stating because a real delivery can get this wrong, and the projector will
follow a wrong sidecar faithfully. If a delivery's frames land on the body but in
the wrong place, check this invariant on its sidecars before suspecting the
projection.
