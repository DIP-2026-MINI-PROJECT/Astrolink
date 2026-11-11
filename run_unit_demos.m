%% AstroLink - Run the course-unit demonstrations
% Runs the individual FITS inspection and four-unit educational examples.
% Use run_demo.m for the six-target integrated pipeline and combined viewer.
root = fileparts(mfilename("fullpath"));

run(fullfile(root,"unit1","inspect_fits.m"));
run(fullfile(root,"unit1","sampling_quantization.m"));
run(fullfile(root,"unit1","pixel_relationships.m"));
run(fullfile(root,"unit1","linear_nonlinear_operations.m"));
run(fullfile(root,"unit1","astronomical_visualization.m"));
run(fullfile(root,"unit3","astronomical_enhancement.m"));
run(fullfile(root,"unit3","astronomical_filtering.m"));
run(fullfile(root,"unit4","morphological_processing.m"));
run(fullfile(root,"unit4","pseudocolor_visualization.m"));
run(fullfile(root,"unit2","dct_compression.m"));
run(fullfile(root,"unit2","evaluate_dct_quantization.m"));
run(fullfile(root,"unit1","Display_results.m"));
