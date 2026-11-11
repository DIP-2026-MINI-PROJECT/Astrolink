%% AstroLink - Unit 1, Topic 4: Linear and Nonlinear Operations
%
% Syllabus topic: linear and nonlinear operations.
%
% This script demonstrates the basic LINEAR point
% operations from the course notes:
%
%   1. Contrast scaling:   s = a * r + b
%   2. Negation:           s = 1 - r   (display image in [0, 1])
%
% A point operation maps each pixel value r to a new
% value s = T(r), pixel by pixel, without using the
% neighbours.
%
% The class notes currently cover the linear point
% operations only, so this script demonstrates those
% two operations.
%
% The same demonstration runs on two datasets (Orion
% and M51) using the same code. The original scientific
% pixel values are preserved: every operation runs on a
% separate normalized display copy.

clc;
clear;
close all;

% Resolve the project root from this script's location.
scriptPath = string(mfilename("fullpath"));
projectRoot = fileparts(fileparts(scriptPath));
resultsFolder = fullfile(projectRoot, "results");

% The two datasets to process.
datasets = ["orion", "m51"];

% ---- Shared visual style (presentation only) ----
darkBg  = [0.07 0.08 0.10];   % dark slate background
lightFg = [0.93 0.94 0.96];   % light text and tick marks
midFg   = [0.62 0.65 0.70];   % secondary notes

for datasetIndex = 1:numel(datasets)
    datasetName = datasets(datasetIndex);

    fprintf("\n==============================\n");
    fprintf(" Dataset: %s\n", datasetName);
    fprintf("==============================\n");

    %% 1. Load the science image
    % load_sci_image finds the right FITS file and
    % reads the science image (original values).
    scienceImage = load_sci_image(datasetName);

    % Normalize the science image to the display range
    % [0, 1]. mat2gray maps the minimum value to 0 and
    % the maximum value to 1. This display copy is
    % separate from the original data.
    displayImage = mat2gray(scienceImage);

    % Folder for this dataset's figures.
    datasetFolder = fullfile(resultsFolder, "unit1", datasetName);
    if ~isfolder(datasetFolder)
        mkdir(datasetFolder);
    end

    %% 2. Linear operation 1: contrast scaling  s = a * r + b
    % Each pixel value r is multiplied by a and shifted
    % by b. a controls the contrast (slope), b controls
    % the brightness (offset). Results outside [0, 1]
    % are clipped, because a display can only show
    % that range.
    a = 1.5;   % slope (contrast)
    b = 0.1;   % offset (brightness)
    scaledImage = a * displayImage + b;
    scaledImage = min(max(scaledImage, 0), 1);   % clip to [0, 1]

    %% 3. Linear operation 2: negation  s = 1 - r
    % Every pixel value is subtracted from 1, so dark
    % pixels become bright and bright pixels become
    % dark. (General form for L gray levels: s = (L-1) - r.)
    negatedImage = 1 - displayImage;

    %% 4. Display the original image first, then the
    % two results, all on the same display scale.

    fig = figure("Visible", "off", ...
        "Color", darkBg, ...
        "Position", [100 100 1260 440]);
    set(fig, ...
        "DefaultAxesFontName", "Calibri", ...
        "DefaultAxesFontSize", 10, ...
        "DefaultAxesColor", darkBg, ...
        "DefaultAxesXColor", lightFg, ...
        "DefaultAxesYColor", lightFg, ...
        "DefaultAxesLineWidth", 0.8, ...
        "DefaultAxesBox", "on", ...
        "DefaultTextFontName", "Calibri");
    colormap(fig, turbo(256));

    tiledlayout(1, 3, "Padding", "compact", ...
        "TileSpacing", "compact");

    nexttile;
    imagesc(displayImage);
    axis image;
    clim([0 1]);
    cb = colorbar;
    cb.Color = lightFg;
    cb.FontSize = 9;
    cb.Label.String = "display level (0 = dark, 1 = bright)";
    cb.Label.Color = lightFg;
    title("Original r (display copy)", ...
        "Color", "w", "FontSize", 11);

    nexttile;
    imagesc(scaledImage);
    axis image;
    clim([0 1]);   % same display scale as the original
    title(sprintf("Contrast scaling: s = %.1f r + %.1f (clipped to [0 1])", a, b), ...
        "Color", "w", "FontSize", 11);

    nexttile;
    imagesc(negatedImage);
    axis image;
    clim([0 1]);   % same display scale as the original
    title("Negation: s = 1 - r", ...
        "Color", "w", "FontSize", 11);

    sgtitle(sprintf("%s - Linear Point Operations (Unit 1, Topic 4)", ...
        datasetName), "Color", "w", "FontSize", 13, ...
        "FontWeight", "bold");
    annotation("textbox", [0.03 0.008 0.94 0.032], ...
        "String", "Display copy: mat2gray maps min -> 0 and max -> 1. " + ...
        "All panels share the display scale [0 1]; the FITS pixel values are unchanged.", ...
        "Color", midFg, "FontSize", 9, "EdgeColor", "none", ...
        "HorizontalAlignment", "center");
    exportgraphics(gcf, ...
        fullfile(datasetFolder, "unit1_linear_nonlinear.png"), ...
        "Resolution", 150);
    close(gcf);

    fprintf("Saved figure: %s\n", ...
        fullfile(datasetFolder, "unit1_linear_nonlinear.png"));
end

fprintf("\nLinear point operations complete for both datasets.\n");
fprintf("Figures saved in results/unit1/orion/ and results/unit1/m51/\n");

