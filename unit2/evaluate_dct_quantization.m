%% AstroLink - Evaluate block DCT reconstruction across quantization steps
% The DCT is computed once per dataset. Each step then uses the project's
% existing uniform coefficient rule: round(C / step) * step. Metrics are
% calculated from scientific arrays; only the comparison figure is stretched.

clc;
clear;
close all;

scriptPath = string(mfilename("fullpath"));
projectRoot = fileparts(fileparts(scriptPath));
addpath(fullfile(projectRoot, "unit1"));
datasets = ["orion", "m51"];
quantizationSteps = [1, 2, 4];
blockSize = 8;
percentiles = [1 99.7];
softeningFraction = 0.02;
darkBg = [0.07 0.08 0.10];
lightFg = [0.93 0.94 0.96];
rowCount = numel(datasets) * numel(quantizationSteps);
datasetColumn = strings(rowCount, 1);
stepColumn = zeros(rowCount, 1);
rmseColumn = zeros(rowCount, 1);
maxErrorColumn = zeros(rowCount, 1);
row = 0;
outputFolder = fullfile(projectRoot, "results", ...
    "astronomical_visualization", "dct_evaluation");
if ~isfolder(outputFolder), mkdir(outputFolder); end

for datasetName = datasets
    scienceImage = double(load_sci_image(datasetName));
    [rows, cols] = size(scienceImage);
    paddedRows = ceil(rows / blockSize) * blockSize;
    paddedCols = ceil(cols / blockSize) * blockSize;
    paddedImage = zeros(paddedRows, paddedCols);
    paddedImage(1:rows, 1:cols) = scienceImage;

    % Forward transform follows the same 8-by-8 block processing as the demo.
    dctImage = zeros(paddedRows, paddedCols);
    for blockRow = 1:blockSize:paddedRows
        for blockCol = 1:blockSize:paddedCols
            rr = blockRow:blockRow+blockSize-1;
            cc = blockCol:blockCol+blockSize-1;
            dctImage(rr, cc) = dct2(paddedImage(rr, cc));
        end
    end

    [originalDisplay, limits] = astro_display_stretch( ...
        scienceImage, [], percentiles, softeningFraction);
    if datasetName == "orion"
        intensityUnit = "COUNTS/S";
    else
        intensityUnit = "ELECTRONS";
    end

    fig = figure("Visible", "off", "Color", darkBg, ...
        "Position", [80 80 1500 950]);
    set(fig, "DefaultAxesFontName", "Calibri", "DefaultAxesFontSize", 10, ...
        "DefaultAxesColor", darkBg, "DefaultAxesXColor", lightFg, ...
        "DefaultAxesYColor", lightFg, "DefaultTextFontName", "Calibri");
    tiledlayout(2, 3, "Padding", "compact", "TileSpacing", "compact");

    ax = nexttile;
    imagesc(originalDisplay, [0 1]);
    axis image; colormap(ax, astro_falsecolor_map(256));
    cb = colorbar; cb.Color = lightFg;
    astro_display_colorbar(cb, limits, softeningFraction, ...
        intensityUnit, lightFg);
    title("Original | single-image false colour", "Color", lightFg);
    xlabel("column"); ylabel("row");

    for stepIndex = 1:numel(quantizationSteps)
        step = quantizationSteps(stepIndex);
        quantizedDct = round(dctImage / step) * step;
        reconstructedPadded = zeros(paddedRows, paddedCols);
        for blockRow = 1:blockSize:paddedRows
            for blockCol = 1:blockSize:paddedCols
                rr = blockRow:blockRow+blockSize-1;
                cc = blockCol:blockCol+blockSize-1;
                reconstructedPadded(rr, cc) = ...
                    idct2(quantizedDct(rr, cc));
            end
        end
        reconstructed = reconstructedPadded(1:rows, 1:cols);
        reconstructedDisplay = astro_display_stretch(reconstructed, ...
            limits, percentiles, softeningFraction);
        difference = reconstructed - scienceImage;
        row = row + 1;
        datasetColumn(row) = datasetName;
        stepColumn(row) = step;
        rmseColumn(row) = sqrt(mean(difference(:).^2));
        maxErrorColumn(row) = max(abs(difference(:)));

        ax = nexttile;
        imagesc(reconstructedDisplay, [0 1]);
        axis image; colormap(ax, astro_falsecolor_map(256));
        title(sprintf("Reconstruction | step = %.4g", step), ...
            "Color", lightFg);
        xlabel("column"); ylabel("row");
    end

    sgtitle(sprintf("%s | DCT quantization step comparison", ...
        upper(datasetName)), "Color", lightFg, ...
        "FontSize", 15, "FontWeight", "bold");
    annotation("textbox", [0.04 0.005 0.92 0.035], ...
        "String", sprintf(char("All panels share the original-derived asinh limits [%.4g, %.4g] %s. " + ...
        "False colour is single-image display only; metrics use original scientific values."), ...
        limits(1), limits(2), intensityUnit), ...
        "Color", [0.62 0.65 0.70], "FontSize", 9, ...
        "EdgeColor", "none", "HorizontalAlignment", "center");
    exportgraphics(fig, fullfile(outputFolder, ...
        sprintf("dct_quantization_%s.png", datasetName)), ...
        "Resolution", 175);
    close(fig);

    fprintf("%s DCT evaluation (8 x 8 blocks, zero pad %d rows x %d cols)\n", ...
        upper(datasetName), paddedRows - rows, paddedCols - cols);
    datasetRows = datasetColumn == datasetName;
    disp(table(datasetColumn(datasetRows), stepColumn(datasetRows), ...
        rmseColumn(datasetRows), maxErrorColumn(datasetRows), ...
        'VariableNames', {'Dataset', 'QuantizationStep', 'RMSE', 'MaxAbsError'}));
end

metrics = table(datasetColumn, stepColumn, rmseColumn, maxErrorColumn, ...
    'VariableNames', {'Dataset', 'QuantizationStep', 'RMSE', 'MaxAbsError'});
metricsPath = fullfile(outputFolder, "dct_quantization_metrics.csv");
writetable(metrics, metricsPath);
fprintf("Metrics saved to %s\n", metricsPath);
fprintf("No compression ratio is reported; coefficient encoding is not implemented.\n");
