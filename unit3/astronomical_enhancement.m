%% AstroLink - Unit 3: display-only astronomical enhancement
% Contrast, log, and asinh mappings below create display copies only.
% Scientific FITS values, including negative M51 values, remain unchanged.

clc;
clear;
close all;

scriptPath = string(mfilename("fullpath"));
unit3Folder = fileparts(scriptPath);
projectRoot = fileparts(unit3Folder);
unit1Folder = fullfile(projectRoot, "unit1");
addpath(unit1Folder);

% Both images use the same percentile policy. The asinh helper maps this
% intensity interval to [0,1] for display, clipping outlying values only in
% the display copy; 2% softening controls how quickly bright values compress.
datasets = ["orion", "m51"];
percentiles = [1 99.7];
softeningFraction = 0.02;
darkBackground = [0.008 0.012 0.025];
lightForeground = [0.93 0.95 0.98];
falseColorMap = astro_falsecolor_map(256);

for datasetName = datasets
    % Keep this array in its original science units. The finite-value copy
    % below is used only for the histogram and to avoid counting NaN/Inf.
    scienceImage = double(load_sci_image(datasetName));
    finiteValues = scienceImage(isfinite(scienceImage));
    if isempty(finiteValues)
        error("No finite science pixels available for %s.", datasetName);
    end
    [asinhDisplay, intensityLimits] = astro_display_stretch( ...
        scienceImage, [], percentiles, softeningFraction);

    switch datasetName
        case "orion"
            intensityUnit = "COUNTS/S";
            sourceName = "WFPC2 drizzled SCI, F658N";
        case "m51"
            intensityUnit = "ELECTRONS";
            sourceName = "ACS drizzled primary, F435W";
    end

    % Linear contrast stretch maps the chosen percentile range to [0,1].
    % Values outside the range are clipped in this display-only result.
    lowerLimit = intensityLimits(1);
    upperLimit = intensityLimits(2);
    range = upperLimit - lowerLimit;
    contrastDisplay = min(max((scienceImage - lowerLimit) / range, 0), 1);

    % Log is defined for nonnegative values. Shift the display copy by the
    % lower percentile and clip it there; the scientific array is untouched.
    nonnegativeDisplayInput = min(max(scienceImage - lowerLimit, 0), range);
    logDisplay = log1p(nonnegativeDisplayInput) / log1p(range);
    logDisplay(~isfinite(logDisplay)) = 0;

    % Each panel is one intensity array shown through the same false-colour
    % palette. Colour is a visual encoding, not an additional data channel.
    outputFolder = fullfile(projectRoot, "results", "unit3", datasetName);
    if ~isfolder(outputFolder)
        mkdir(outputFolder);
    end

    fig = figure("Visible", "off", "Color", darkBackground, ...
        "Position", [60 80 1650 1000]);
    tiledlayout(fig, 2, 2, "Padding", "compact", ...
        "TileSpacing", "compact");
    % The first and fourth panels intentionally use the same asinh display:
    % the first is the baseline, and the final one names the stretch itself.
    displayNames = ["Original | asinh display"; ...
        "Linear contrast stretch"; ...
        "Log transform | nonnegative shifted copy"; ...
        "Asinh stretch"];
    displayCopies = {asinhDisplay, contrastDisplay, logDisplay, asinhDisplay};

    for panelIndex = 1:numel(displayCopies)
        ax = nexttile;
        imagesc(ax, displayCopies{panelIndex}, [0 1]);
        axis(ax, "image");
        colormap(ax, falseColorMap);
        ax.Color = darkBackground;
        ax.XColor = lightForeground;
        ax.YColor = lightForeground;
        title(ax, displayNames(panelIndex), ...
            "Color", lightForeground, "FontSize", 12);
        xlabel(ax, "Pixel column");
        ylabel(ax, "Pixel row");
        cb = colorbar(ax);
        cb.Color = lightForeground;
        cb.Label.String = "False-colour display level";
        cb.Label.Color = lightForeground;
        cb.FontSize = 9;
    end
    sgtitle(fig, sprintf("%s | display-only enhancement | %s", ...
        upper(datasetName), sourceName), ...
        "Color", lightForeground, "FontSize", 15, "FontWeight", "bold");
    annotation(fig, "textbox", [0.04 0.005 0.92 0.035], ...
        "String", sprintf("Percentile limits [%.4g, %.4g] %s. Log view shifts by the lower limit and clips below it. Palette encodes one intensity image, not RGB.", ...
        lowerLimit, upperLimit, intensityUnit), ...
        "Color", lightForeground, "FontSize", 9, ...
        "EdgeColor", "none", "HorizontalAlignment", "center");
    exportgraphics(fig, fullfile(outputFolder, ...
        "astronomical_enhancement.png"), "Resolution", 200);
    close(fig);

    fig = figure("Visible", "off", "Color", darkBackground, ...
        "Position", [100 100 1150 650]);
    ax = axes(fig);
    % The histogram uses original intensities and source units. Restrict its
    % x-axis to the display limits so the central distribution is legible;
    % pixels outside the interval remain part of the science array.
    histogram(ax, finiteValues, 200, ...
        "BinLimits", intensityLimits, ...
        "FaceColor", [0.16 0.68 0.82], ...
        "EdgeColor", "none");
    ax.Color = darkBackground;
    ax.XColor = lightForeground;
    ax.YColor = lightForeground;
    title(ax, sprintf("%s | science-pixel histogram | clipped display range", ...
        upper(datasetName)), "Color", lightForeground, ...
        "FontSize", 14, "FontWeight", "bold");
    xlabel(ax, sprintf("Original science intensity (%s)", intensityUnit));
    ylabel(ax, "Pixel count per bin");
    grid(ax, "on");
    ax.GridColor = [0.45 0.50 0.58];
    ax.GridAlpha = 0.25;
    xlim(ax, intensityLimits);
    exportgraphics(fig, fullfile(outputFolder, ...
        "science_intensity_histogram.png"), "Resolution", 200);
    close(fig);

    fprintf("%s enhancement outputs:\n", upper(datasetName));
    fprintf("  %s\n", fullfile(outputFolder, "astronomical_enhancement.png"));
    fprintf("  %s\n", fullfile(outputFolder, "science_intensity_histogram.png"));
    fprintf("  source intensities preserved; display limits [%.6g, %.6g] %s\n", ...
        lowerLimit, upperLimit, intensityUnit);
end
