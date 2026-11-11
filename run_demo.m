%% AstroLink - Run six-target integrated processing and display
% This entry point processes all six configured FITS targets, then opens the
% results viewer with the six-target reconstruction overview in front.
root = fileparts(mfilename("fullpath"));
run(fullfile(root,"AstroLink_Final_Integrated.m"));
run(fullfile(root,"unit1","Display_results.m"));
