# comet-toolbox reference frames: HERA AFC-1

Screenshots of the HERA dashboard of **comet-toolbox** (<https://comet-toolbox.com/dashboard/hera/>),
showing the AFC-1 view at eight epochs. They are the comet-toolbox authors' work, included here
only as reference frames for comparing PRo3D's renders. Please credit comet-toolbox
when you use them.

- Taken on 2026-11-06, with the SPICE kernels the dashboard showed: HERA Planning
  `v182_20261020_001` (metakernel `mk/former_versions/hera_plan_v182_20261020_001.tm` on
  the ESA SPICE server).
- 392 × 392 px, the full 5.5° AFC-1 field, with no zoom or pan.
- File names are the UTC epoch: `YYYYMMDDTHHMM.png`.

| Epoch (UTC) | HERA–Dimorphos distance | Phase | In the frame |
|---|---|---|---|
| 2027-02-18 11:00 | 5.7 km | 12° | Dimorphos |
| 2027-02-18 13:30 | 4.8 km | 34° | Dimorphos |
| 2027-02-25 10:30 | 5.6 km | 36° | Dimorphos |
| 2027-02-25 14:45 | 5.8 km | 57° | Dimorphos |
| 2027-03-11 01:00 | 9.9 km | 71° | Dimorphos |
| 2027-03-21 12:30 | 7.4 km | 0° | Dimorphos |
| 2027-03-24 03:00 | 24.4 km | 91° | Didymos in the centre, Dimorphos in the top-left corner |
| 2027-03-25 03:00 | 9.0 km | 79° | Dimorphos |

At all epochs except 03-24, AFC-1 points at Dimorphos, and Didymos neither occults nor
eclipses it.

## Use

- [`scripts/compare-render-view-toolbox.py`](https://github.com/pro3d-space/PRo3D/blob/9a5db533c5f155ac8b6c3fbbd9625466e5a98641/scripts/compare-render-view-toolbox.py)
  renders each epoch with `pro3d-tool render-view`, once per pointing, and compares the
  result with these frames.
- [`scripts/render-view-job.py`](https://github.com/pro3d-space/PRo3D/blob/9a5db533c5f155ac8b6c3fbbd9625466e5a98641/scripts/render-view-job.py)
  computes the camera from SPICE: the job generator, documented in
  [Pro3DTool-RenderView.md → The SPICE job generator](https://github.com/pro3d-space/PRo3D/blob/9a5db533c5f155ac8b6c3fbbd9625466e5a98641/docs/Pro3DTool-RenderView.md#the-spice-job-generator).

No automated test reads these files.
