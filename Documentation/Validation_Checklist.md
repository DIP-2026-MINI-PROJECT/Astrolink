# Validation checklist

| Check | Status | Evidence / limitation |
|---|---|---|
| Existing units and files inspected | PASS | Repository listing and source inspection; see Project_Audit.md |
| Integrated single entry script created | PASS (static) | `AstroLink_Final_Integrated.m` |
| Four unit headings and pipeline present | PASS (static) | Sections 1–4 in integrated script |
| Uses actual current Unit 2 technique accurately | PASS | DCT quantization; explicitly not RF |
| Unit 4 separates display copies from science values | PASS (static) | Asinh output generated after science metrics; pseudocolour note |
| Ten distinct images | FAIL | Only Orion and M51 are independent science images in current configured data |
| MATLAB execution | PASS | Executed with MATLAB R2026b using workspace-local preference folder; both images completed |
| Metrics/results table generated | PASS | Console table and CSV/MAT summary created under `results/integrated/metrics` |
| Metrics graphs and image outputs generated | PASS | Integrated script completed all export calls |
| FITS/DCT/graphics runtime availability | PASS | FITS reads, transforms and graphics executed for both configured images |
| Actual RF, BER, channel SNR | NOT IMPLEMENTED | No bitstream/modem/channel in existing code; BER emitted as NaN |
| Source-array reconstruction metrics are computed | PASS | Original vs inverse-DCT science array, not display copies; see Results_Analysis.md |
