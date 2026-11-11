%% AstroLink - Unit 4: scientific and pseudocolour display
% The colormap and asinh stretch are display-only. Pseudocolour maps one
% intensity image to a palette; it is not true astronomical RGB.

clc;
clear;
close all;

scriptPath = string(mfilename("fullpath"));
unit4Folder = fileparts(scriptPath);
projectRoot = fileparts(unit4Folder);
unit1Folder = fullfile(projectRoot, "unit1");
addpath(unit1Folder);

datasets = ["orion", "m51"];
% The same finite-pixel percentile policy and softening fraction are used
% for both datasets. Negative values (present in M51) remain in the science
% array and are handled by the shared asinh display mapping.
percentiles = [1 99.7];
softeningFraction = 0.02;
darkBackground = [0.008 0.012 0.025];
lightForeground = [0.93 0.95 0.98];

for datasetName = datasets
    % Preserve the FITS science values; this helper returns a separate
    % display copy and the source-intensity limits used by its colorbar.
    scienceImage = double(load_sci_image(datasetName));
    [displayImage, intensityLimits] = astro_display_stretch( ...
        scienceImage, [], percentiles, softeningFraction);
    switch datasetName
        case "orion"
            intensityUnit = "COUNTS/S";
            sourceName = "HST WFPC2 drizzled SCI, F658N";
        case "m51"
            intensityUnit = "ELECTRONS";
            sourceName = "HST ACS drizzled primary, F435W";
    end
    outputFolder = fullfile(projectRoot, "results", "unit4", datasetName);
    if ~isfolder(outputFolder)
        mkdir(outputFolder);
    end

    % Scientific intensity view: grayscale makes brightness easy to read,
    % while the colorbar maps the stretched display back to source units.
    fig = figure("Visible", "off", "Color", darkBackground, ...
        "Position", [80 60 1500 1120]);
    layout = tiledlayout(fig, 1, 1, ...
        "Padding", "compact", "TileSpacing", "compact");
    ax = nexttile(layout);
    imagesc(ax, displayImage, [0 1]);
    axis(ax, "image");
    colormap(ax, gray(256));
    ax.Color = darkBackground;
    ax.XColor = lightForeground;
    ax.YColor = lightForeground;
    title(ax, sprintf("%s | scientific intensity | %s", ...
        upper(datasetName), sourceName), "Color", lightForeground, ...
        "FontSize", 16, "FontWeight", "bold");
    xlabel(ax, "Pixel column");
    ylabel(ax, "Pixel row");
    cb = colorbar(ax);
    astro_display_colorbar(cb, intensityLimits, ...
        softeningFraction, intensityUnit, lightForeground);
    exportgraphics(fig, fullfile(outputFolder, ...
        "scientific_intensity.png"), "Resolution", 300);
    close(fig);

    % Pseudocolour view uses that exact same display copy and limits. It
    % assigns palette hues to one filter's intensity; it does not combine
    % channels or represent physical RGB colour.
    fig = figure("Visible", "off", "Color", darkBackground, ...
        "Position", [80 60 1500 1120]);
    layout = tiledlayout(fig, 1, 1, ...
        "Padding", "compact", "TileSpacing", "compact");
    ax = nexttile(layout);
    imagesc(ax, displayImage, [0 1]);
    axis(ax, "image");
    colormap(ax, astro_falsecolor_map(256));
    ax.Color = darkBackground;
    ax.XColor = lightForeground;
    ax.YColor = lightForeground;
    title(ax, sprintf("%s | single-image pseudocolour | %s", ...
        upper(datasetName), sourceName), "Color", lightForeground, ...
        "FontSize", 16, "FontWeight", "bold");
    xlabel(ax, "Pixel column");
    ylabel(ax, "Pixel row");
    cb = colorbar(ax);
    astro_display_colorbar(cb, intensityLimits, ...
        softeningFraction, intensityUnit, lightForeground);
    annotation(fig, "textbox", [0.08 0.025 0.84 0.045], ...
        "String", "Pseudocolour encodes one filter's intensity; this is not true astronomical RGB.", ...
        "Color", lightForeground, "FontSize", 10, ...
        "EdgeColor", "none", "HorizontalAlignment", "center");
    exportgraphics(fig, fullfile(outputFolder, ...
        "single_image_pseudocolour.png"), "Resolution", 300);
    close(fig);

    fprintf("%s pseudocolour outputs:\n", upper(datasetName));
    fprintf("  %s\n", fullfile(outputFolder, "scientific_intensity.png"));
    fprintf("  %s\n", fullfile(outputFolder, "single_image_pseudocolour.png"));
end
