# View plan footprint — fixture for [#733](https://github.com/pro3d-space/PRo3D/issues/733)

`footprint.pro3d` is an MSL Mastcam OPC surface (`1087_004779_MSLMST_0011`, the fixture in
the parent directory) with an ExoMars rover placed on it, `MastcamZR` selected and the
footprint switched on. The camera opens looking at the terrain.

**What to look for:** a red outline on the surface, marking the edge of the instrument
image. In a build without the fix there is none — the rover, the instrument selector and
the instrument view all work, and only the outline is missing, which is exactly what the
issue reports.

The instrument is tilted 90° down. That is not decoration: the patch is only **2 m across**,
and with the axes at rest the camera looks at the horizon, where the image edges — the only
part `Shader.footPrintF` paints — miss the terrain altogether and a correct build would look
just as empty as a broken one. At this tilt 34 of 372 sampled terrain points fall on the
boundary band, so there is something to see either way.

## Setup

Scenes record **absolute** surface paths (`relativePaths` only redirects `opcPaths`;
`Surface.Sg.createSgSurfaces` still drops any surface whose `importPath` does not exist), so
the committed file points at the machine that produced it. On any other checkout, rewrite it
in one line from the PRo3D repo:

```
dotnet run --project src/Tests -- --make-footprint-scene
```

That rebuilds this scene against the local `src/Tests/resources` checkout — same surface,
same rover, same instrument, same tilt. It needs the submodule and a GL context.

## Regenerating

The generator is `src/Tests/Features/FootprintSceneFixture.fs` in PRo3D. It drives the same
`ViewerAction`s the UI raises — import, place rover, select instrument, toggle footprint,
save — then reopens the result to confirm the view plan survives its codec. Rover,
instrument and tilt are chosen by score rather than by hash-map order, so re-running it
reproduces this scene rather than an arbitrary one.
