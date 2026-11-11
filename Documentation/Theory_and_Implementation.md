# AstroLink: theory and implementation

## Abstract and problem

AstroLink studies how digital image operations affect astronomical science arrays and how intensity data can be presented for inspection. The repository's actual transmission-related operation is lossy block DCT quantization, not an RF modem. The integrated demonstration compares each input FITS science array with its DCT-quantized reconstruction and keeps visualization transformations separate.

## Motivation and objectives

Astronomical scenes have large dynamic ranges; faint structures can be hidden beside bright sources. Compression also introduces measurable reconstruction error. The objectives are to load real-valued science data, demonstrate sampling/quantization and transform quantization, reconstruct, quantify error, and render an interpretable grayscale and pseudocolour view without implying that display processing restores information.

## System and pipeline

One of six FITS science inputs → select the intended image HDU → `fitsread` and convert to double → finite-value check → zero padding at bottom/right to a multiple of 8 → 8×8 DCT → scalar coefficient quantization `Q = Δ round(C/Δ)`, production Δ=2 → inverse DCT → crop → metrics on original science values → percentile-limited asinh display → grayscale and false-colour rendering. Source array and reconstruction remain numeric science products; display arrays are separate. The six inputs are processed in a batch loop, but each image is padded and measured independently.

## Units

**Unit 1:** FITS acquisition via the shared `load_sci_image(datasetName)` loader, metadata inspection, and educational sampling, quantization, pixel-neighborhood and intensity-operation demonstrations. Orion's primary HDU is empty; its SCI image is the first image extension (FITS HDU 2). The loader selects that SCI plane rather than WHT or CTX. M51, Bug Nebula, Eagle Nebula, M35, and Venus use primary image HDUs; three of those files also contain ASCII-table extensions that are not image inputs. The six selected arrays range from 1496×1516 to 3050×2150. FITS storage types are `single` except M35 (`int16`); MATLAB `fitsread` returns double arrays, and the integrated script explicitly keeps calculations in double precision without scaling science values to [0,1]. All six inspected arrays were finite. The implementation still replaces any non-finite samples with zero before DCT if such values occur in a future input.

**Unit 2:** Orthonormal block DCT concentrates smooth-region energy into fewer low-frequency coefficients. Uniform scalar quantization rounds each coefficient to the nearest multiple of Δ. The integrated baseline keeps Δ=2 in each image's unnormalized source scale. Since the six robust p1–p99.7 spans range from 0.88398 (M51) to 18142 (M35), this same absolute step does not create a comparable relative quantization level. `unit2/evaluate_scale_adaptive_quantization.m` experimentally compares Δ=2 to `Δᵢ = 2 × robustSpanᵢ / median(robustSpan)`, anchoring the median-scale input at 2. That candidate greatly narrows relative RMSE variation but increases distortion on some targets; it remains a documented experiment and is not the integrated default. Padding permits complete blocks and is cropped away after reconstruction. DCT coefficient quantization is a compression proxy, not RF transmission.

**Unit 3:** Inverse DCT reconstructs each quantized block. The pipeline does not apply denoising to the metric reference because that would confound quantization fidelity. Existing Unit 3 scripts separately explore filtering and display enhancement. Metrics are calculated before any display-only stretch or pseudocolour mapping.

**Unit 4:** The integrated output uses an asinh stretch because it expands low-valued structure while compressing the bright tail. Limits are the original image's 1st and 99.7th percentiles, shared for original/reconstruction, and the softening fraction is 0.02. A grayscale map supports intensity reading; the existing project false-colour map provides a second encoding of the same scalar field. Pseudocolour is not true RGB and neither stretch nor map recovers lost samples. Linear scaling is the underlying normalization; log stretches are possible but require careful treatment of nonpositive values. Histogram equalization/CLAHE were not selected for the final scientific display because their spatial/intensity remapping can obscure consistent cross-image interpretation.

## Metrics

For N pixels, `MSE = mean((I-R)^2)`. `PSNR = 10 log10(L²/MSE)` where L is the input's observed full max-minus-min range (zero MSE gives +Inf). MSE retains squared source units; M51 uses electrons, Orion COUNTS/S, and the other inputs have absent `BUNIT` keywords in the inspected headers. PSNR and residual SNR can therefore hide differences in physical units and backgrounds. SSIM summarizes luminance, contrast and covariance; the integrated file uses the documented **global** form, not MATLAB's standard local-window `ssim`. SNR is `10 log10(sum(I²)/sum((I-R)²))`, an image-domain signal-to-residual ratio, not channel SNR. BER is undefined because no bits are transmitted. Never interpret a NaN BER as zero errors.

## Dataset provenance and limits

The integrated dataset now contains six distinct targets: Orion, M51, Bug Nebula, Eagle Nebula, M35 cluster, and Venus. Full selected-HDU, storage-type, dimensions, ranges, and available header metadata are recorded in `Project_Audit.md`. Orion's MAST manifest is in `data/orion/MANIFEST.HTML`; exact retrieval citation details for included data should still be checked against the originating archive. The four new files include primary images and, for three files, accompanying ASCII tables. One image per target is selected. Different Orion chips, extensions, calibrations, or derived products are not additional targets.

## Limitations and future work

No RF hardware or simulated RF channel exists in the current code. DCT quantization is not entropy-coded and the baseline fixed step is in source intensity units. The scale-relative experiment is one candidate for cross-scale comparison, not an established optimum. The six-target integrated script and the scale experiment were executed in MATLAB R2026b; see `Results_Analysis.md`. Six images are now configured, but the sample remains small and heterogeneous; acquire additional provenance-recorded targets for broader conclusions. Add an explicit bitstream and declared modulation/channel/decoder before reporting BER or channel SNR.

## References

- Hubble Legacy Archive / Mikulski Archive for Space Telescopes (MAST), public archive: https://archive.stsci.edu/ (project's local Orion manifest records `mast:HST/U2ID010GT/...`).
- Gonzalez, R. C., and Woods, R. E., *Digital Image Processing*, 4th ed., Pearson, 2018 (sampling, quantization, DCT and image metrics).
- NASA/IPAC Extragalactic Database, M51 object information: https://ned.ipac.caltech.edu/ (object context; not evidence of the exact local FITS retrieval).
