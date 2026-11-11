# AstroLink viva preparation — 77 questions and answers

Answers describe the checked-in implementation. Do not describe DCT quantization as RF transmission.

## Project and architecture

1. **What is AstroLink?** A MATLAB project for astronomical image input, digital image processing demonstrations, lossy block-DCT quantization/reconstruction, and scientific display.
2. **What problem does it address?** It demonstrates how image processing and transform quantization affect astronomical arrays and how display stretching reveals faint structure.
3. **What is the current end-to-end pipeline?** Six FITS target images are loaded through the shared loader, validated, padded independently, processed with 8×8 DCT coefficient rounding at Δ=2, inverse-transformed and cropped, measured on source arrays, then rendered through separate asinh grayscale/pseudocolour display paths.
4. **What is the project's contribution?** An integrated, reproducible demonstration tying the existing FITS loader and DCT operation to metrics and scientifically qualified visualization.
5. **Is it an RF transmission system?** No. The current repository contains no RF hardware, modulation, channel, or bitstream encoder/decoder. It demonstrates transform quantization only.
6. **What are the four units?** Unit 1 FITS input, sampling, intensity, and pixel concepts; Unit 2 DCT quantization; Unit 3 enhancement and filtering; Unit 4 morphology and pseudocolour visualization. The integrated script ties the units together without replacing `run_demo.m`.
7. **Why retain separate scientific and display arrays?** Stretching clips/remaps display values. Metrics and processing must use meaningful source-unit values, not a visualization copy.
8. **What is the main limitation?** The integrated pipeline now runs six independent targets, but this remains a small, heterogeneous sample with differing or absent physical-unit metadata. Fixed Δ=2 also creates unequal relative distortion across their raw scales.

## Dataset

9. **Which data are configured?** Orion, M51, Bug Nebula, Eagle Nebula, M35 cluster, and Venus; each is one distinct astronomical target with one selected science image.
10. **What is known about Orion?** Its FITS primary HDU is empty. FITS HDU 2 is the SCI image (1496×1516, stored single, `COUNTS/S`); the header identifies HST WFPC2, target NGC1976-HST1, and date 1995-03-21.
11. **What is known about M51?** The loader reads the 3050×2150 primary image, stored single. The header identifies HST ACS/WFC, target M51-POS6, filter F435W, and `BUNIT=ELECTRONS`.
12. **Where did Orion data come from?** The checked-in manifest records public MAST URIs under `mast:HST/U2ID010GT/`; the exact retrieval URL and a formal dataset citation should be verified from archive metadata.
13. **Why are there not nine Orion images?** The nine files are products/calibration files from the same visit and target; multiple extensions/chips/products are not nine independent astronomical targets.
14. **How many independent targets are currently used?** Six: Orion, M51, Bug Nebula, Eagle Nebula, M35 cluster, and Venus. This satisfies the current six-image implementation target, but it is still too small for broad population-level conclusions.

## Unit 1 — acquisition and preparation

15. **What is FITS?** Flexible Image Transport System, a scientific format that stores arrays and metadata in HDUs.
16. **What does `load_sci_image` do?** It maps a configured target ID to its FITS path, checks the file with `fitsinfo`, loads a 2-D primary image when present, and otherwise selects the named Orion SCI extension. It avoids loading Orion's WHT/CTX images or ASCII-table HDUs as science data.
17. **Why convert to double?** MATLAB `fitsread` returns the selected single-precision or int16 FITS arrays as double in this run. The integrated script explicitly uses double for DCT and metrics, avoiding integer arithmetic and retaining adequate numeric precision without rescaling the measurement values.
18. **Are input values normalized?** No science-array normalization is applied before metrics or the integrated DCT. The asinh display makes a separate normalized copy; the scale experiment uses the robust span only to set a test quantization step.
19. **How are dimensions handled?** The image is padded to the next multiple of eight for block processing, then cropped back to its original height and width.
20. **What happens to nonfinite samples?** The script validates that at least one finite pixel exists and replaces any nonfinite pixels with zero before transformation. All six inspected inputs were finite, so no pixels were replaced in the recorded run.
21. **What is sampling?** Sampling represents a continuous/spatial field at discrete pixel locations. The Unit 1 script demonstrates effects of spatial sampling.
22. **What is quantization?** Mapping continuous-valued measurements or transform coefficients to a finite set of representable levels; it introduces error.

## Unit 2 — actual transform operation

