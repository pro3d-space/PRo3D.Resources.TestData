# PRo3D.Resources.TestData

Binary test fixtures for the PRo3D test suite, kept out of the main
[PRo3D](https://github.com/pro3d-space/PRo3D) repository so that a plain clone stays small.

## Contents

| Path | Description |
|---|---|
| `1087_004779_MSLMST_0011/` | Part of Stimson_1087 dataset - the whole dataset can be downloaded here : http://download.vrvis.at/acquisition/32987e2792e0/PRo3D/Stimson_1087.zip |
| `HERA/Dimorphos_opc/Dimorphos/` | Dimorphos OPC (1.1 GB; DRACO_1/DRACO_2 texture layers, outward-wound) — the shape model for image-projection tests |
| `HERA/Dimorphos_opc/AFC_2027-03-21/` | simulated HERA/AFC-1 frames of that OPC with `.mbi.json` sidecars describing the exact render camera, plus a scene template; used by PRo3D's `tests-ui` (`PRO3D_TEST_DATA`) — see its README |
| `HERA/Dimorphos_dsk/` | the Dimorphos shape model the Hera SPICE kernels ship (39 MB gzipped OBJ, 0.24 m facets, in **kilometres**) — the fine shape `pro3d-tool --obj` renders from, and the one a SPICE ray-cast of the kernels' own DSK agrees with exactly. **Separately licensed, CC BY-NC 3.0 IGO — see [its CREDITS.md](HERA/Dimorphos_dsk/CREDITS.md)** |

## How PRo3D consumes this

The Playwright tests in PRo3D's `tests-ui/` read this checkout from the `PRO3D_TEST_DATA`
environment variable.

The Expecto suite also mounts it as a git submodule at `src/Tests/data/opc`:

```
git submodule update --init --recursive
```

`src/Tests/Features/TestHelpers.fs` resolves the surface as
`<repo>/src/Tests/data/opc/1087_004779_MSLMST_0011`.

The suite does **not** require this data. When the submodule is not checked out,
`Render.available` returns `false` and every OPC-backed test skips with
`no OPC test data at ...` rather than failing. Only clone with `--recurse-submodules`
if you intend to exercise the rendering and scene-lifecycle sections.

