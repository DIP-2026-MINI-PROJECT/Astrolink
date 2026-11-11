%% AstroLink - Unit 1, Topic 3: Basic Pixel Relationships
%
% Syllabus topic: pixel neighbourhoods, adjacency and
% connectivity.
%
%   4-neighbours of pixel (r, c):  (r-1,c) (r+1,c)
%                                      (r,c-1) (r,c+1)
%   diagonal neighbours:               (r-1,c-1) (r-1,c+1)
%                                      (r+1,c-1) (r+1,c+1)
%   8-neighbourhood = 4-neighbours + diagonal neighbours
%
%   Adjacency: two pixels are 4-adjacent if one is a
%   4-neighbour of the other; 8-adjacent if one is in
%   the other's 8-neighbourhood; m-adjacent if they are
%   8-adjacent but the 4-neighbours they share are all
%   background.
%
%   Connectivity: a path of adjacent pixels. With
%   4-connectivity only horizontal/vertical steps are
%   allowed; with 8-connectivity diagonal steps are
%   also allowed.
%
% The same demonstration runs on two datasets (Orion and
% M51) using the same code. All demonstrations use a
% separate asinh-stretched display copy. Pixel samples,
% neighborhoods, and the threshold are evaluated on original
% science values.
%
% Three figures are saved per dataset:
%   unit1_pixel_neighbourhood.png  (region + 3 x 3 detail)
%   unit1_adjacency_example.png    (4- vs 8-adjacency)
%   unit1_connectivity.png         (4- vs 8-connectivity)

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

    %% 1. Read the science image and pick a small region

    % load_sci_image finds the right FITS file and reads
    % the science image (original values).
    scienceImage = load_sci_image(datasetName);

    if datasetName == "orion"
        intensityUnit = "COUNTS/S";
    else
        intensityUnit = "ELECTRONS";
    end
    softeningFraction = 0.02;
    [displayImage, displayLimits] = astro_display_stretch( ...
        scienceImage, [], [1 99.7], softeningFraction);

    % Folder for this dataset's figures.
    datasetFolder = fullfile(resultsFolder, "astronomical_visualization", ...
        "unit1", datasetName);
    if ~isfolder(datasetFolder)
        mkdir(datasetFolder);
    end

    % A small square region around the brightest science pixel.
    [~, maxIndex] = max(scienceImage(:));
    [maxRow, maxCol] = ind2sub(size(displayImage), maxIndex);
    rowStart = min(max(maxRow - 8, 1), size(displayImage, 1) - 15);
    colStart = min(max(maxCol - 8, 1), size(displayImage, 2) - 15);
    region = scienceImage(rowStart:rowStart+15, ...
        colStart:colStart+15);   % 16 x 16 region
    regionDisplay = astro_display_stretch(region, displayLimits, ...
        [1 99.7], softeningFraction);
    centreRow = 8;
    centreCol = 8;

    fprintf("Region: 16 x 16 pixels at rows %d-%d, columns %d-%d\n", ...
        rowStart, rowStart+15, colStart, colStart+15);
    fprintf("Centre pixel at (row %d, col %d) of the region\n", ...
        centreRow, centreCol);
    fprintf("Centre value: %.6g %s\n\n", ...
        region(centreRow, centreCol), intensityUnit);

    %% 2. Neighbours of the centre pixel

    % The 3 x 3 neighbourhood around the centre pixel.
    neighbourhood = region(centreRow-1:centreRow+1, ...
        centreCol-1:centreCol+1);
    neighbourhoodDisplay = regionDisplay(centreRow-1:centreRow+1, ...
        centreCol-1:centreCol+1);

    % 4-neighbours: north, south, west, east.
    north = region(centreRow-1, centreCol);
    south = region(centreRow+1, centreCol);
    west  = region(centreRow, centreCol-1);
    east  = region(centreRow, centreCol+1);

    % 4 diagonal neighbours.
    northWest = region(centreRow-1, centreCol-1);
    northEast = region(centreRow-1, centreCol+1);
    southWest = region(centreRow+1, centreCol-1);
    southEast = region(centreRow+1, centreCol+1);

    fprintf("3 x 3 neighbourhood (the centre element is at position 2,2):\n");
    for r = 1:3
        for c = 1:3
            fprintf("  %.4f", neighbourhood(r, c));
        end
        fprintf("\n");
    end
    fprintf("\n4-neighbours:     N=%.4f  S=%.4f  W=%.4f  E=%.4f\n", ...
        north, south, west, east);
    fprintf("Diagonal neighbours: NW=%.4f  NE=%.4f  SW=%.4f  SE=%.4f\n", ...
        northWest, northEast, southWest, southEast);
    fprintf("The 8-neighbourhood is the union of these 8 pixels.\n");

    % Figure: the region (left) and its 3 x 3
    % neighbourhood (right). Both panels use the
    % same display scale.
    fig = figure("Visible", "off", ...
        "Color", darkBg, ...
        "Position", [100 100 1080 500]);
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

    tiledlayout(1, 2, "Padding", "compact", ...
        "TileSpacing", "compact");

    % Left: the 16 x 16 region with the 8-neighbourhood
    % of the centre pixel marked. plot uses (x, y)
    % = (column, row). The pixel grid makes the
    % individual samples visible.
    nexttile;
    imagesc(regionDisplay);
    axis image;
    clim([0 1]);
    set(gca, "XTick", 1:16, "YTick", 1:16, "FontSize", 7, ...
        "GridColor", gridCol, "GridAlpha", 0.35);
    grid on;
    hold on;
    plot(centreCol, centreRow, "g*", "MarkerSize", 14, "LineWidth", 2);
    plot([centreCol centreCol centreCol-1 centreCol+1], ...
         [centreRow-1 centreRow+1 centreRow centreRow], ...
         "ro", "MarkerSize", 10, "LineWidth", 2);
    plot([centreCol-1 centreCol+1 centreCol-1 centreCol+1], ...
         [centreRow-1 centreRow-1 centreRow+1 centreRow+1], ...
         "bs", "MarkerSize", 10, "LineWidth", 2);
    hold off;
    lg = legend("centre pixel (green star)", ...
                "4-neighbours (red circles)", ...
                "diagonal neighbours (blue squares)", ...
                "Location", "southoutside");
    lg.TextColor = lightFg;
    lg.Color = [0.11 0.12 0.14];
    lg.EdgeColor = gridCol;
    lg.FontSize = 9;
    cb = colorbar;
    astro_display_colorbar(cb, displayLimits, softeningFraction, ...
        intensityUnit, lightFg);
    title(sprintf("16 x 16 region at rows %d-%d, columns %d-%d", ...
        rowStart, rowStart+15, colStart, colStart+15), ...
        "Color", "w", "FontSize", 11);
    xlabel("column");
    ylabel("row");

    % Right: the 3 x 3 neighbourhood with every value
    % printed on its pixel and the centre cell
    % outlined. Same display scale as the region.
    nexttile;
    imagesc(neighbourhoodDisplay);
    axis image;
    clim([0 1]);
    set(gca, "XTick", 1:3, "YTick", 1:3, ...
        "GridColor", gridCol, "GridAlpha", 0.35);
    grid on;
    hold on;
    for r = 1:3
        for c = 1:3
            if neighbourhoodDisplay(r, c) > 0.5
                textColor = darkBg;
            else
                textColor = "w";
            end
            text(c, r, sprintf("%.4g", neighbourhood(r, c)), ...
                "Color", textColor, "FontSize", 9, ...
                "FontWeight", "bold", ...
                "HorizontalAlignment", "center");
        end
    end
    % The centre cell of the 3 x 3 block is at (2, 2).
    rectangle("Position", [2 - 0.5, 2 - 0.5, 1, 1], ...
        "EdgeColor", [0.25 0.80 0.40], "LineWidth", 2.5);
    hold off;
    title("3 x 3 neighbourhood of the centre pixel (region row 8, col 8)", ...
        "Color", "w", "FontSize", 11);
    xlabel("column in the 3 x 3 block");
    ylabel("row in the 3 x 3 block");

    sgtitle(sprintf("%s - Pixel Neighbourhood: 4- and 8-Neighbours (Unit 1, Topic 3)", ...
        datasetName), "Color", "w", "FontSize", 13, ...
        "FontWeight", "bold");
    annotation("textbox", [0.03 0.008 0.94 0.032], ...
        "String", sprintf("Pixel values are original science intensities. Panels use one asinh display mapping with limits [%.4g, %.4g] %s.", ...
        displayLimits(1), displayLimits(2), intensityUnit), ...
        "Color", midFg, "FontSize", 9, "EdgeColor", "none", ...
        "HorizontalAlignment", "center");
    exportgraphics(gcf, ...
        fullfile(datasetFolder, "unit1_pixel_neighbourhood.png"), ...
        "Resolution", 150);
    close(gcf);

    fprintf("\nSaved figure: %s\n", ...
        fullfile(datasetFolder, "unit1_pixel_neighbourhood.png"));

    %% 3. Adjacency and connectivity on a small binary example
    % Binary image: 1 = foreground (white), 0 = background
    % (black). The three foreground pixels touch each
    % other only diagonally.
    binaryImage = [ ...
        0 0 0 0 0
        0 1 0 0 0
        0 0 1 0 0
        0 0 0 1 0
        0 0 0 0 0];

    % bwconncomp finds connected components.
    % conn = 4: only horizontal and vertical steps
    % connect pixels.
    % conn = 8: diagonal steps also connect pixels.
    components4 = bwconncomp(binaryImage, 4);
    components8 = bwconncomp(binaryImage, 8);

    % bwlabel gives each component a different label
    % number, which label2rgb turns into a coloured
    % image for display. The dark background colour
    % matches the figure; the component colours have a
    % clear scientific purpose: they tell the
    % components apart.
    labels4 = bwlabel(binaryImage, 4);
    labels8 = bwlabel(binaryImage, 8);
    rgb4 = label2rgb(labels4, "lines", darkBg);
    rgb8 = label2rgb(labels8, "lines", darkBg);

    fprintf("\nBinary example (1 = foreground):\n");
    disp(binaryImage);
    fprintf("4-connected components: %d (diagonal pixels do NOT touch)\n", ...
        components4.NumObjects);
    fprintf("8-connected components: %d (diagonal pixels DO touch)\n", ...
        components8.NumObjects);

    fprintf("\nm-adjacency: pixels (2,2) and (3,3) are 8-adjacent.\n");
    fprintf("The 4-neighbours they share are (2,3) and (3,2),\n");
    fprintf("and both are background (0), so the pixels are\n");
    fprintf("also m-adjacent. m-adjacency removes the\n");
    fprintf("ambiguity of 8-adjacency: it prevents paths\n");
    fprintf("that sneak between two background pixels\n");
    fprintf("diagonally.\n");

    % Figure: the same synthetic example labelled under
    % 4-connectivity (left) and 8-connectivity (right).
    fig = figure("Visible", "off", ...
        "Color", darkBg, ...
        "Position", [100 100 920 440]);
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

    tiledlayout(1, 2, "Padding", "compact", ...
        "TileSpacing", "compact");

    nexttile;
    image(rgb4);
    axis image;
    set(gca, "XTick", 1:5, "YTick", 1:5, "FontSize", 8, ...
        "GridColor", gridCol, "GridAlpha", 0.35);
    grid on;
    title(sprintf("4-connectivity: %d components", ...
        components4.NumObjects), "Color", "w", "FontSize", 11);
    xlabel("diagonal pixels do NOT touch");
    ylabel("row");

    nexttile;
    image(rgb8);
    axis image;
    set(gca, "XTick", 1:5, "YTick", 1:5, "FontSize", 8, ...
        "GridColor", gridCol, "GridAlpha", 0.35);
    grid on;
    title(sprintf("8-connectivity: %d components", ...
        components8.NumObjects), "Color", "w", "FontSize", 11);
    xlabel("diagonal pixels DO touch");
    ylabel("row");

    sgtitle(sprintf("%s - Adjacency and m-Adjacency: Example (Unit 1, Topic 3)", ...
        datasetName), "Color", "w", "FontSize", 13, ...
        "FontWeight", "bold");
    annotation("textbox", [0.03 0.008 0.94 0.032], ...
        "String", "Pixels (2,2) and (3,3) are 8-adjacent; the 4-neighbours they share, (2,3) and (3,2), are background, " + ...
        "so they are also m-adjacent.", ...
        "Color", midFg, "FontSize", 9, "EdgeColor", "none", ...
        "HorizontalAlignment", "center");
    exportgraphics(gcf, ...
        fullfile(datasetFolder, "unit1_adjacency_example.png"), ...
        "Resolution", 150);
    close(gcf);

    % Threshold the original region at the midpoint of its science range.
    thresholdValue = (min(region(:)) + max(region(:))) / 2;
    binaryRegion = region > thresholdValue;
    componentsRegion4 = bwconncomp(binaryRegion, 4);
    componentsRegion8 = bwconncomp(binaryRegion, 8);
    labelsRegion4 = bwlabel(binaryRegion, 4);
    labelsRegion8 = bwlabel(binaryRegion, 8);
    rgbRegion4 = label2rgb(labelsRegion4, "lines", darkBg);
    rgbRegion8 = label2rgb(labelsRegion8, "lines", darkBg);
    fprintf("\nThresholded science region (threshold = %.6g %s):\n", ...
        thresholdValue, intensityUnit);
    fprintf("  4-connected components: %d\n", componentsRegion4.NumObjects);
    fprintf("  8-connected components: %d\n", componentsRegion8.NumObjects);

    % Figure: connectivity on the real astronomical
    % region. The original region comes first, then
    % the thresholded image, then the component maps.
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

    nexttile;
    imagesc(regionDisplay);
    axis image;
    clim([0 1]);
    set(gca, "XTick", 1:16, "YTick", 1:16, "FontSize", 7, ...
        "GridColor", gridCol, "GridAlpha", 0.35);
    grid on;
    cb = colorbar;
    astro_display_colorbar(cb, displayLimits, softeningFraction, ...
        intensityUnit, lightFg);
    title("Region of the astronomical image (display only)", ...
        "Color", "w", "FontSize", 11);
    xlabel("column");
    ylabel("row");

    nexttile;
    imagesc(binaryRegion);
    axis image;
    clim([0 1]);
    set(gca, "XTick", 1:16, "YTick", 1:16, "FontSize", 7, ...
        "GridColor", gridCol, "GridAlpha", 0.35);
    grid on;
    title(sprintf("Thresholded region: science value > %.4g %s", ...
        thresholdValue, intensityUnit), ...
        "Color", "w", "FontSize", 11);
    xlabel("column");
    ylabel("row");

    nexttile;
    image(rgbRegion4);
    axis image;
    set(gca, "XTick", 1:16, "YTick", 1:16, "FontSize", 7, ...
        "GridColor", gridCol, "GridAlpha", 0.35);
    grid on;
    title(sprintf("4-connected components: %d", ...
        componentsRegion4.NumObjects), "Color", "w", "FontSize", 11);
    xlabel("column");
    ylabel("row");

    nexttile;
    image(rgbRegion8);
    axis image;
    set(gca, "XTick", 1:16, "YTick", 1:16, "FontSize", 7, ...
        "GridColor", gridCol, "GridAlpha", 0.35);
    grid on;
    title(sprintf("8-connected components: %d", ...
        componentsRegion8.NumObjects), "Color", "w", "FontSize", 11);
    xlabel("column");
    ylabel("row");

    sgtitle(sprintf("%s - Connectivity: 4- vs 8-Connected Components (Unit 1, Topic 3)", ...
        datasetName), "Color", "w", "FontSize", 13, ...
        "FontWeight", "bold");
    annotation("textbox", [0.03 0.008 0.94 0.032], ...
        "String", sprintf("Connectivity uses the binary test science intensity > %.4g %s; the displayed image uses a separate asinh stretch.", ...
        thresholdValue, intensityUnit), ...
        "Color", midFg, "FontSize", 9, "EdgeColor", "none", ...
        "HorizontalAlignment", "center");
    exportgraphics(gcf, ...
        fullfile(datasetFolder, "unit1_connectivity.png"), ...
        "Resolution", 150);
    close(gcf);

    %% 4. Explanation of the observed effects

    fprintf("\nWhat to observe (%s):\n", datasetName);
    fprintf("  The green star is the centre pixel. The red\n");
    fprintf("  circles are its 4-neighbours (north, south,\n");
    fprintf("  west, east) and the blue squares are the 4\n");
    fprintf("  diagonal neighbours; together they form the\n");
    fprintf("  8-neighbourhood.\n");
    fprintf("  In the adjacency example the three white\n");
    fprintf("  pixels form ONE component under 8-connectivity\n");
    fprintf("  but THREE separate components under\n");
    fprintf("  4-connectivity, because they only touch\n");
    fprintf("  corner-to-corner.\n");
    fprintf("\nSaved figures:\n");
    fprintf("  %s\n", fullfile(datasetFolder, "unit1_pixel_neighbourhood.png"));
    fprintf("  %s\n", fullfile(datasetFolder, "unit1_adjacency_example.png"));
    fprintf("  %s\n", fullfile(datasetFolder, "unit1_connectivity.png"));
end

fprintf("\nSaved figures in results/astronomical_visualization/unit1/orion/ and m51/:\n");
fprintf("  unit1_pixel_neighbourhood.png, unit1_adjacency_example.png,\n");
fprintf("  unit1_connectivity.png\n");

