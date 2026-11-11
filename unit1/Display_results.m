%% AstroLink - Browse generated project figures
clc;
close all;

projectFolder = fileparts(fileparts(mfilename("fullpath")));
resultsFolder = fullfile(projectFolder, "results");
integratedFolder = fullfile(resultsFolder, "integrated");
datasetNames = ["orion","m51","bug_nebula", ...
    "eagle_nebula","m35","venus"];

% One overview for the six independent integrated targets. The source-unit
% arrays are loaded from the MAT outputs and rendered with the same display
% method. Per-target percentile limits are necessary because the FITS inputs
% have different or unspecified physical intensity units.
metricsPath = fullfile(integratedFolder,"metrics","metrics.csv");
if isfile(metricsPath)
    metrics = readtable(metricsPath);
else
    metrics = table();
    warning("Integrated metric CSV not found: %s",metricsPath);
end

overviewFigure = figure("Name","Integrated | Six-target overview", ...
    "NumberTitle","off","Color","w");
overviewLayout = tiledlayout(overviewFigure,2,3, ...
    "TileSpacing","compact","Padding","compact");
for imageIndex = 1:numel(datasetNames)
    datasetName = datasetNames(imageIndex);
    arrayPath = fullfile(integratedFolder,"reconstructed", ...
        datasetName + "_science_arrays.mat");
    ax = nexttile(overviewLayout);
    if ~isfile(arrayPath)
        axis(ax,"off");
        title(ax,datasetName + " | output missing","Interpreter","none");
        continue;
    end

    arrays = load(arrayPath,"original","reconstructed");
    displayImage = asinh_display_copy(arrays.original, ...
        arrays.reconstructed,[1 99.7],0.02);
    imagesc(ax,displayImage,[0 1]);
    axis(ax,"image","off");
    colormap(ax,gray(256));

    metricText = "metrics unavailable";
    if ~isempty(metrics) && any(strcmpi(string(metrics.Image),datasetName))
        row = find(strcmpi(string(metrics.Image),datasetName),1);
        metricText = sprintf("PSNR %.2f dB | global SSIM %.6f", ...
            metrics.PSNR_dB(row),metrics.SSIM(row));
    end
    title(ax,{char(datasetName), ...
        sprintf("%d × %d",size(arrays.original,1),size(arrays.original,2)), ...
        metricText},"Interpreter","none","FontSize",9);
end
sgtitle({"Integrated reconstructions: six independent targets", ...
    "Same asinh method and [0,1] display range; each image uses its own source p1–p99.7 limits. Compare structure, not absolute brightness."}, ...
    "Interpreter","none");
fprintf("Displayed the six-target integrated reconstruction overview.\n");

displayGroups = { ...
    "FITS inspection", resultsFolder, ["u2id010gt_drz_SCI_display.png", ...
        "u2id010gt_drz_extensions_display.png", ...
        "u2id010gt_drz_SCI_histogram.png"]; ...
    "Unit 1 | Orion", fullfile(resultsFolder, "unit1", "orion"), "*.png"; ...
    "Unit 1 | M51", fullfile(resultsFolder, "unit1", "m51"), "*.png"; ...
    "Unit 2 | Orion", fullfile(resultsFolder, "unit2", "orion"), "*.png"; ...
    "Unit 2 | M51", fullfile(resultsFolder, "unit2", "m51"), "*.png"; ...
    "Evaluation", fullfile(resultsFolder, "evaluation"), "*.png"; ...
    "Astronomical visualization | Orion", ...
        fullfile(resultsFolder, "astronomical_visualization", "orion"), "*.png"; ...
    "Astronomical visualization | M51", ...
        fullfile(resultsFolder, "astronomical_visualization", "m51"), "*.png"; ...
    "Unit 1 visualization | Orion", ...
        fullfile(resultsFolder, "astronomical_visualization", "unit1", "orion"), "*.png"; ...
    "Unit 1 visualization | M51", ...
        fullfile(resultsFolder, "astronomical_visualization", "unit1", "m51"), "*.png"; ...
    "DCT comparison", ...
        fullfile(resultsFolder, "astronomical_visualization", "dct"), "*.png"; ...
    "DCT evaluation", ...
        fullfile(resultsFolder, "astronomical_visualization", "dct_evaluation"), "*.png"; ...
    "Unit 3 | Orion", fullfile(resultsFolder, "unit3", "orion"), "*.png"; ...
    "Unit 3 | M51", fullfile(resultsFolder, "unit3", "m51"), "*.png"; ...
    "Unit 4 | Orion", fullfile(resultsFolder, "unit4", "orion"), "*.png"; ...
    "Unit 4 | M51", fullfile(resultsFolder, "unit4", "m51"), "*.png" ...
    };

for groupIndex = 1:size(displayGroups, 1)
    groupName = displayGroups{groupIndex, 1};
    folder = displayGroups{groupIndex, 2};
    pattern = displayGroups{groupIndex, 3};
    if ~isfolder(folder)
        fprintf("Skipping missing results folder: %s\n", folder);
        continue;
    end
    if groupIndex == 1
        imageFiles = dir(fullfile(folder, "*.png"));
        imageFiles = imageFiles(ismember(string({imageFiles.name}), pattern));
    else
        imageFiles = dir(fullfile(folder, pattern));
    end
    if isempty(imageFiles)
        fprintf("No PNG figures found for %s.\n", groupName);
        continue;
    end
    figure("Name", groupName, "NumberTitle", "off", ...
        "Color", [0.07 0.08 0.10]);
    tiledlayout("flow", "TileSpacing", "compact", "Padding", "compact");
    for imageIndex = 1:numel(imageFiles)
        imagePath = fullfile(imageFiles(imageIndex).folder, ...
            imageFiles(imageIndex).name);
        nexttile;
        imshow(imread(imagePath));
        title(imageFiles(imageIndex).name, "Interpreter", "none", ...
            "Color", [0.93 0.94 0.96]);
    end
    sgtitle(groupName, "Color", [0.93 0.94 0.96]);
    fprintf("Displayed %d figure(s): %s\n", numel(imageFiles), groupName);
end

% Bring the six-target overview to the front after the legacy figure groups.
figure(overviewFigure);

function displayImage = asinh_display_copy(original,reconstructed,percentiles,softening)
% Match the integrated pipeline's display-only asinh transformation.
finiteSource = original(isfinite(original));
finiteSource = sort(finiteSource(:));
lowerLimit = percentile_value(finiteSource,percentiles(1));
upperLimit = percentile_value(finiteSource,percentiles(2));
if upperLimit <= lowerLimit
    upperLimit = lowerLimit + eps(max(1,abs(lowerLimit)));
end
normalized = (reconstructed-lowerLimit)/(upperLimit-lowerLimit);
normalized = min(max(normalized,0),1);
scale = max(softening,eps);
displayImage = asinh(normalized/scale)/asinh(1/scale);
displayImage = min(max(displayImage,0),1);
end

function value = percentile_value(sortedValues,percentile)
position = 1+(numel(sortedValues)-1)*percentile/100;
lowerIndex = floor(position);
upperIndex = ceil(position);
value = sortedValues(lowerIndex) + ...
    (position-lowerIndex)*(sortedValues(upperIndex)-sortedValues(lowerIndex));
end
