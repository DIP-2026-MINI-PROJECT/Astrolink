# AstroLink: theory and implementation

## Abstract and problem

AstroLink studies how digital image operations affect astronomical science arrays and how intensity data can be presented for inspection. The repository's actual transmission-related operation is lossy block DCT quantization, not an RF modem. The integrated demonstration compares each input FITS science array with its DCT-quantized reconstruction and keeps visualization transformations separate.

## Motivation and objectives

Astronomical scenes have large dynamic ranges; faint structures can be hidden beside bright sources. Compression also introduces measurable reconstruction error. The objectives are to load real-valued science data, demonstrate sampling/quantization and transform quantization, reconstruct, quantify error, and render an interpretable grayscale and pseudocolour view without implying that display processing restores information.

## System and pipeline

FITS SCI/primary input → double precision and finite-value check → zero padding at bottom/right to a multiple of 8 → 8×8 DCT → scalar coefficient quantization `Q = Δ round(C/Δ)`, Δ=2 → inverse DCT → crop → metrics on original units → percentile-limited asinh display → grayscale and false-colour rendering. Source array and reconstruction remain numeric science products; display arrays are separate.

## Units

**Unit 1:** FITS acquisition via `load_sci_image`, metadata inspection, and educational sampling, quantization, pixel-neighborhood and intensity-operation demonstrations. The integrated script uses the SCI plane and preserves its source scale. Non-finite values are rejected as a group condition and then zero-filled if encountered; current known data report finite arrays.

**Unit 2:** Orthonormal block DCT concentrates smooth-region energy into fewer low-frequency coefficients. Uniform scalar quantization rounds each coefficient to the nearest multiple of Δ. Increasing Δ generally increases distortion; decreasing Δ reduces coefficient error but increases representation precision. Padding permits complete blocks and is cropped away after reconstruction. This is a compression proxy, not an RF link.

**Unit 3:** Inverse DCT reconstructs each quantized block. The added pipeline does not apply denoising to the metric reference because that would confound transmission/compression fidelity. Separate existing Unit 3 scripts explore filtering and display enhancement.

**Unit 4:** The integrated output uses an asinh stretch because it expands low-valued structure while compressing the bright tail. Limits are the original image's 1st and 99.7th percentiles, shared for original/reconstruction, and the softening fraction is 0.02. A grayscale map supports intensity reading; the existing project false-colour map provides a second encoding of the same scalar field. Pseudocolour is not true RGB and neither stretch nor map recovers lost samples. Linear scaling is the underlying normalization; log stretches are possible but require careful treatment of nonpositive values. Histogram equalization/CLAHE were not selected for the final scientific display because their spatial/intensity remapping can obscure consistent cross-image interpretation.

## Metrics

For N pixels, `MSE = mean((I-R)^2)`. `PSNR = 10 log10(L²/MSE)` where L is the input's observed max-minus-min range (zero MSE gives +Inf). SSIM summarizes luminance, contrast and covariance; the integrated file uses the documented **global** form, not MATLAB's local-window `ssim` implementation. SNR is `10 log10(sum(I²)/sum((I-R)²))`, an image-domain signal-to-residual ratio, not channel SNR. BER is undefined because no bits are transmitted. Never interpret a NaN BER as zero errors.

## Dataset provenance and limits

The project includes an MAST manifest for public Hubble Space Telescope Orion products, path `data/orion/MAST_2026-10-09T0632/HST`, and one M51 drizzled FITS science image. Orion SCI details are recorded in `results/fits_inspection_report.txt`: WFPC2, target NGC1976-HST1, 1496×1516, COUNTS/S, observed 1995-03-21. Project source notes identify M51 as ACS F435W drizzled primary image. The exact original MAST retrieval URL/DOI and M51 header details are not preserved in the checked-in metadata inspected here; obtain these before claiming a full citation. Two independent image inputs are available, not ten. Multiple calibrations, chips, extensions, and derived products must not be counted as different targets.

## Limitations and future work

No RF hardware or simulated RF channel exists in the current code. DCT quantization is not entropy-coded and the fixed step is in source intensity units. Global SSIM is less spatially sensitive than standard local-window SSIM. The integrated script ran successfully in MATLAB R2026b on the two configured targets; see `Results_Analysis.md`. Obtain at least ten independent, provenance-recorded targets; add an explicit bitstream and declared modulation/channel/decoder before reporting BER or channel SNR.

## References

- Hubble Legacy Archive / Mikulski Archive for Space Telescopes (MAST), public archive: https://archive.stsci.edu/ (project's local Orion manifest records `mast:HST/U2ID010GT/...`).
- Gonzalez, R. C., and Woods, R. E., *Digital Image Processing*, 4th ed., Pearson, 2018 (sampling, quantization, DCT and image metrics).
- NASA/IPAC Extragalactic Database, M51 object information: https://ned.ipac.caltech.edu/ (object context; not evidence of the exact local FITS retrieval).
