# AstroLink project audit

## Existing structure and data flow

The repository has MATLAB code in `unit1` through `unit4`, FITS data under `data`, demonstrations and historical outputs under `results`, and `run_demo.m` as the original orchestrator. Unit 1 loads/inspects FITS science arrays and demonstrates sampling, quantization, pixel relationships, and display preparation. Unit 2 applies 8×8 block discrete cosine transform (DCT) coefficient quantization and inverse DCT. Unit 3 demonstrates astronomical display enhancement and filtering. Unit 4 demonstrates threshold-derived morphology and pseudocolour. Existing outputs show the units run separately; the former demo script runs these scripts sequentially.

## Findings

- Unit 2 is lossy transform compression/quantization. No image bitstream, encoder/decoder, modulator, RF channel, noise injection, or BER implementation was found. It cannot be represented honestly as RF transmission.
- `run_demo.m` is a sequential exercise runner, not a single input-to-output evaluation pipeline. It clears/closes state in constituent scripts and produces no common per-image metrics table.
- Two science-image sources are exposed by `load_sci_image`: Orion WFPC2 drizzled SCI extension and M51 ACS drizzled primary array. Nine Orion FITS files are products of one visit/target, not nine independent targets. Ten distinct images are unavailable.
- The existing scientific display design is sound: source-valued arrays remain separate from asinh display copies and pseudocolour is correctly identified as display encoding.
- Unit 4 includes morphology as a mask demonstration; it is not image restoration and should not be inserted into the transmission/reconstruction chain.
- Existing FITS inspection report documents Orion SCI as 1496×1516, COUNTS/S, HST WFPC2, target NGC1976-HST1, proposal 5469, observed 1995-03-21. Existing project notes identify M51 as ACS F435W drizzled, in electrons. Exact M51 dimensions are not stated here because this audit did not re-run MATLAB.

## Integrated architecture added

`AstroLink_Final_Integrated.m` resolves root relative to its own location, runs the two available datasets through input validation, 8×8 DCT scalar quantization (step 2 in source units), inverse transform/crop, and display-only asinh grayscale/pseudocolour. It saves source-unit reconstructed arrays as MAT files, PNG previews/comparisons, metrics in CSV/MAT/Excel, plus metric graphs. MSE, PSNR, global SSIM, and residual image SNR are computed from original and reconstructed science arrays. BER is explicitly unavailable (NaN) because there is no bit channel.

## Validation status

Executed under MATLAB R2026b. Both configured inputs completed; MSE/PSNR/global SSIM/residual SNR were calculated and outputs exported. See `Results_Analysis.md` and `Validation_Checklist.md`. Dataset limit remains 2 distinct inputs, 8 short of the ten-image target.
