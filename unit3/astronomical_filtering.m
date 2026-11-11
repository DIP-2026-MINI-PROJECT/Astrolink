%% AstroLink - Unit 3: spatial and frequency-domain low-pass filters
% Each dataset uses its central 512-by-512 science-image crop. Filtering
% changes only working copies for this comparison, never the FITS source.
% Low-pass filters suppress high-frequency detail as well as some noise;
% noise has not been independently characterized or claimed to be removed.

clc;
clear;
close all;

scriptPath = string(mfilename("fullpath"));
unit3Folder = fileparts(scriptPath);
projectRoot = fileparts(unit3Folder);
unit1Folder = fullfile(projectRoot, "unit1");
addpath(unit1Folder);

requiredFunctions = ["imfilter", "medfilt2", "fspecial"];
if ~license("test", "image_toolbox")
    error("Image Processing Toolbox license is required for spatial filtering.");
end
% Fail explicitly before loading large images if a required toolbox
% function is missing from this MATLAB installation.
for functionName = requiredFunctions
    if exist(functionName, "file") == 0 && exist(functionName, "builtin") == 0
        error("Required Image Processing Toolbox function '%s' is unavailable.", ...
            functionName);
    end
end

datasets = ["orion", "m51"];
% Identical crop dimensions make the visual comparison straightforward.
% These are working copies: neither filtering nor the plots overwrite FITS.
cropSize = 512;
% Gaussian width controls blur; the odd kernel reaches about 3 sigma on
% each side. The median window is deliberately only 3 by 3 pixels.
spatialSigma = 1.2;
medianWindow = [3 3];
% D0 is the radial cutoff in cycles/pixel. The Butterworth order controls
% transition sharpness; no hard cutoff/ideal response is used.
frequencyCutoff = 0.08; % cycles/pixel
butterworthOrder = 2;
percentiles = [1 99.7];
softeningFraction = 0.02;
darkBackground = [0.008 0.012 0.025];
lightForeground = [0.93 0.95 0.98];
falseColorMap = astro_falsecolor_map(256);
differenceMap = blueWhiteRedMap(257);

