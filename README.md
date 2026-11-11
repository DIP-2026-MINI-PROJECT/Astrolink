# AstroLink: Astronomical Image Processing

## Project Name

AstroLink — Digital Image Processing of Astronomical Images

## Project Description:

AstroLink is a MATLAB course project demonstrating digital image processing on astronomical FITS science images. It contains unit-wise exercises in image fundamentals, transform-domain quantization, enhancement and filtering, morphology, and visualization, together with an integrated reconstruction and evaluation workflow.

## Summary -

The integrated workflow reads six astronomical FITS science arrays, applies 8×8 block discrete cosine transform (DCT) coefficient quantization at Δ=2, reconstructs each image, and compares source and reconstruction using image-domain metrics. Grayscale and pseudocolour products are created separately for display. The DCT stage is a lossy compression demonstration; the project does not implement an RF transmission link or bitstream channel.

## Course concepts used -

1. Image sampling and quantization
2. Pixel neighborhoods, adjacency, and connectivity
3. Linear and nonlinear intensity operations
4. 2-D DCT and scalar coefficient quantization
5. Image enhancement and filtering
6. Morphological processing
7. Image visualization and pseudocolour mapping
8. Reconstruction measures: MSE, PSNR, global SSIM, and residual SNR

## Additional concepts used -

1. FITS science-image loading and metadata inspection
2. Percentile limits and asinh display stretch
3. Separation of source-unit arrays from display-only images
4. Automated export of figures, metric tables, and reconstructed arrays

## Dataset -

The inputs are astronomical observations stored as FITS (Flexible Image Transport System) files. FITS preserves numeric pixel arrays and observation metadata, unlike an ordinary RGB photograph. Each input is processed as a two-dimensional intensity image; pixel values are kept in the science array's original scale for reconstruction metrics. Astronomical images have varying brightness and contrast, so faint structures may appear alongside much brighter sources.

The integrated set contains six distinct targets: Orion, M51, Bug Nebula, Eagle Nebula, M35 cluster, and Venus. The inputs are FITS scientific arrays rather than ordinary RGB photographs. Orion is read from its `SCI` image extension; the other five selected images are read from their primary HDUs. FITS stored types are single precision except M35 (`int16`); MATLAB reads the selected arrays as double for processing without scaling source values to `[0,1]`. Three of the new files also contain ASCII-table extensions, which are not used as images. See [`Documentation/Project_Audit.md`](Documentation/Project_Audit.md) for the measured HDUs, dimensions, ranges, and available header metadata. The Orion archive manifest is at `data/orion/MANIFEST.HTML`; exact retrieval citation details remain incomplete for some inputs.

### Link and/or Explanation if generated

The FITS inputs are stored in `data/`; no synthetic images are presented as independent observations. The integrated evaluation currently processes six independent astronomical targets. Orion chips, FITS extensions, and derived views are not counted as additional targets. Source and observation metadata should be recorded for any future additions.

## Novelty -

AstroLink separates scientific pixel values from display transformations. It evaluates reconstruction in the original science-value domain, then creates grayscale and pseudocolour views from a separate asinh-stretched display copy. BER is explicitly reported as unavailable because the project has no encoded bitstream or channel.

## Contributors:

- Eshwar Hebsur (PES1UG24EC076)
- Danesh Sullad (PES1UG24EC061)
- Prathamesh Shinde (PES1UG24EC153)

## Steps:

### Clone Repository

```bash
git clone https://github.com/DIP-2026-MINI-PROJECT/Astrolink.git
cd Astrolink
```

### Install Dependencies

No Python `requirements.txt` is needed. Open the project in MATLAB. The integrated script requires FITS functions (`fitsinfo`, `fitsread`), `dct2`/`idct2`, and table/graphics support including `tiledlayout` and `exportgraphics`. The recorded run used MATLAB R2026b; individual unit scripts may require additional toolboxes.

### Run the Code

In MATLAB, run:

```matlab
AstroLink_Final_Integrated
```

Run `run_demo.m` to execute the six-target integrated pipeline and open the combined results viewer. To run the individual course demonstrations in sequence, run `run_unit_demos.m`; some unit scripts may open figures or request interactive input.

## Outputs:

Generated products are saved under `results/integrated/`:

- Reconstructed science arrays (`results/integrated/reconstructed/*_science_arrays.mat`) and PNG previews
- Grayscale and pseudocolour display images
- Original/reconstruction comparison panels
- Per-image metric tables in CSV/MAT formats and metric graphs

Recorded six-image values and metric interpretation are in [`Documentation/Results_Analysis.md`](Documentation/Results_Analysis.md). The optional scale experiment in `unit2/evaluate_scale_adaptive_quantization.m` compares Δ=2 with a robust-span-relative step; it does not change the integrated default. BER is `NaN` (unavailable), not zero. The reported SNR is the image-energy to reconstruction-residual ratio, not channel SNR.

## References:

1. Gonzalez, R. C., and Woods, R. E., *Digital Image Processing*, 4th ed., Pearson, 2018.
2. Mikulski Archive for Space Telescopes (MAST), https://archive.stsci.edu/ — the included Orion manifest records the local archive product identifiers.
3. NASA/IPAC Extragalactic Database, https://ned.ipac.caltech.edu/ — M51 object context; not evidence of the exact local FITS retrieval.

## Limitations and Future Work:

- The six-image set is a small and heterogeneous sample; it is not a broad survey of astronomical data.
- No bitstream, modem, RF channel, or decoder is implemented, so BER and channel SNR cannot be measured.
- SSIM is the global form implemented by this project, not a local-window SSIM calculation.
- The integrated coefficient quantization step is fixed at 2 in source-intensity units and is not entropy-coded. The scale-relative comparison is experimental, not a validated optimum.
- Record exact archive citations and add more independent, provenance-tracked images for broader evaluation.
- Implement an explicit bitstream and channel model before reporting communication metrics.
