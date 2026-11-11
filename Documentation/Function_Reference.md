# Function reference for the integrated pipeline and scale experiment

This reference covers the six-image integrated run, the shared Unit 1 FITS loader, and the optional scale-adaptive DCT comparison script.

| Function | Purpose, inputs/outputs, theory and parameter notes |
|---|---|
| `mfilename('fullpath')` | MATLAB built-in; current script path, used to resolve project root. |
| `fileparts`, `fullfile` | Path decomposition and platform-correct path construction. Relative paths avoid machine-specific roots. |
| `addpath` | Adds `unit1` so the shared loader and existing palette are available to both scripts. |
| `isfolder`, `mkdir` | Output-folder existence and creation. |
| `load_sci_image(name)` | Shared project loader for `orion`, `m51`, `bug_nebula`, `eagle_nebula`, `m35`, and `venus`. It uses `fitsinfo` to choose a 2-D primary image when present, otherwise selects Orion's `SCI` image extension. It leaves original FITS files unchanged and returns the selected science array. |
| `fitsinfo`, `fitsread` | MATLAB FITS functions used by the shared loader. `fitsinfo` identifies HDUs, dimensions, and FITS storage type. `fitsread` reads only the selected primary image or SCI extension; table extensions are not passed into the image pipeline. |
| `isfile`, `isfield`, `strlength`, `string`, `lower`, `strcmpi` | Loader path checking, case-insensitive dataset-name handling, and SCI extension-name lookup. |
| `double` | Converts values returned by `fitsread` to MATLAB double precision for DCT and metrics. It does not rescale values to `[0,1]`; all source-unit intensities are retained. |
| `isempty`, `ismatrix`, `isfinite`, `any`, `error` | Input validation and clear failure handling. Non-finite samples are zero-filled before DCT; all six inspected arrays were finite. |
| `size`, `ceil`, `zeros` | Get dimensions and create padding/reconstruction arrays; padding rounds dimensions up to multiples of block size 8. |
| `dct2`, `idct2` | 2-D discrete cosine transform and inverse; used on each 8×8 block. Requires Image Processing Toolbox in common MATLAB installations. |
| `round` | Nearest-integer coefficient quantization after division by step Δ=2 in the integrated pipeline; ties follow MATLAB rounding convention. The comparison script also rounds using its calculated per-image scale-relative step. |
| `mean`, `max`, `min`, `sum`, `log10` | MSE, data range, global SSIM statistics, and dB metric calculations. |
| `realmin`, `eps` | Avoid divide-by-zero in residual SNR and degenerate display limits. |
| `asinh` | Inverse hyperbolic sine stretch. Softening parameter 0.02 balances faint-signal expansion and bright-tail compression. |
| `sort`, `floor` | Percentile helpers use linear interpolation of sorted finite samples. Percentiles 1 and 99.7 set the display limits; in the separate scale experiment their span defines a comparative scale, not a display or metric input. |
| `median` | Calculates the median of the six robust intensity spans to anchor the adaptive comparison step so the median-scale image retains Δ=2. |
| `mat2gray`, `imwrite` | Normalize reconstructed image for an 8-bit PNG preview and save it. This preview is not the source-unit reconstruction. |
| `figure`, `tiledlayout`, `nexttile`, `imagesc`, `axis`, `colormap`, `gray`, `colorbar`, `title`, `exportgraphics`, `close` | Create/save noninteractive image panels. Grayscale and pseudocolour use the same scalar display array. |
| `astro_falsecolor_map(256)` | Existing project function; returns 256-entry scalar-to-RGB display palette. Number 256 controls palette resolution, not image channels. |
| `fprintf`, `disp`, `table` | Command-window reporting and metrics table creation. |
| `writetable`, `save` | CSV, Excel (attempted, guarded), and MAT outputs. Raw original/reconstructed science arrays are saved per input; metrics and summary are also in MAT. |
| `categorical`, `bar`, `ylabel`, `xlabel`, `grid` | Per-image metric plots. BER values remain NaN because no bit channel exists. |
| `measure_pair`, `percentile_sorted` | Local functions in `unit2/evaluate_scale_adaptive_quantization.m`; calculate pairwise metrics and linearly interpolated percentiles for the fixed-step/scale-adaptive experiment. |

## Metric helper

`global_ssim(a,b)` computes global means, variances and covariance: `((2μxμy+C1)(2cov+C2))/((μx²+μy²+C1)(varx+vary+C2))`, with C1/C2 based on 1% and 3% of the observed range. It is a global SSIM variant; MATLAB's `ssim` normally uses local windows and may yield different values. `stretch_asinh` and `percentile` are local helper functions. `save_display` writes a figure with a supplied colormap.

## Batch and scale-comparison behavior

`AstroLink_Final_Integrated.m` iterates over the six configured target IDs and calls the shared loader for each. It retains the original 8×8 DCT, coefficient step Δ=2, source-unit metric comparison, and separate display processing. `unit2/evaluate_scale_adaptive_quantization.m` is an additional experiment; it reports fixed Δ=2 beside `Δᵢ = 2 × robustSpanᵢ / median(robustSpan)` and writes `results/integrated/metrics/quantization_scale_experiment.csv`. It does not change the integrated default.

## Dependencies and version notes

The six-image integrated pipeline and the scale comparison were both executed successfully in MATLAB R2026b. FITS functions, table and graphics APIs must exist in the MATLAB installation. `tiledlayout` and `exportgraphics` require a recent MATLAB release; `dct2`/`idct2` availability and license must be present. Excel export can fail without a supported writer; CSV and MAT remain the core outputs. See `Validation_Checklist.md` for execution evidence and limitations.
