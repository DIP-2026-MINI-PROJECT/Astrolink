# Validation checklist

| Check | Status | Evidence / limitation |
|---|---|---|
| All six technical baseline documents read before changes | PASS | Read Function Reference, Project Audit, Results Analysis, Theory and Implementation, Validation Checklist, and Viva Preparation first. |
| Existing four-unit architecture preserved | PASS | `unit1`–`unit4` remain in place; `run_demo.m` unchanged. Integrated pipeline is a separate entry point. |
| Shared FITS loader extended | PASS | `unit1/load_sci_image.m` keeps the Orion SCI and M51 primary paths and adds the four new primary-image inputs. MATLAB Code Analyzer reported no issues for this file. |
| Four new FITS files inspected | PASS | `fitsinfo`/`fitsread` inspection recorded HDU layout, dimensions, stored type, returned MATLAB class, finite counts, ranges, and available header metadata in `Project_Audit.md`. |
| Six independent targets configured | PASS | Orion, M51, Bug Nebula, Eagle Nebula, M35 cluster, and Venus each use one selected source image. Extensions and companion products are not counted as targets. |
| All six integrated targets execute | PASS | `AstroLink_Final_Integrated.m` completed under MATLAB R2026b and printed one metrics row for each of six targets. |
| Existing Orion and M51 processing preserved | PASS | Their dimensions and Δ=2 metrics match the prior two-image run. |
| 8×8 DCT and Δ=2 baseline preserved | PASS | Integrated source retains `block=8`, `qstep=2`; six-image metrics were generated using these values. |
| Δ=2 scale suitability investigated | PASS | Separate scale experiment was run; fixed robust-NRMSE span was 0.0000321–0.08594. Scale-relative candidate reduced it to 0.000866–0.004666, while increasing distortion for some targets. |
| Original science values remain separate from display | PASS | Metrics precede asinh stretch; display and pseudocolour products are generated separately. No pseudocolour data enter metric calculations. |
| Source data finite and shape checks | PASS | Six selected arrays are 2-D and finite; selected sizes and ranges are listed in `Project_Audit.md`. |
| Six-image metrics and outputs exported | PASS | CSV/MAT metrics, summary, graphs, comparison images, reconstructed arrays, and displays were generated under `results/integrated/`. The scale experiment CSV was also generated. |
| MATLAB Code Analyzer | PASS | No issues reported for the shared loader, six-image integrated script, or scale experiment script. |
| Individual educational unit scripts after loader extension | NOT TESTED | The integrated six-image path was run; `run_demo.m` and every interactive unit script were not rerun. |
| Local-window SSIM | NOT IMPLEMENTED | Reported SSIM is the global-statistics formula, explicitly distinguished from MATLAB local-window `ssim`. |
| RF, transmitted bits, BER, channel SNR | NOT IMPLEMENTED | No bitstream or channel exists. BER remains NaN/unavailable, not zero. |
| Dataset-wide generalization | LIMITED | Six targets are configured, but this is still a small and heterogeneous sample; several FITS inputs lack `BUNIT` metadata. |