23. **What is DCT?** Discrete Cosine Transform; a real-valued frequency transform that often concentrates image energy in low-frequency coefficients.
24. **Why 8×8 blocks?** It is a conventional manageable local transform block size; smaller blocks localize artifacts but reduce compaction, while larger blocks can increase boundary artifacts and computation.
25. **What is the quantizer equation?** `Cq = Δ round(C/Δ)` with Δ=2 in this script.
26. **What does increasing Δ do?** Coefficients are rounded more coarsely, generally increasing reconstruction distortion while reducing precision requirements.
27. **What is the inverse DCT for?** It maps quantized block coefficients back into pixel-domain reconstructed blocks.
28. **Why zero-pad?** It ensures full 8×8 blocks at image boundaries. Cropping removes padding from the delivered reconstruction.
29. **Is this a complete image codec?** No. It omits coefficient scanning, entropy coding, headers, bitstream framing and rate control.
30. **Is it a simulated RF channel?** No. There is no channel model or noise. Calling it RF would be inaccurate.
31. **Can BER be calculated?** Not meaningfully without a transmitted and received bit sequence; the integrated output records NaN (unavailable), not zero.
32. **What is the quantization step measured in?** The integrated Δ=2 is applied directly to DCT coefficients derived from each input's unnormalized source values. Because source ranges differ greatly and several inputs lack `BUNIT`, the same absolute Δ does not impose equal relative distortion.

## Unit 3 — reconstruction and processing

33. **How is the image reconstructed?** Each block's quantized DCT coefficients are passed through inverse DCT, assembled, and cropped.
34. **Does Unit 3 improve transmission fidelity?** The existing scripts explore filtering/enhancement, but display enhancement is not proof of restored information. The integrated metrics use the direct reconstructed array.
35. **Why not filter before calculating metrics?** That would confound the isolated effect of coefficient quantization with a second operation.
36. **What errors can arise?** Quantization error, block boundary artifacts, padding/cropping mistakes, FITS HDU selection errors, and invalid/nonfinite values.
37. **How is shape compatibility maintained?** The reconstruction is cropped to exactly the original dimensions before elementwise comparison.

## Unit 4 — scientific display

38. **What is intensity stretching?** A monotonic remapping of scalar intensity to display range to make selected values easier to see; it does not add information.
39. **What is asinh?** Inverse hyperbolic sine, `asinh(z/a)/asinh(1/a)` here after robust normalization z∈[0,1].
40. **Why asinh for astronomy?** It expands faint values near zero while compressing bright values more gently than a logarithm, useful for wide dynamic range.
41. **What do the 1st and 99.7th percentiles do?** They set robust display limits; values outside them clip in the display copy, not the source array.
42. **What does softening fraction 0.02 control?** The transition scale in asinh; a smaller value makes the mapping more log-like, a larger value more linear.
43. **Why use a shared stretch for original and reconstructed images?** It makes the side-by-side views comparable; limits are computed from the original.
44. **What is pseudocolour?** Assigning palette colors to one grayscale intensity plane to aid visual separation of levels.
45. **Is pseudocolour true astronomical RGB?** No. It is a palette applied to one scalar image and does not represent physical color channels.
46. **Why grayscale too?** It provides a direct luminance-oriented view and a familiar scientific intensity display.
47. **Why not histogram equalization or CLAHE in the integrated view?** They were not necessary for this display objective and can make intensity relationships less directly comparable; they remain possible alternatives, not claimed as implemented in this integrated pipeline.
48. **Does display stretching improve PSNR?** No. It is performed after metrics on separate display arrays and cannot restore transmitted or quantized information.

## Metrics

49. **What is MSE?** Mean squared pixel error, `mean((I-R)^2)`; lower is closer in squared source units.
50. **What is PSNR?** `10 log10(L²/MSE)`, where L is the observed input range here; higher usually means less error. Exact reconstruction yields +Inf.
51. **Why might PSNR be undefined or misleading?** A zero/degenerate range or different scaling/reference can invalidate interpretation; report the reference range and units.
52. **What is SSIM?** Structural Similarity Index compares luminance, contrast and covariance. This script uses a global-statistics variant, not MATLAB's local-window default.
53. **Why can SSIM remain high with pixel differences?** It emphasizes structure and can tolerate some local intensity changes; it is not a pixelwise error measure.
54. **What is SNR here?** Image-domain ratio `10log10(sum(I²)/sum((I-R)²))`; it is called residual SNR and must not be confused with RF channel SNR.
55. **What does BER=0 mean?** It means no bit errors only when actual transmitted/recovered bit vectors were compared. AstroLink currently has no such vectors, so BER is unavailable, not zero.

