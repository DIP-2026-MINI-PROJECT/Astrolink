%% AstroLink - Unit 1, Topic 2: Sampling and Quantization
%
% Syllabus topic: image sampling and quantization.
%
%   SAMPLING = how often we measure the image in space
%   (spatial resolution). Here we keep every Nth row and
%   every Nth column. Larger N -> fewer samples.
%
%   QUANTIZATION = how many gray levels we store per
%   pixel (intensity resolution). Here we round pixel
%   values to L evenly spaced levels.
%
% The same demonstration runs on two datasets (Orion and
% M51) using the same code. The original scientific data
% is used for sampling and quantization. Asinh stretching is applied
% only to separate copies used to render the figures.

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
gridCol = [0.42 0.45 0.50];   % subtle grid lines

for datasetIndex = 1:numel(datasets)
    datasetName = datasets(datasetIndex);

    fprintf("\n==============================\n");
    fprintf(" Dataset: %s\n", datasetName);
    fprintf("==============================\n");

    %% 1. Read the science image
    % load_sci_image finds the right FITS file and
    % reads the science image (original values).
    scienceImage = double(load_sci_image(datasetName));
    if datasetName == "orion"
        intensityUnit = "COUNTS/S";
    else
        intensityUnit = "ELECTRONS";
    end

    fprintf("Original science image (values unmodified):\n");
    fprintf("  size:  %d x %d pixels\n", ...
        size(scienceImage, 1), size(scienceImage, 2));
    fprintf("  class: %s\n", class(scienceImage));
    fprintf("  range: %.4f to %.4f\n", ...
        min(scienceImage(:)), max(scienceImage(:)));

    % Shared display mapping; all scientific operations below use the
    % original values, not this stretched copy.
    softeningFraction = 0.02;
    [displayImage, displayLimits] = astro_display_stretch( ...
        scienceImage, [], [1 99.7], softeningFraction);

    % Folder for this dataset's figures.
    datasetFolder = fullfile(resultsFolder, "astronomical_visualization", ...
        "unit1", datasetName);
    if ~isfolder(datasetFolder)
        mkdir(datasetFolder);
    end

    %% 3. Spatial sampling
    % Keep every Nth row and every Nth column, starting
    % at row 1, column 1:
    %   sampledImage(i, j) = scienceImage((i-1)*N+1, (j-1)*N+1)

    sampleSteps = [2, 4, 8];   % keep every 2nd, 4th, 8th pixel

    % Polished figure: dark background, light text,
    % grayscale astronomical display, one shared scale.
    fig = figure("Visible", "off", ...
        "Color", darkBg, ...
        "Position", [100 100 1000 620]);
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

    tiledlayout(2, 2, "Padding", "compact", ...
        "TileSpacing", "compact");

    % The original astronomical image comes first.
    nexttile;
    imagesc(displayImage);
    axis image;
    clim([0 1]);
    cb = colorbar;
    astro_display_colorbar(cb, displayLimits, softeningFraction, ...
        intensityUnit, lightFg);
    title(sprintf("Original image: all %d x %d samples", ...
        size(scienceImage, 1), size(scienceImage, 2)), ...
        "Color", "w", "FontSize", 11);

    for k = 1:numel(sampleSteps)
        N = sampleSteps(k);
        sampledImage = scienceImage(1:N:end, 1:N:end);
        sampledDisplay = astro_display_stretch(sampledImage, displayLimits, ...
            [1 99.7], softeningFraction);
        nexttile;
        imagesc(sampledDisplay);
        axis image;
        clim([0 1]);   % same display scale as the original
        title(sprintf("Every %dth pixel: %d x %d (%.1f%%)", ...
            N, size(sampledImage, 1), size(sampledImage, 2), ...
            100 * numel(sampledImage) / numel(displayImage)), ...
            "Color", "w", "FontSize", 11);
    end

    sgtitle(sprintf("%s - Spatial Sampling (Unit 1, Topic 2)", ...
        datasetName), "Color", "w", "FontSize", 13, ...
        "FontWeight", "bold");
    annotation("textbox", [0.03 0.008 0.94 0.032], ...
        "String", sprintf("Sampling uses unmodified science values. Panels share the asinh display mapping and original intensity limits [%.4g, %.4g] %s.", ...
        displayLimits(1), displayLimits(2), intensityUnit), ...
        "Color", midFg, "FontSize", 9, "EdgeColor", "none", ...
        "HorizontalAlignment", "center");
    exportgraphics(gcf, ...
        fullfile(datasetFolder, "unit1_sampling.png"), ...
        "Resolution", 150);
    close(gcf);

    fprintf("\nSpatial sampling (every Nth row and column kept):\n");
    for k = 1:numel(sampleSteps)
        N = sampleSteps(k);
        sampledImage = scienceImage(1:N:end, 1:N:end);
        fprintf("  N = %d -> %d x %d = %d pixels (%.1f%% of the original)\n", ...
            N, size(sampledImage, 1), size(sampledImage, 2), ...
            numel(sampledImage), 100 * numel(sampledImage) / numel(scienceImage));
    end

    %% 4. Intensity quantization
    % Quantize the original science range into L evenly spaced levels.
    % Display stretching is applied only after quantization.

    grayLevelCounts = [64, 16, 4, 2];   % number of gray levels L
    quantizationLimits = [min(scienceImage(:)), max(scienceImage(:))];
    quantizationRange = diff(quantizationLimits);
    if quantizationRange <= 0
        error("Cannot quantize a constant-valued image: %s", datasetName);
    end

    fig = figure("Visible", "off", ...
        "Color", darkBg, ...
        "Position", [100 100 1260 620]);
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

    tiledlayout(2, 3, "Padding", "compact", ...
        "TileSpacing", "compact");

    % The original astronomical image comes first.
    nexttile;
    imagesc(displayImage);
    axis image;
    clim([0 1]);
    cb = colorbar;
    astro_display_colorbar(cb, displayLimits, softeningFraction, ...
        intensityUnit, lightFg);
    title("Original: unmodified science intensities", ...
        "Color", "w", "FontSize", 11);

    for k = 1:numel(grayLevelCounts)
        L = grayLevelCounts(k);
        quantizedImage = quantizationLimits(1) + ...
            round((scienceImage - quantizationLimits(1)) * ...
            (L - 1) / quantizationRange) * quantizationRange / (L - 1);
        quantizedDisplay = astro_display_stretch(quantizedImage, ...
            displayLimits, [1 99.7], softeningFraction);
        nexttile;
        imagesc(quantizedDisplay);
        axis image;
        clim([0 1]);   % same display scale as the original
        title(sprintf("Quantized science values: L = %d levels", L), ...
            "Color", "w", "FontSize", 11);
    end

    sgtitle(sprintf("%s - Intensity Quantization (Unit 1, Topic 2)", ...
        datasetName), "Color", "w", "FontSize", 13, ...
        "FontWeight", "bold");
    annotation("textbox", [0.03 0.008 0.94 0.032], ...
        "String", sprintf("Quantization uses the original science-value range [%.4g, %.4g] %s. All panels share the original-image asinh display mapping.", ...
        quantizationLimits(1), quantizationLimits(2), intensityUnit), ...
        "Color", midFg, "FontSize", 9, "EdgeColor", "none", ...
        "HorizontalAlignment", "center");
    exportgraphics(gcf, ...
        fullfile(datasetFolder, "unit1_quantization.png"), ...
        "Resolution", 150);
    close(gcf);

    fprintf("\nIntensity quantization results:\n");
    for k = 1:numel(grayLevelCounts)
        L = grayLevelCounts(k);
        quantizedImage = quantizationLimits(1) + ...
            round((scienceImage - quantizationLimits(1)) * ...
            (L - 1) / quantizationRange) * quantizationRange / (L - 1);
        fprintf("  L = %d gray levels -> %d distinct values present\n", ...
            L, numel(unique(quantizedImage)));
    end

    fprintf("\nWhat to observe (%s):\n", datasetName);
    fprintf("  Sampling: as N grows (2 -> 4 -> 8) the image keeps\n");
    fprintf("  fewer samples, so fine detail (stars, wisps)\n");
    fprintf("  disappears and the picture looks blockier.\n");
    fprintf("  This is spatial resolution loss.\n");
    fprintf("  Quantization: as L shrinks (64 -> 16 -> 4 -> 2)\n");
    fprintf("  smooth areas develop visible bands (false\n");
    fprintf("  contours). With L = 2 the image becomes pure\n");
    fprintf("  black and white. This is intensity resolution\n");
    fprintf("  loss.\n");
end

fprintf("\nSaved figures in results/astronomical_visualization/unit1/orion/ and m51/:\n");
fprintf("  unit1_sampling.png, unit1_quantization.png\n");
