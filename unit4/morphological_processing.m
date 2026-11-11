%% AstroLink - Unit 4: threshold-derived region masks
% This demonstration uses a percentile threshold on original intensities.
% It is an illustrative region mask, not validated star/nebula segmentation.
% Morphology changes only the binary mask, not the science-image array.

clc;
clear;
close all;

scriptPath = string(mfilename("fullpath"));
unit4Folder = fileparts(scriptPath);
projectRoot = fileparts(unit4Folder);
unit1Folder = fullfile(projectRoot, "unit1");
addpath(unit1Folder);

requiredFunctions = ["strel", "imerode", "imdilate", "imopen", ...
    "imclose", "bwconncomp", "bwlabel", "label2rgb"];
if ~license("test", "image_toolbox")
    error("Image Processing Toolbox license is required for morphology.");
end
for functionName = requiredFunctions
    if exist(functionName, "file") == 0 && exist(functionName, "builtin") == 0
        error("Required Image Processing Toolbox function '%s' is unavailable.", ...
            functionName);
    end
end

datasets = ["orion", "m51"];
% Select the upper 15% of finite pixel intensities to form an illustrative
% bright-region mask. This empirical threshold is not a physical boundary.
thresholdPercentile = 85;
softeningFraction = 0.02;
darkBackground = [0.008 0.012 0.025];
lightForeground = [0.93 0.95 0.98];
falseColorMap = astro_falsecolor_map(256);
maskMap = [darkBackground; 0.98 0.88 0.58];

