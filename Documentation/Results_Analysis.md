# Results analysis

## Execution and scope

`AstroLink_Final_Integrated.m` was run with MATLAB R2026b after configuring all six independent targets. It used the inherited 8×8 block DCT and fixed coefficient step Δ=2. The metrics below compare the loaded source-unit science arrays (non-finite pixels would be zero-filled; the six inspected inputs contained none) with the cropped inverse-DCT reconstructions. Display stretch and pseudocolour are downstream only and are not used in metric calculations. Results were exported under `results/integrated/metrics/`, with per-image figures and comparisons under `results/integrated/`.

## Integrated results at Δ=2

| Target | MSE | PSNR (dB) | Global SSIM | Residual SNR (dB) | BER |
|---|---:|---:|---:|---:|---|
| Orion | 0.0136203 | 52.6750 | 0.996255 | 20.9396 | N/A |
| M51 | 0.00577116 | 63.3386 | 0.998769 | 8.1730 | N/A |
| Bug Nebula | 0.110549 | 75.9414 | 0.999981 | 39.7681 | N/A |
| Eagle Nebula | 0.196382 | 76.4309 | 0.999976 | 31.6559 | N/A |
| M35 cluster | 0.340003 | 93.8089 | 0.99999996 | 79.9876 | N/A |
| Venus | 0.120893 | 92.0091 | 0.99999944 | 52.7330 | N/A |
| Mean of six | 0.1312 | 75.701 | 0.99916 | 38.876 | N/A |

The generated `metrics.csv`, `metrics.mat`, `metrics_summary.csv`, and attempted Excel export contain the actual run values. PNG metric graphs, comparisons, display images, and reconstructed arrays were also written. CSV and MAT exports completed; Excel output is guarded by a `try/catch`.

## Interpretation and metric definitions

- MSE is `mean((I-R)^2)` in squared source units. Its magnitude is not directly comparable when FITS inputs use different or unspecified units.
- PSNR uses each image's full observed max-minus-min range: `10 log10(L²/MSE)`. The large values for M35 and Venus reflect their wide raw ranges; they do not alone establish better scientific fidelity.
- SSIM is the project's global-statistics implementation, not MATLAB's standard local-window `ssim`. Values near one indicate similar global luminance/variance/covariance but can miss local artifacts.
- Residual SNR is `10 log10(sum(I²)/sum((I-R)²))`, an image energy to reconstruction-error ratio. It is not channel or RF SNR and can be affected by source offset and intensity scale.
- BER is unavailable (`NaN`), not zero, because no transmitted and received bitstreams exist.

## Δ=2 scale investigation

The integrated implementation retains Δ=2 as the baseline, but the raw FITS intensity scales differ substantially. The robust span below is p99.7−p1 of each source array. The scale experiment was run by `unit2/evaluate_scale_adaptive_quantization.m`; it writes the complete fixed/adaptive metric comparison to `quantization_scale_experiment.csv`.

| Target | Robust span | Δ=2 RMSE / robust span | Scale-relative Δᵢ | Adaptive RMSE / robust span |
|---|---:|---:|---:|---:|
| Orion | 4.38753 | 0.0265997 | 0.0737413 | 0.00369053 |
| M51 | 0.883980 | 0.0859389 | 0.0148572 | 0.00373239 |
| Bug Nebula | 216.938 | 0.00153290 | 3.64551 | 0.00206420 |
| Eagle Nebula | 21.0919 | 0.0210107 | 0.354491 | 0.00412220 |
| M35 cluster | 18142.0 | 0.0000321408 | 304.916 | 0.00466567 |
| Venus | 1841.63 | 0.000188804 | 30.9516 | 0.000866125 |

The tested alternative uses one consistent rule, `Δᵢ = 2 × robustSpanᵢ / median(robustSpan)`, so the median-span image retains Δ=2 and all other steps scale by the same relative-span convention. Fixed-step relative RMSE ranged from 0.0000321 to 0.08594 (about 2,674×). The adaptive experiment narrowed it to 0.000866 to 0.004666 (about 5.4×). This is evidence that Δ=2 does not impose comparable relative quantization across these raw scales. The adaptive rule improves relative error for Orion, M51, and Eagle, while increasing it for Bug, M35, and Venus. It is a scale-consistency candidate, not a universally optimal setting; the production integrated pipeline remains at Δ=2 until a scientific distortion criterion is agreed.

## Limits

There are six different target objects, but this is still a small and heterogeneous sample. Header `BUNIT` is absent from the four new FITS inputs, and M35 also lacks instrument/exposure keywords in the inspected primary header. Dates and numeric filter codes are preserved as recorded rather than decoded. The scale-adaptive step normalizes a robust intensity span but does not solve differences in detector response, background, noise, or physical units. The project still has no RF link, encoded bitstream, channel, or decoder; BER and channel SNR cannot be reported. Do not count FITS extensions, calibrations, chips, or display derivatives as new targets.
