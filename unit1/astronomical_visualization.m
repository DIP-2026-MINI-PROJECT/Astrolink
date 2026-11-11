%% AstroLink - Single-image astronomical display views
% Save a scientific intensity view and a single-image false-colour view
% for each dataset. All transformations below are display-only.

clc;
clear;
close all;

scriptPath = string(mfilename("fullpath"));
scriptFolder = fileparts(scriptPath);
projectRoot = fileparts(fileparts(scriptPath));
addpath(scriptFolder);

datasets = ["orion", "m51"];
percentiles = [1 99.7];
softeningFraction = 0.02;
darkBackground = [0.008 0.012 0.025];
lightForeground = [0.93 0.95 0.98];
visualizationRoot = fullfile(projectRoot, "results", ...
    "astronomical_visualization");

for datasetName = datasets
    scienceImage = double(load_sci_image(datasetName));
    [displayImage, intensityLimits] = astro_display_stretch( ...
        scienceImage, [], percentiles, softeningFraction);

    switch datasetName
        case "orion"
            unitLabel = "COUNTS/S";
            sourceLabel = "HST WFPC2 drizzled SCI, F658N";
        case "m51"
            unitLabel = "ELECTRONS";
            sourceLabel = "HST ACS drizzled primary, F435W";
    end

    outputFolder = fullfile(visualizationRoot, datasetName);
    if ~isfolder(outputFolder)
        mkdir(outputFolder);
    end

    fig = figure("Visible", "off", "Color", darkBackground, ...
        "Position", [80 60 1500 1120]);
    set(fig, "DefaultAxesColor", darkBackground, ...
        "DefaultAxesXColor", lightForeground, ...
        "DefaultAxesYColor", lightForeground, ...
        "DefaultAxesFontName", "Calibri", "DefaultAxesFontSize", 12, ...
        "DefaultTextFontName", "Calibri");
    layout = tiledlayout(fig, 1, 1, ...
        "Padding", "compact", "TileSpacing", "compact");
    ax = nexttile(layout);
    imagesc(ax, displayImage);
    axis(ax, "image");
    colormap(ax, gray(256));
    clim(ax, [0 1]);
    colorbarHandle = colorbar(ax);
    astro_display_colorbar(colorbarHandle, intensityLimits, ...
        softeningFraction, unitLabel, lightForeground);
    title(ax, sprintf("%s | scientific intensity | %s", ...
        upper(datasetName), sourceLabel), ...
        "Color", lightForeground, "FontSize", 16, "FontWeight", "bold");
    xlabel(ax, "Pixel column");
    ylabel(ax, "Pixel row");
    exportgraphics(fig, fullfile(outputFolder, ...
        "scientific_intensity.png"), "Resolution", 300);
    close(fig);

    fig = figure("Visible", "off", "Color", darkBackground, ...
        "Position", [80 60 1500 1120]);
    set(fig, "DefaultAxesColor", darkBackground, ...
        "DefaultAxesXColor", lightForeground, ...
        "DefaultAxesYColor", lightForeground, ...
        "DefaultAxesFontName", "Calibri", "DefaultAxesFontSize", 12, ...
        "DefaultTextFontName", "Calibri");
    layout = tiledlayout(fig, 1, 1, ...
        "Padding", "compact", "TileSpacing", "compact");
    ax = nexttile(layout);
    imagesc(ax, displayImage);
    axis(ax, "image");
    colormap(ax, astro_falsecolor_map(256));
    clim(ax, [0 1]);
    colorbarHandle = colorbar(ax);
    astro_display_colorbar(colorbarHandle, intensityLimits, ...
        softeningFraction, unitLabel, lightForeground);
    title(ax, sprintf("%s | single-image false colour | %s", ...
        upper(datasetName), sourceLabel), ...
        "Color", lightForeground, "FontSize", 16, "FontWeight", "bold");
    xlabel(ax, "Pixel column");
    ylabel(ax, "Pixel row");
    annotation(fig, "textbox", [0.08 0.025 0.84 0.045], ...
        "String", "Single-filter false colour; hue is intensity, not true astronomical RGB.", ...
        "Color", lightForeground, "FontSize", 10, "EdgeColor", "none", ...
        "HorizontalAlignment", "center");
    exportgraphics(fig, fullfile(outputFolder, ...
        "single_image_false_color.png"), "Resolution", 300);
    close(fig);

    fprintf("%s visualization saved:\n", upper(datasetName));
    fprintf("  %s\n", fullfile(outputFolder, "scientific_intensity.png"));
    fprintf("  %s\n", fullfile(outputFolder, "single_image_false_color.png"));
    fprintf("  asinh intensity limits: [%.6g, %.6g] %s\n", ...
        intensityLimits(1), intensityLimits(2), unitLabel);
end