for datasetName = datasets
    % Keep the science image separate from this logical mask. Non-finite
    % samples are excluded rather than being treated as bright regions.
    scienceImage = double(load_sci_image(datasetName));
    finiteValues = scienceImage(isfinite(scienceImage));
    thresholdValue = percentileValue(finiteValues, thresholdPercentile);
    if ~isfinite(thresholdValue)
        error("No finite science pixels are available for %s.", datasetName);
    end
    workingMask = isfinite(scienceImage) & scienceImage >= thresholdValue;

    % A radius-one disk is a compact 3-by-3 neighborhood. Erosion shrinks
    % mask regions; dilation expands them. Opening (erosion then dilation)
    % removes small protrusions, while closing (dilation then erosion)
    % fills small gaps. These operations act on the binary mask only.
    structuringElement = strel("disk", 1, 0);
    erodedMask = imerode(workingMask, structuringElement);
    dilatedMask = imdilate(workingMask, structuringElement);
    openedMask = imopen(workingMask, structuringElement);
    closedMask = imclose(workingMask, structuringElement);

    % Stretch only the image panel for legibility. The threshold and all
    % morphology operations above use un-stretched science intensities.
    [originalDisplay, intensityLimits] = astro_display_stretch( ...
        scienceImage, [], [1 99.7], softeningFraction);
    switch datasetName
        case "orion"
            intensityUnit = "COUNTS/S";
            sourceName = "WFPC2 F658N";
        case "m51"
            intensityUnit = "ELECTRONS";
            sourceName = "ACS F435W";
    end
    outputFolder = fullfile(projectRoot, "results", "unit4", datasetName);
    if ~isfolder(outputFolder)
        mkdir(outputFolder);
    end

    fig = figure("Visible", "off", "Color", darkBackground, ...
        "Position", [50 80 1600 1000]);
    tiledlayout(fig, 2, 3, "Padding", "compact", ...
        "TileSpacing", "compact");

    axesHandle = nexttile;
    imagesc(axesHandle, originalDisplay, [0 1]);
    axis(axesHandle, "image");
    colormap(axesHandle, falseColorMap);
    styleAxes(axesHandle, darkBackground, lightForeground);
    title(axesHandle, "Original | asinh display", "Color", lightForeground);
    cb = colorbar(axesHandle);
    astro_display_colorbar(cb, intensityLimits, softeningFraction, ...
        intensityUnit, lightForeground);

    % Display the starting mask and each operation separately to make the
    % effect of erosion, dilation, opening, and closing easy to compare.
    masks = {workingMask, erodedMask, dilatedMask, openedMask, closedMask};
    maskNames = ["Threshold region mask"; "Erosion"; "Dilation"; ...
        "Opening"; "Closing"];
    for panelIndex = 1:numel(masks)
        ax = nexttile;
        imagesc(ax, masks{panelIndex}, [0 1]);
        axis(ax, "image");
        colormap(ax, maskMap);
        styleAxes(ax, darkBackground, lightForeground);
        title(ax, maskNames(panelIndex), "Color", lightForeground);
        cb = colorbar(ax);
        cb.Ticks = [0 1];
        cb.TickLabels = ["background", "region"];
        cb.Color = lightForeground;
        cb.Label.String = "Binary mask class";
        cb.Label.Color = lightForeground;
    end

    sgtitle(fig, sprintf("%s | threshold-derived region mask | %s", ...
        upper(datasetName), sourceName), "Color", lightForeground, ...
        "FontSize", 15, "FontWeight", "bold");
    annotation(fig, "textbox", [0.04 0.005 0.92 0.035], ...
        "String", sprintf("Threshold = %.5g %s (%.0fth percentile); disk structuring element radius 1 pixel. Mask is illustrative, not validated astronomical segmentation.", ...
        thresholdValue, intensityUnit, thresholdPercentile), ...
        "Color", lightForeground, "FontSize", 9, ...
        "EdgeColor", "none", "HorizontalAlignment", "center");
    exportgraphics(fig, fullfile(outputFolder, ...
        "morphology_masks.png"), "Resolution", 180);
    close(fig);

    % Eight-connectivity counts diagonal touching pixels as one component.
    % Labeling assigns colors for visualization only; it does not rank or
    % reject components, so small stars are not automatically called noise.
    openedComponents = bwconncomp(openedMask, 8);
    closedComponents = bwconncomp(closedMask, 8);
    openedLabels = bwlabel(openedMask, 8);
    closedLabels = bwlabel(closedMask, 8);
    openedRgb = label2rgb(openedLabels, "lines", darkBackground, "shuffle");
    closedRgb = label2rgb(closedLabels, "lines", darkBackground, "shuffle");

    fig = figure("Visible", "off", "Color", darkBackground, ...
        "Position", [80 100 1250 620]);
    tiledlayout(fig, 1, 2, "Padding", "compact", ...
        "TileSpacing", "compact");
    ax = nexttile;
    image(ax, openedRgb);
    axis(ax, "image");
    styleAxes(ax, darkBackground, lightForeground);
    title(ax, sprintf("Opened mask | %d components (8-connected)", ...
        openedComponents.NumObjects), "Color", lightForeground);
    xlabel(ax, "Pixel column");
    ylabel(ax, "Pixel row");
    ax = nexttile;
    image(ax, closedRgb);
    axis(ax, "image");
    styleAxes(ax, darkBackground, lightForeground);
    title(ax, sprintf("Closed mask | %d components (8-connected)", ...
        closedComponents.NumObjects), "Color", lightForeground);
    xlabel(ax, "Pixel column");
    ylabel(ax, "Pixel row");
    sgtitle(fig, sprintf("%s | connected regions after morphology", ...
        upper(datasetName)), "Color", lightForeground, ...
        "FontSize", 15, "FontWeight", "bold");
    annotation(fig, "textbox", [0.05 0.005 0.90 0.035], ...
        "String", "Each connected region is assigned a display colour; no components are automatically discarded or classified as noise.", ...
        "Color", lightForeground, "FontSize", 9, ...
        "EdgeColor", "none", "HorizontalAlignment", "center");
    exportgraphics(fig, fullfile(outputFolder, ...
        "morphology_components.png"), "Resolution", 180);
    close(fig);

    fprintf("%s morphology outputs:\n", upper(datasetName));
    fprintf("  %s\n", fullfile(outputFolder, "morphology_masks.png"));
    fprintf("  %s\n", fullfile(outputFolder, "morphology_components.png"));
    fprintf("  threshold %.6g %s; opened %d, closed %d components\n", ...
        thresholdValue, intensityUnit, openedComponents.NumObjects, ...
        closedComponents.NumObjects);
end

function value = percentileValue(values, percentile)
% Compute a linearly interpolated percentile without requiring another toolbox.
values = sort(values(isfinite(values)));
if isempty(values)
    value = NaN;
    return;
end
position = (percentile / 100) * (numel(values) - 1) + 1;
lowerIndex = floor(position);
upperIndex = ceil(position);
fraction = position - lowerIndex;
value = values(lowerIndex) + fraction * ...
    (values(upperIndex) - values(lowerIndex));
end

function styleAxes(ax, background, foreground)
% Keep axis styling consistent across the original and binary-mask panels.
ax.Color = background;
ax.XColor = foreground;
ax.YColor = foreground;
ax.FontName = "Calibri";
ax.FontSize = 10;
xlabel(ax, "Pixel column");
ylabel(ax, "Pixel row");
end
