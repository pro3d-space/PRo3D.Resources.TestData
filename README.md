# PRo3D.Resources.TestData

Binary test fixtures for the PRo3D test suite, kept out of the main
[PRo3D](https://github.com/pro3d-space/PRo3D) repository so that a plain clone stays small.

## Contents

| Path | Description |
|---|---|
| `1087_004779_MSLMST_0011/` | Part of Stimson_1087 dataset - the whole dataset can be downloaded here : http://download.vrvis.at/acquisition/32987e2792e0/PRo3D/Stimson_1087.zip |

## How PRo3D consumes this

Mounted as a git submodule at `src/Tests/data/opc`:

```
git submodule update --init --recursive
```

`src/Tests/Features/TestHelpers.fs` resolves the surface as
`<repo>/src/Tests/data/opc/1087_004779_MSLMST_0011`.

The suite does **not** require this data. When the submodule is not checked out,
`Render.available` returns `false` and every OPC-backed test skips with
`no OPC test data at ...` rather than failing. Only clone with `--recurse-submodules`
if you intend to exercise the rendering and scene-lifecycle sections.

