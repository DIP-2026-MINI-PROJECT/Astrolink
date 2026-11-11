%% AstroLink - Unit 2: Block-based DCT demonstration
% This demonstration applies the existing 8-by-8 DCT coefficient
% quantization to the original science arrays. Display stretches below
% are separate copies and never replace the scientific arrays.

clc;
clear;
close all;

scriptPath = string(mfilename("fullpath"));
projectRoot = fileparts(fileparts(scriptPath));
addpath(fullfile(projectRoot, "unit1"));
datasets = ["orion", "m51"];
blockSize = 8;
quantizationStep = 2; % Retain the existing default quantization step.
percentiles = [1 99.7];
softeningFraction = 0.02;
darkBg = [0.07 0.08 0.10];
lightFg = [0.93 0.94 0.96];
midFg = [0.62 0.65 0.70];

for datasetName = datasets
    scienceImage = double(load_sci_image(datasetName));
    [rows, cols] = size(scienceImage);

    % Pad with zeros at the bottom/right, transform each 8-by-8 block,
    % quantize using the original rule, inverse transform, and crop.
    paddedRows = ceil(rows / blockSize) * blockSize;
    paddedCols = ceil(cols / blockSize) * blockSize;
    paddedImage = zeros(paddedRows, paddedCols);
    paddedImage(1:rows, 1:cols) = scienceImage;
    dctImage = zeros(paddedRows, paddedCols);
    for blockRow = 1:blockSize:paddedRows
        for blockCol = 1:blockSize:paddedCols
            rr = blockRow:blockRow+blockSize-1;
            cc = blockCol:blockCol+blockSize-1;
            dctImage(rr, cc) = dct2(paddedImage(rr, cc));
        end
    end
    quantizedDct = round(dctImage / quantizationStep) * quantizationStep;
    reconstructedPadded = zeros(paddedRows, paddedCols);
    for blockRow = 1:blockSize:paddedRows
        for blockCol = 1:blockSize:paddedCols
            rr = blockRow:blockRow+blockSize-1;
            cc = blockCol:blockCol+blockSize-1;
            reconstructedPadded(rr, cc) = idct2(quantizedDct(rr, cc));
        end
    end
    reconstructedImage = reconstructedPadded(1:rows, 1:cols);
    differenceImage = reconstructedImage - scienceImage;

    % One original-derived asinh mapping is shared by both display copies.
    [originalDisplay, displayLimits] = astro_display_stretch( ...
        scienceImage, [], percentiles, softeningFraction);
    reconstructedDisplay = astro_display_stretch(reconstructedImage, ...
        displayLimits, percentiles, softeningFraction);
    if datasetName == "orion"
        intensityUnit = "COUNTS/S";
    else
        intensityUnit = "ELECTRONS";
    end

    [~, maxIndex] = max(scienceImage(:));
    [maxRow, maxCol] = ind2sub(size(scienceImage), maxIndex);
    blockRow = min(floor((maxRow - 1) / blockSize) * blockSize + 1, ...
        max(1, rows - blockSize + 1));
    blockCol = min(floor((maxCol - 1) / blockSize) * blockSize + 1, ...
        max(1, cols - blockSize + 1));
    representativeBlock = zeros(blockSize, blockSize);
    availableRows = min(blockSize, rows - blockRow + 1);
    availableCols = min(blockSize, cols - blockCol + 1);
    representativeBlock(1:availableRows, 1:availableCols) = ...
        scienceImage(blockRow:blockRow+availableRows-1, ...
        blockCol:blockCol+availableCols-1);
    representativeDct = dct2(representativeBlock);
    magnitudeLog = log1p(abs(dctImage));
    magnitudeLimits = [0, max(magnitudeLog(:))];
    if magnitudeLimits(2) <= 0, magnitudeLimits(2) = 1; end
    outputFolder = fullfile(projectRoot, "results", ...
        "astronomical_visualization", "dct");
    if ~isfolder(outputFolder), mkdir(outputFolder); end
    fig = figure("Visible", "off", "Color", darkBg, ...
        "Position", [80 80 1450 900]);
    set(fig, "DefaultAxesFontName", "Calibri", "DefaultAxesFontSize", 10, ...
        "DefaultAxesColor", darkBg, "DefaultAxesXColor", lightFg, ...
        "DefaultAxesYColor", lightFg, "DefaultTextFontName", "Calibri");
    tiledlayout(2, 2, "Padding", "compact", "TileSpacing", "compact");

    ax = nexttile;
    imagesc(originalDisplay, [0 1]);
    axis image; colormap(ax, astro_falsecolor_map(256));
    cb = colorbar; styleColorbar(cb, lightFg, "science intensity (COUNTS/S)");
    astro_display_colorbar(cb, displayLimits, softeningFraction, ...
        intensityUnit, lightFg);
    title("Original | single-image false colour", "Color", lightFg);
    xlabel("column"); ylabel("row");

    ax = nexttile;
    imagesc(reconstructedDisplay, [0 1]);
    axis image; colormap(ax, astro_falsecolor_map(256));
    title(sprintf("Reconstructed after coefficient quantization (step %.4g)", ...
        quantizationStep), "Color", lightFg);
    xlabel("column"); ylabel("row");

    ax = nexttile;
    imagesc(representativeDct);
    axis image; colormap(ax, divergingMap(256));
    clim(max(abs(representativeDct(:))) * [-1 1] + ...
        (max(abs(representativeDct(:))) == 0) * [-1 1]);
    cb = colorbar; styleColorbar(cb, lightFg, "signed DCT coefficient");
    set(gca, "XTick", 1:blockSize, "YTick", 1:blockSize);
    title(sprintf("Signed DCT coefficients: representative 8 x 8 block (%d,%d)", ...
        blockRow, blockCol), "Color", lightFg);
    xlabel("frequency index u"); ylabel("frequency index v");

    ax = nexttile;
    imagesc(magnitudeLog, magnitudeLimits);
    axis image; colormap(ax, parula(256));
    cb = colorbar; styleColorbar(cb, lightFg, "log(1 + |DCT coefficient|)");
    title("Whole-image coefficient magnitude (log display)", "Color", lightFg);
    xlabel("block-frequency column"); ylabel("block-frequency row");

    sgtitle(sprintf("%s | 8 x 8 block DCT and quantization", upper(datasetName)), ...
        "Color", lightFg, "FontSize", 15, "FontWeight", "bold");
    annotation("textbox", [0.04 0.005 0.92 0.035], ...
        "String", sprintf(char("Original and reconstruction share the original-derived asinh limits [%.4g, %.4g] %s. " + ...
        "False colour represents one intensity image, not RGB; DCT uses unmodified science values."), ...
        displayLimits(1), displayLimits(2), intensityUnit), ...
        "Color", midFg, "FontSize", 9, "EdgeColor", "none", ...
        "HorizontalAlignment", "center");
    outputName = sprintf("%s_dct_compression.png", datasetName);
    exportgraphics(fig, fullfile(outputFolder, outputName), ...
        "Resolution", 175);
    close(fig);

    fprintf("%s block DCT demonstration\n", upper(datasetName));
    fprintf("  dimensions: %d x %d pixels\n", rows, cols);
    fprintf("  blocks: %d x %d = %d\n", paddedRows / blockSize, ...
        paddedCols / blockSize, (paddedRows / blockSize) * (paddedCols / blockSize));
    fprintf("  padding: %d rows, %d columns\n", paddedRows - rows, paddedCols - cols);
    fprintf("  quantization step: %.4g %s\n", quantizationStep, intensityUnit);
    fprintf("  maximum absolute reconstruction difference: %.6g %s\n", ...
        max(abs(differenceImage(:))), intensityUnit);
    fprintf("  figure: %s\n\n", fullfile(outputFolder, outputName));
end

function cmap = divergingMap(count)
% Blue-white-red map: zero is white, negative/positive are distinct.
halfCount = floor(count / 2);
blue = [0.16 0.42 0.78];
white = [0.96 0.96 0.94];
red = [0.80 0.22 0.18];
left = [linspace(blue(1), white(1), halfCount)', ...
    linspace(blue(2), white(2), halfCount)', ...
    linspace(blue(3), white(3), halfCount)'];
rightCount = count - halfCount;
right = [linspace(white(1), red(1), rightCount)', ...
    linspace(white(2), red(2), rightCount)', ...
    linspace(white(3), red(3), rightCount)'];
cmap = [left; right(2:end, :)];
end

function styleColorbar(cb, textColor, labelText)
cb.Color = textColor;
cb.FontSize = 9;
cb.Label.String = labelText;
cb.Label.Color = textColor;
end
