# AstroLink project audit

## Existing structure and data flow

The four-unit architecture remains intact: Unit 1 handles FITS acquisition, image fundamentals, pixel relationships, and intensity operations; Unit 2 demonstrates block-DCT quantization; Unit 3 contains enhancement and filtering exercises; Unit 4 contains morphology and pseudocolour visualization. `run_demo.m` remains the sequential unit runner. `AstroLink_Final_Integrated.m` is the separate six-target evaluation entry point. The shared `unit1/load_sci_image.m` loader supports all six targets, preserving the Orion SCI-extension path and the existing M51 primary-image path.

## Findings

- Unit 2 is lossy transform compression/quantization. No image bitstream, encoder/decoder, modulator, RF channel, noise injection, or BER implementation was found. It cannot be represented honestly as RF transmission.
- `run_demo.m` is a sequential exercise runner, not the integrated per-image evaluation pipeline.
- Six independent targets are configured. Each is one astronomical object; Orion companion FITS products and its WHT/CTX extensions are not counted as extra targets.
- The existing scientific display design is sound: source-valued arrays remain separate from asinh display copies and pseudocolour is correctly identified as display encoding.
- Unit 4 includes morphology as a mask demonstration; it is not image restoration and should not be inserted into the transmission/reconstruction chain.

## FITS inventory verified in MATLAB R2026b

The selected arrays below were read with `fitsinfo`/`fitsread` after extending the shared loader. “FITS type” is the stored numeric type reported by `fitsinfo`; `fitsread` returned MATLAB `double` for each selected image. Every selected array was 2-D and had zero non-finite samples. Header values are recorded as stored; coded filter values and ambiguous date strings are not silently translated.

| Target / configured ID | FITS file and selected HDU | Size (rows × columns) | FITS type → MATLAB class | Pixel range | Header metadata observed |
|---|---|---:|---|---:|---|
| Orion / `orion` | `u2id010gt_drz.fits`, FITS HDU 2 (first image extension, `EXTNAME=SCI`); primary HDU 1 is empty, HDUs 3–4 are `WHT` and `CTX` | 1496 × 1516 | single → double | 0 to 50.21614456 | HST, WFPC2, target NGC1976-HST1, 1995-03-21, exposure 180 s, `COUNTS/S`, proposal 5469; `FILTER1=32`, `FILTER2=0` |
| M51 / `m51` | `h_m51_b_s20_drz_sci.fits`, primary image | 3050 × 2150 | single → double | −0.02497177 to 111.5490723 | HST, ACS/WFC, target M51-POS6, 2005-01-20, exposure 16320 s, `ELECTRONS`, `FILTER2=F435W`, proposal 10452 |
| Bug Nebula / `bug_nebula` | `656nmos.fits`, primary image; ASCII-table extension also present | 1600 × 1600 | single → double | −29.9519062 to 2053.799316 | HST, WFPC2, target PK349+01D1, 2000-02-21, exposure 203.3333 s, proposal 8345; `FILTER1=31`, `FILTER2=0`; no `BUNIT` keyword observed |
| Eagle Nebula / `eagle_nebula` | `502nmos.fits`, primary image; ASCII-table extension also present | 1600 × 1600 | single → double | −12.43932438 to 2925.871826 | WFPC2, target M16-A, header date string `1/04/95`, exposure 1100 s, proposal 5773; `FILTER1=23`, `FILTER2=0`; no `BUNIT` keyword observed |
| M35 cluster / `m35` | `m35_40min_blue.fits`, primary image only | 2381 × 2376 | int16 → double | −137 to 28451 | `OBJECT=dss28298`, telescope `Palomar 48-in Schm`, header date `1996/01/14`; no instrument, exposure, or `BUNIT` keyword observed |
| Venus / `venus` | `218wmos.fits`, primary image; ASCII-table extension also present | 1600 × 1600 | single → double | −377.9898682 to 13478.60352 | WFPC2, target VENUS, header date string `24/01/95`, exposure 20 s, proposal 5783; `FILTER1=8`, `FILTER2=0`; no `BUNIT` keyword observed |

## Integrated architecture

`AstroLink_Final_Integrated.m` loops through the six configured IDs via the shared loader, validates each 2-D science array, converts the selected FITS data to double without normalization, applies the inherited 8×8 DCT coefficient quantizer with Δ=2, inverse-transforms, and crops to source dimensions. It saves source-unit reconstructions, display-only asinh grayscale/pseudocolour images, comparisons, metrics, and plots. Metrics use the original and reconstructed science arrays, not display images. BER remains NaN because no bitstream or channel exists.

`unit2/evaluate_scale_adaptive_quantization.m` is a reproducible separate experiment; it compares fixed Δ=2 with `Δᵢ = 2 × robustSpanᵢ / median(robustSpan)`, where robust span is p99.7−p1. This experiment does not change the integrated pipeline's default.

## Validation status

The integrated six-image run and separate scale-adaptive experiment both completed in MATLAB R2026b. Six rows were written to `results/integrated/metrics/metrics.csv`; the comparison script wrote `quantization_scale_experiment.csv`. See `Results_Analysis.md` and `Validation_Checklist.md` for measured results and limitations. This six-target result is still a small sample and not a broad astronomical population study.
