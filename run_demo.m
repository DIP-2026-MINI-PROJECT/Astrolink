%% AstroLink - Run the complete project demonstration
% The sequence follows the syllabus: FITS inspection, Unit 1, selected
% Unit 3 enhancement/filtering, Unit 4 morphology/pseudocolour, Unit 2 DCT,
% quantization evaluation, and finally the results viewer.

run(fullfile(fileparts(mfilename("fullpath")), "unit1", "inspect_fits.m"));
run(fullfile(fileparts(mfilename("fullpath")), "unit1", "sampling_quantization.m"));
run(fullfile(fileparts(mfilename("fullpath")), "unit1", "pixel_relationships.m"));
run(fullfile(fileparts(mfilename("fullpath")), "unit1", "linear_nonlinear_operations.m"));
run(fullfile(fileparts(mfilename("fullpath")), "unit1", "astronomical_visualization.m"));
run(fullfile(fileparts(mfilename("fullpath")), "unit3", "astronomical_enhancement.m"));
run(fullfile(fileparts(mfilename("fullpath")), "unit3", "astronomical_filtering.m"));
run(fullfile(fileparts(mfilename("fullpath")), "unit4", "morphological_processing.m"));
run(fullfile(fileparts(mfilename("fullpath")), "unit4", "pseudocolor_visualization.m"));
run(fullfile(fileparts(mfilename("fullpath")), "unit2", "dct_compression.m"));
run(fullfile(fileparts(mfilename("fullpath")), "unit2", "evaluate_dct_quantization.m"));
run(fullfile(fileparts(mfilename("fullpath")), "unit1", "Display_results.m"));
