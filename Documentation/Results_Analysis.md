# Results analysis

The integrated script was executed in MATLAB R2026b on the two independent available science images: Orion and M51. Results are from the original source-unit arrays versus DCT reconstructions, using block size 8 and coefficient step Δ=2. The metric table was saved to `results/integrated/metrics/metrics.csv` and `.mat`; graph and image outputs were generated. An Excel copy is attempted by the script and should be checked in the output folder.

| Image | MSE | PSNR (dB) | Global SSIM | Residual SNR (dB) | BER |
|---|---:|---:|---:|---:|---:|
| Orion | 0.0136203 | 52.675 | 0.996255 | 20.940 | N/A |
| M51 | 0.00577116 | 63.339 | 0.998769 | 8.173 | N/A |
| Mean | 0.0096957 | 58.007 | 0.997512 | 14.556 | N/A |

BER is unavailable, not zero, because no encoded bits traverse a channel. PSNR uses each original image's max-minus-min as its peak range. Residual SNR compares image energy to reconstruction error and is not channel SNR. M51's higher PSNR but lower residual SNR illustrates that the metrics use different denominators/conventions; do not interpret them interchangeably.

Expected interpretation: lower MSE is closer reconstruction; higher PSNR and SSIM indicate greater fidelity; residual SNR compares image energy with reconstruction error and is not RF channel SNR. BER is NaN/undefined because the implementation has no bitstream link. No average is fabricated from unexecuted results. There are two independent input targets, below the requested ten by eight. Re-running Orion chips, extensions, or transformed copies does not resolve the independent-image shortage.

These are a two-image demonstration, not a broad generalization. Do not substitute display-enhanced images into metric calculations.
