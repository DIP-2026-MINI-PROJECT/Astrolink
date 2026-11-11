# Function reference for integrated script

Only functions actually called by `AstroLink_Final_Integrated.m` are listed.

| Function | Purpose, inputs/outputs, theory and parameter notes |
|---|---|
| `mfilename('fullpath')` | MATLAB built-in; current script path, used to resolve project root. |
| `fileparts`, `fullfile` | Path decomposition and platform-correct path construction. Relative paths avoid machine-specific roots. |
| `addpath` | Adds `unit1` so the shared loader and existing palette are available. |
| `isfolder`, `mkdir` | Output-folder existence and creation. |
| `load_sci_image(name)` | Project function; reads Orion SCI extension or M51 primary FITS image, returns numeric 2-D science array. Requires `fitsinfo`/`fitsread`. |
| `double` | Converts integer/single FITS values to double precision without normalizing physical units. |
| `isempty`, `ismatrix`, `isfinite`, `error` | Input validation and clear failure handling. Non-finite values are replaced by zero before DCT. |
| `size`, `ceil`, `zeros` | Get dimensions and create padding/reconstruction arrays; padding rounds dimensions up to multiples of block size 8. |
| `dct2`, `idct2` | 2-D discrete cosine transform and inverse; used on each 8×8 block. Requires Image Processing Toolbox in common MATLAB installations. |
| `round` | Nearest-integer coefficient quantization after division by step Δ=2; ties follow MATLAB rounding convention. |
| `mean`, `max`, `min`, `sum`, `log10` | MSE, data range, global SSIM statistics, and dB metric calculations. |
| `realmin`, `eps` | Avoid divide-by-zero and degenerate percentile limits. |
| `asinh` | Inverse hyperbolic sine stretch. Softening parameter 0.02 balances faint-signal expansion and bright-tail compression. |
| `sort`, `floor` | Percentile helper via linear interpolation of sorted finite samples. Percentiles 1 and 99.7 reduce outlier influence on display only. |
| `mat2gray`, `imwrite` | Normalize reconstructed image for an 8-bit PNG preview and save it. This preview is not the source-unit reconstruction. |
| `figure`, `tiledlayout`, `nexttile`, `imagesc`, `axis`, `colormap`, `gray`, `colorbar`, `title`, `exportgraphics`, `close` | Create/save noninteractive image panels. Grayscale and pseudocolour use the same scalar display array. |
| `astro_falsecolor_map(256)` | Existing project function; returns 256-entry scalar-to-RGB display palette. Number 256 controls palette resolution, not image channels. |
| `fprintf`, `disp`, `table` | Command-window reporting and metrics table creation. |
| `writetable`, `save` | CSV, Excel (attempted, guarded), and MAT outputs. Raw original/reconstructed science arrays are saved per input; metrics and summary are also in MAT. |
| `categorical`, `bar`, `ylabel`, `xlabel`, `grid` | Per-image metric plots. BER values remain NaN because no bit channel exists. |

## Metric helper

`global_ssim(a,b)` computes global means, variances and covariance: `((2μxμy+C1)(2cov+C2))/((μx²+μy²+C1)(varx+vary+C2))`, with C1/C2 based on 1% and 3% of the observed range. It is a global SSIM variant; MATLAB's `ssim` normally uses local windows and may yield different values. `stretch_asinh` and `percentile` are local helper functions. `save_display` writes a figure with a supplied colormap.

## Dependencies and version notes

FITS functions, table and graphics APIs must exist in the MATLAB installation. `tiledlayout` and `exportgraphics` require relatively recent MATLAB releases; the repository's old inspection report came from R2026b. `dct2`/`idct2` availability/license must be checked. Excel export can fail without a supported writer; CSV/MAT remain the core outputs. The integrated script was not executed in this environment, so runtime compatibility is NOT TESTED.