## MATLAB and evaluator challenges

56. **Why use `fitsread`?** It reads FITS arrays; Orion requires selecting the SCI image HDU while M51's science array is primary.
57. **Why use `dct2`/`idct2`?** They provide two-dimensional transform/inverse for spatial blocks; verify the Image Processing Toolbox requirement on the execution machine.
58. **Why save CSV, MAT, and Excel?** CSV is portable, MAT retains MATLAB table types, Excel is convenient if a writer is available; Excel export is guarded.
59. **What does a NaN BER in the metrics table mean?** Not applicable/unavailable because the current code has no bit channel; it must not be interpreted as measured zero BER.
60. **Were results validated by execution?** Yes. MATLAB R2026b ran the integrated pipeline on all six targets and generated six metric rows and output files. A separate scale-step experiment also completed; see `Results_Analysis.md`.
61. **How would you add an honest RF simulation?** Serialize pixels, define framing and modulation (for example BPSK), add a stated AWGN channel with calibrated Eb/N0, demodulate/decode, compare actual bit vectors for BER, then reconstruct and report channel settings.
62. **How would you improve dataset coverage?** Add more independently sourced astronomical targets with provenance; do not count derived products, extensions, chips, or repeated bands of the same object as new objects when independent targets are required.
63. **Why can MSE units be awkward?** Squaring source intensity units gives squared units; compare images only with consistent units and scale.
64. **What if MSE is zero?** PSNR is +Inf; this is the correct limit for exact reconstruction, not a divide-by-zero failure.
65. **What is a limitation of global SSIM?** It collapses spatial structure into global statistics and may miss localized distortions; use a validated local-window implementation for a standard benchmark.
66. **Why include morphology?** It demonstrates binary-mask morphology as an educational Unit 4 topic; it is not part of the integrated transmission pipeline and does not modify the science array.
67. **What evidence supports the current run?** The MATLAB R2026b run printed six per-image metric rows, wrote metrics CSV/MAT and summary files, generated plots and image outputs, and completed without a runtime error. See the validation checklist for what was not re-run.
68. **Is the fixed Δ=2 universally optimal?** No. The scale experiment shows it yields robust-normalized RMSE from 0.0000321 to 0.08594 across the six raw scales. A tested scale-relative rule narrows that range, but increases distortion for some images and is not yet adopted as the production default.
69. **Why preserve the original FITS?** It is the immutable source/reference; derived PNGs and reconstructions are separate outputs.
70. **What source attribution is still needed?** Verify and record exact archive/download provenance for all six FITS files. Several new headers lack BUNIT, and M35 lacks instrument/exposure keywords.

## Six-image extension and scale investigation

71. **What is an HDU in FITS?** A Header/Data Unit is one FITS component with its own header and optional data. Orion's file has an empty primary HDU, then SCI, WHT, and CTX image extensions. The loader selects SCI. Other selected files store the science image in the primary HDU; some also include an ASCII table extension.
72. **What are the stored data types?** `fitsinfo` reports `single` storage for Orion, M51, Bug, Eagle, and Venus, and `int16` for M35. `fitsread` returned MATLAB `double` for the selected arrays in the inspected environment.
73. **Why do the intensity ranges matter for Δ=2?** The p1–p99.7 span runs from about 0.884 for M51 to 18,142 for M35. A fixed two-unit coefficient step is large relative to M51 but negligible relative to M35, so raw MSE and relative distortion differ in meaning.
74. **What is the tested alternative normalization?** The separate experiment uses `Δᵢ = 2 × robustSpanᵢ / median(robustSpan)`, with robust span p99.7−p1. It does not normalize the source arrays or replace the integrated Δ=2 setting.
75. **What did the scale experiment show?** Relative RMSE to robust span fell from a fixed-step spread of about 0.0000321–0.08594 to about 0.000866–0.004666 for the adaptive candidate. The alternative improves relative comparability but gives higher distortion on Bug, M35, and Venus.
76. **How does batch processing handle different image sizes?** It loops through target IDs independently, pads each source at the bottom/right to multiples of eight, processes blocks, then crops the reconstruction to the exact original height and width before metrics.
77. **How were six independent samples counted?** The six IDs map to six object targets. Orion's SCI/WHT/CTX planes and its other calibration files are not counted separately; each target contributes one selected science image.
