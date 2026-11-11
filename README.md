# AstroLink: Astronomical Image Processing

## Project Name

AstroLink — Digital Image Processing of Astronomical Images

## Project Description:

AstroLink is a MATLAB course project demonstrating digital image processing on astronomical FITS science images. It contains unit-wise exercises in image fundamentals, transform-domain quantization, enhancement and filtering, morphology, and visualization, together with an integrated reconstruction and evaluation workflow.

## Summary -

The integrated workflow reads Orion and M51 FITS science arrays, applies 8×8 block discrete cosine transform (DCT) coefficient quantization, reconstructs each image, and compares source and reconstruction using image-domain metrics. Grayscale and pseudocolour products are created separately for display. The DCT stage is a lossy compression demonstration; the project does not implement an RF transmission link or bitstream channel.

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

The current evaluation uses two independent optical science images: an Orion Hubble Space Telescope WFPC2 drizzled science product and an M51 ACS F435W drizzled image. The loader reads Orion's science extension and the M51 primary image. The included Orion archive manifest is at `data/orion/MANIFEST.HTML`. Infrared and X-ray observations are not part of the current configured dataset. Exact retrieval citation details for the included images are incomplete; consult the FITS headers and archive records before formal reuse.

### Link and/or Explanation if generated

The FITS inputs are stored in `data/`; no synthetic images are presented as independent observations. The integrated evaluation currently uses two targets and is planned to expand to at least six independent images. Any added wavelength bands or targets should be accompanied by their source and observation metadata. Orion chips, FITS extensions, and derived views are not independent targets.

## Novelty -

AstroLink separates scientific pixel values from display transformations. It evaluates reconstruction in the original science-value domain, then creates grayscale and pseudocolour views from a separate asinh-stretched display copy. BER is explicitly reported as unavailable because the project has no encoded bitstream or channel.

## Contributors:

- Eshwar Hebsur (PES1UG24EC076)
- Danesh Sullad (PES1UG24EC061)
- Prathamesh Shinde (PES1UG24EC153)

## Steps:

### Clone Repository

```bash
git clone <repo-url>
cd <repository-folder>
```

### Install Dependencies

No Python `requirements.txt` is needed. Open the project in MATLAB. The integrated script requires FITS functions (`fitsinfo`, `fitsread`), `dct2`/`idct2`, and table/graphics support including `tiledlayout` and `exportgraphics`. The recorded run used MATLAB R2026b; individual unit scripts may require additional toolboxes.

### Run the Code

In MATLAB, run:

```matlab
AstroLink_Final_Integrated
```

To run the unit demonstrations in sequence, run `run_demo.m`. Some unit scripts may open figures or request interactive input.

## Outputs:

Generated products are saved under `results/integrated/`:

- Reconstructed science arrays (`reconstructed/*_science_arrays.mat`) and PNG previews
- Grayscale and pseudocolour display images
- Original/reconstruction comparison panels
- Per-image metric tables in CSV/MAT formats and metric graphs

Recorded values and metric interpretation are in `Documentation/Results_Analysis.md`. BER is `NaN` (unavailable), not zero. The reported SNR is the image-energy to reconstruction-residual ratio, not channel SNR.

## References:

1. Gonzalez, R. C., and Woods, R. E., *Digital Image Processing*, 4th ed., Pearson, 2018.
2. Mikulski Archive for Space Telescopes (MAST), https://archive.stsci.edu/ — the included Orion manifest records the local archive product identifiers.
3. NASA/IPAC Extragalactic Database, https://ned.ipac.caltech.edu/ — M51 object context; not evidence of the exact local FITS retrieval.

## Limitations and Future Work:

- Only two independent science-image targets are currently configured. The planned next step is to expand the evaluation to at least six independent targets.
- No bitstream, modem, RF channel, or decoder is implemented, so BER and channel SNR cannot be measured.
- SSIM is the global form implemented by this project, not a local-window SSIM calculation.
- The coefficient quantization step is fixed at 2 in source-intensity units and is not entropy-coded.
- Record exact archive citations and add more independent, provenance-tracked images for broader evaluation.
- Implement an explicit bitstream and channel model before reporting communication metrics.