for datasetName = datasets
    scienceImage = double(load_sci_image(datasetName));
    [rows, columns] = size(scienceImage);
    % Extract a central crop, clipping the crop bounds for images smaller
    % than the requested size. All four filters receive this same region.
    cropRows = max(1, floor((rows - cropSize) / 2) + 1): ...
        min(rows, floor((rows - cropSize) / 2) + cropSize);
    cropColumns = max(1, floor((columns - cropSize) / 2) + 1): ...
        min(columns, floor((columns - cropSize) / 2) + cropSize);
    original = scienceImage(cropRows, cropColumns);

    % Spatial Gaussian: a normalized Gaussian neighborhood replaces each
    % pixel with a local weighted average. Replicate padding avoids an
    % artificial zero-valued border in this spatial-domain result.
    gaussianKernelSize = 2 * ceil(3 * spatialSigma) + 1;
    gaussianKernel = fspecial("gaussian", gaussianKernelSize, spatialSigma);
    gaussianSpatial = imfilter(original, gaussianKernel, "replicate", "same");
    % Median filtering selects the neighborhood median instead of averaging.
    % Symmetric padding reflects values at the crop boundary.
    medianSpatial = medfilt2(original, medianWindow, "symmetric");

    % Build frequency coordinates in cycles/pixel around zero frequency.
    % hypot gives radial distance D(u,v), so each response is circularly
    % symmetric and depends only on distance from the frequency origin.
    [cropRowsCount, cropColumnsCount] = size(original);
    frequencyY = (-floor(cropRowsCount / 2): ...
        ceil(cropRowsCount / 2) - 1) / cropRowsCount;
    frequencyX = (-floor(cropColumnsCount / 2): ...
        ceil(cropColumnsCount / 2) - 1) / cropColumnsCount;
    [frequencyGridX, frequencyGridY] = meshgrid(frequencyX, frequencyY);
    radialFrequency = hypot(frequencyGridX, frequencyGridY);
    % Gaussian low-pass response H(D)=exp(-D^2/(2 D0^2)); high frequencies
    % are smoothly attenuated rather than abruptly removed.
    gaussianTransfer = exp(-(radialFrequency .^ 2) / ...
        (2 * frequencyCutoff ^ 2));
    % Butterworth response H(D)=1/(1+(D/D0)^(2n)); n sets its roll-off.
    butterworthTransfer = 1 ./ (1 + ...
        (radialFrequency / frequencyCutoff) .^ (2 * butterworthOrder));

    % The shared helper applies each centered response to the unshifted FFT.
    % It returns the real image after inverse transformation.
    gaussianFrequency = inverseCenteredFilter(original, gaussianTransfer);
    butterworthFrequency = inverseCenteredFilter(original, butterworthTransfer);

    filteredImages = {gaussianSpatial, medianSpatial, ...
        gaussianFrequency, butterworthFrequency};
    filterNames = ["Gaussian spatial"; "Median spatial"; ...
        "Gaussian frequency low-pass"; "Butterworth frequency low-pass"];
    % Derive one display mapping from the unfiltered crop and reuse it for
    % every panel. This avoids mistaking independent autoscaling for a filter
    % effect; filtering itself operates on the original intensity values.
    [originalDisplay, intensityLimits] = astro_display_stretch( ...
        original, [], percentiles, softeningFraction);

    switch datasetName
        case "orion"
            intensityUnit = "COUNTS/S";
        case "m51"
            intensityUnit = "ELECTRONS";
    end
    outputFolder = fullfile(projectRoot, "results", "unit3", datasetName);
    if ~isfolder(outputFolder)
        mkdir(outputFolder);
    end

    fig = figure("Visible", "off", "Color", darkBackground, ...
        "Position", [50 100 1850 610]);
    tiledlayout(fig, 1, 5, "Padding", "compact", ...
        "TileSpacing", "compact");
    comparisonImages = [{original}, filteredImages];
    comparisonNames = ["Original crop"; filterNames];
    for panelIndex = 1:numel(comparisonImages)
        ax = nexttile;
        panelDisplay = astro_display_stretch(comparisonImages{panelIndex}, ...
            intensityLimits, percentiles, softeningFraction);
        imagesc(ax, panelDisplay, [0 1]);
        axis(ax, "image");
        colormap(ax, falseColorMap);
        ax.Color = darkBackground;
        ax.XColor = lightForeground;
        ax.YColor = lightForeground;
        title(ax, comparisonNames(panelIndex), ...
            "Color", lightForeground, "FontSize", 11);
        xlabel(ax, "Column");
        ylabel(ax, "Row");
        cb = colorbar(ax);
        astro_display_colorbar(cb, intensityLimits, ...
            softeningFraction, intensityUnit, lightForeground);
    end
    sgtitle(fig, sprintf("%s | low-pass filter comparison | central %d x %d pixels", ...
        upper(datasetName), size(original, 1), size(original, 2)), ...
        "Color", lightForeground, "FontSize", 15, "FontWeight", "bold");
    annotation(fig, "textbox", [0.03 0.005 0.94 0.035], ...
        "String", sprintf("Spatial Gaussian sigma=%.1f px; median=%d x %d; frequency cutoff=%.3g cycles/pixel; Butterworth order=%d. Low-pass filtering also suppresses high-frequency structure.", ...
        spatialSigma, medianWindow(1), medianWindow(2), ...
        frequencyCutoff, butterworthOrder), ...
        "Color", lightForeground, "FontSize", 9, ...
        "EdgeColor", "none", "HorizontalAlignment", "center");
    exportgraphics(fig, fullfile(outputFolder, ...
        "filter_comparison.png"), "Resolution", 180);
    close(fig);

    % Signed filter-minus-original differences show what changed. Use a
    % shared symmetric limit so positive and negative changes are comparable.
    differences = cell(size(filteredImages));
    maximumDifference = 0;
    for filterIndex = 1:numel(filteredImages)
        differences{filterIndex} = filteredImages{filterIndex} - original;
        maximumDifference = max(maximumDifference, ...
            percentileValue(abs(differences{filterIndex}(:)), 99.5));
    end
    if ~isfinite(maximumDifference) || maximumDifference <= 0
        maximumDifference = eps;
    end

    fig = figure("Visible", "off", "Color", darkBackground, ...
        "Position", [50 100 1850 610]);
    tiledlayout(fig, 1, 4, "Padding", "compact", ...
        "TileSpacing", "compact");
    for filterIndex = 1:numel(differences)
        ax = nexttile;
        imagesc(ax, differences{filterIndex}, ...
            [-maximumDifference maximumDifference]);
        axis(ax, "image");
        colormap(ax, differenceMap);
        ax.Color = darkBackground;
        ax.XColor = lightForeground;
        ax.YColor = lightForeground;
        title(ax, filterNames(filterIndex) + " - original", ...
            "Color", lightForeground, "FontSize", 11);
        xlabel(ax, "Column");
        ylabel(ax, "Row");
        cb = colorbar(ax);
        cb.Color = lightForeground;
        cb.Label.String = sprintf("Difference (%s)", intensityUnit);
        cb.Label.Color = lightForeground;
        cb.FontSize = 8;
    end
    sgtitle(fig, sprintf("%s | signed filter differences | common symmetric scale", ...
        upper(datasetName)), "Color", lightForeground, ...
        "FontSize", 15, "FontWeight", "bold");
    exportgraphics(fig, fullfile(outputFolder, ...
        "filter_differences.png"), "Resolution", 180);
    close(fig);

    fprintf("%s filtering outputs:\n", upper(datasetName));
    fprintf("  %s\n", fullfile(outputFolder, "filter_comparison.png"));
    fprintf("  %s\n", fullfile(outputFolder, "filter_differences.png"));
    fprintf("  crop rows %d-%d, columns %d-%d; max filtered change %.6g %s\n", ...
        cropRows(1), cropRows(end), cropColumns(1), cropColumns(end), ...
        max(cellfun(@(image) max(abs(image(:) - original(:))), filteredImages)), ...
        intensityUnit);
end

function filteredImage = inverseCenteredFilter(image, centeredTransfer)
% The transfer function was built with zero frequency at its center, while
% fft2 stores zero frequency at the array origin. ifftshift aligns them.
% Multiplication in frequency space is circular convolution in the image,
% so the frequency-domain results have periodic boundary assumptions.
filteredComplex = ifft2(fft2(image) .* ifftshift(centeredTransfer));
% A real input and symmetric real response should yield a real result;
% discard only numerical round-off in the inverse FFT's imaginary part.
filteredImage = real(filteredComplex);
end

function value = percentileValue(values, percentile)
% Toolbox-independent, linearly interpolated percentile for difference limits.
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

function colorMap = blueWhiteRedMap(count)
blue = [0.12 0.38 0.78];
white = [0.96 0.96 0.94];
red = [0.78 0.16 0.18];
colorMap = interp1([-1 0 1], [blue; white; red], ...
    linspace(-1, 1, count), "linear");
end
