# AstroLink viva preparation — 55 questions and answers

Answers describe the checked-in implementation. Do not describe DCT quantization as RF transmission.

## Project and architecture

1. **What is AstroLink?** A MATLAB project for astronomical image input, digital image processing demonstrations, lossy block-DCT quantization/reconstruction, and scientific display.
2. **What problem does it address?** It demonstrates how image processing and transform quantization affect astronomical arrays and how display stretching reveals faint structure.
3. **What is the current end-to-end pipeline?** FITS science input, validation, 8×8 DCT coefficient rounding, inverse transform/crop, fidelity metrics, then separate grayscale/asinh and pseudocolour outputs.
4. **What is the project's contribution?** An integrated, reproducible demonstration tying the existing FITS loader and DCT operation to metrics and scientifically qualified visualization.
5. **Is it an RF transmission system?** No. The current repository contains no RF hardware, modulation, channel, or bitstream encoder/decoder. It demonstrates transform quantization only.
6. **What are the four units?** Unit 1 input/sampling/intensity and pixel concepts; Unit 2 DCT quantization; Unit 3 reconstruction/filtering/enhancement demonstrations; Unit 4 morphology and scientific/pseudocolour display.
7. **Why retain separate scientific and display arrays?** Stretching clips/remaps display values. Metrics and processing must use meaningful source-unit values, not a visualization copy.
8. **What is the main limitation?** Only two independent astronomical targets are available and the pipeline was not executable in the current environment.

## Dataset

9. **Which data are configured?** Orion HST WFPC2 drizzled SCI extension and M51 HST ACS drizzled science primary array.
10. **What is known about Orion?** Existing inspection report records 1496×1516, COUNTS/S, target NGC1976-HST1, WFPC2, and observation date 1995-03-21.
11. **What is known about M51?** Project notes identify an ACS F435W drizzled image; the loader reads the primary array and treats values as electrons.
12. **Where did Orion data come from?** The checked-in manifest records public MAST URIs under `mast:HST/U2ID010GT/`; the exact retrieval URL and a formal dataset citation should be verified from archive metadata.
13. **Why are there not nine Orion images?** The nine files are products/calibration files from the same visit and target; multiple extensions/chips/products are not nine independent astronomical targets.
14. **Why test ten distinct images?** A broader sample tests whether conclusions generalize beyond two examples; current data do not satisfy that target and no transformations are counted as independent inputs.

## Unit 1 — acquisition and preparation

15. **What is FITS?** Flexible Image Transport System, a scientific format that stores arrays and metadata in HDUs.
16. **What does `load_sci_image` do?** It locates the FITS file relative to project root, reads metadata, then selects the SCI image extension for Orion or primary array for M51.
17. **Why convert to double?** DCT arithmetic and metrics need floating point; `double` preserves numeric values without scaling to [0,1].
18. **Are input values normalized?** No, source units are preserved for processing and metrics. Normalization is only used for PNG preview output.
19. **How are dimensions handled?** The image is padded to the next multiple of eight for block processing, then cropped back to its original height and width.
20. **What happens to nonfinite samples?** The integrated script validates the image, then replaces nonfinite entries with zero before transformation; this policy should be documented for any dataset where such values occur.
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
32. **What is the quantization step measured in?** It is applied directly to DCT coefficient values derived from the input's source units; its scale depends on those units and the DCT normalization.

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
60. **Were results validated by execution?** Not in this session. MATLAB/Octave was unavailable on PATH, so outputs and metrics are marked NOT TESTED.
61. **How would you add an honest RF simulation?** Serialize pixels, define framing and modulation (for example BPSK), add a stated AWGN channel with calibrated Eb/N0, demodulate/decode, compare actual bit vectors for BER, then reconstruct and report channel settings.
62. **How would you reach ten images?** Acquire at least eight more independent, provenance-recorded science images and include them as separate source inputs; do not count derived products or transformed copies.
63. **Why can MSE units be awkward?** Squaring source intensity units gives squared units; compare images only with consistent units and scale.
64. **What if MSE is zero?** PSNR is +Inf; this is the correct limit for exact reconstruction, not a divide-by-zero failure.
65. **What is a limitation of global SSIM?** It collapses spatial structure into global statistics and may miss localized distortions; use a validated local-window implementation for a standard benchmark.
66. **Why include morphology?** It demonstrates binary-mask morphology as an educational Unit 4 topic; it is not part of the integrated transmission pipeline and does not modify the science array.
67. **What would prove the pipeline works?** Run it in a supported MATLAB installation, verify outputs exist and open correctly, inspect table values against independently recomputed samples, then record version/toolbox status and exact input count.
68. **Is the fixed Δ=2 universally optimal?** No. It is an inherited demonstration setting. A rate-distortion study across Δ values and scientifically meaningful error criteria is needed to select an optimal value.
69. **Why preserve the original FITS?** It is the immutable source/reference; derived PNGs and reconstructions are separate outputs.
70. **What source attribution is still needed?** Capture exact MAST product identifiers/download pages and M51 FITS header/provenance so dataset citations are reproducible.
