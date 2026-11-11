%% AstroLink - Generate the six-target comparison report
% Creates one figure with original and reconstructed pseudocolour images
% side by side, followed by metrics computed from source-unit arrays.
clear; close all; clc;
root = fileparts(mfilename("fullpath"));
addpath(fullfile(root,"unit1"));

names = ["orion","m51","bug_nebula","eagle_nebula","m35","venus"];
displayNames = ["Orion","M51","Bug Nebula","Eagle Nebula", ...
    "M35 Cluster","Venus"];
reconstructionFolder = fullfile(root,"results","integrated","reconstructed");
metricsPath = fullfile(root,"results","integrated","metrics","metrics.csv");
if ~isfile(metricsPath)
    error("Integrated metrics file not found. Run AstroLink_Final_Integrated.m first.");
end
metrics = readtable(metricsPath);
palette = astro_falsecolor_map(256);

fig = figure("Name","AstroLink Six-Target Final Report", ...
    "NumberTitle","off","Color","w","Units","inches", ...
    "Position",[0.5 0.5 18 15]);
layout = tiledlayout(fig,7,3,"TileSpacing","compact","Padding","compact");
headerText = ["Original (pseudocolour)", ...
    "Reconstructed (pseudocolour)","Evaluation metrics"];
for c = 1:3
    ax = nexttile(layout);
    axis(ax,"off");
    text(ax,0.5,0.5,headerText(c),"Units","normalized", ...
        "HorizontalAlignment","center","VerticalAlignment","middle", ...
        "FontWeight","bold","FontSize",15,"Color","k", ...
        "Interpreter","none");
end

for k = 1:numel(names)
    matPath = fullfile(reconstructionFolder,names(k)+"_science_arrays.mat");
    if ~isfile(matPath)
        error("Reconstructed science arrays not found: %s",matPath);
    end
    data = load(matPath,"original","reconstructed");
    [originalDisplay,reconstructedDisplay,limits] = ...
        report_display_pair(data.original,data.reconstructed,[1 99.7],0.02);

    ax = nexttile(layout);
    imagesc(ax,originalDisplay,[0 1]);
    axis(ax,"image","off");
    colormap(ax,palette);
    title(ax,sprintf("%s | %d × %d",displayNames(k), ...
        size(data.original,1),size(data.original,2)), ...
        "Interpreter","none","FontSize",10,"Color","k");

    ax = nexttile(layout);
    imagesc(ax,reconstructedDisplay,[0 1]);
    axis(ax,"image","off");
    colormap(ax,palette);
    title(ax,sprintf("Same display limits: %.5g to %.5g", ...
        limits(1),limits(2)),"Interpreter","none","FontSize",9,"Color","k");

    metricIndex = find(strcmpi(string(metrics.Image),names(k)),1);
    if isempty(metricIndex)
        error("No integrated metrics row found for target %s.",names(k));
    end
    ax = nexttile(layout);
    axis(ax,[0 1 0 1]);
    axis(ax,"off");
    metricLines = { ...
        sprintf("MSE: %.6g",metrics.MSE(metricIndex)), ...
        sprintf("PSNR: %.3f dB",metrics.PSNR_dB(metricIndex)), ...
        sprintf("Global SSIM: %.6f",metrics.SSIM(metricIndex)), ...
        sprintf("Residual SNR: %.3f dB",metrics.SNR_dB(metricIndex)), ...
        "BER: N/A (no bitstream/channel)"};
    text(ax,0.04,0.94,metricLines,"Units","normalized", ...
        "VerticalAlignment","top","FontSize",11,"Color","k", ...
        "Interpreter","none");
end

sgtitle(layout,{char("AstroLink: Six-Target Reconstruction Report"), ...
    char("Original and reconstructed science arrays use paired asinh display limits " + ...
    "(source p1–p99.7; softening 0.02). Metrics use un-stretched source arrays."), ...
    char("Each target is scaled independently; compare each original with its reconstruction, not absolute brightness across targets.")}, ...
    "Interpreter","none","FontWeight","bold","Color","k");

outputFolder = fullfile(root,"results","final_report");
if ~isfolder(outputFolder), mkdir(outputFolder); end
pngPath = fullfile(outputFolder,"AstroLink_Six_Target_Comparison.png");
pdfPath = fullfile(outputFolder,"AstroLink_Six_Target_Comparison.pdf");
exportgraphics(fig,pngPath,"Resolution",300);
exportgraphics(fig,pdfPath,"Resolution",300);
fprintf("Saved final report:\n%s\n%s\n",pngPath,pdfPath);

function [originalDisplay,reconstructedDisplay,limits] = ...
        report_display_pair(original,reconstructed,percentiles,softening)
finiteSource = sort(original(isfinite(original)));
if isempty(finiteSource)
    error("Cannot create a display for an image without finite source pixels.");
end
limits = [report_percentile(finiteSource,percentiles(1)), ...
    report_percentile(finiteSource,percentiles(2))];
if limits(2) <= limits(1)
    limits(2) = limits(1)+eps(max(1,abs(limits(1))));
end
originalDisplay = apply_report_stretch(original,limits,softening);
reconstructedDisplay = apply_report_stretch(reconstructed,limits,softening);
end

function displayImage = apply_report_stretch(imageData,limits,softening)
normalized = (imageData-limits(1))/(limits(2)-limits(1));
normalized = min(max(normalized,0),1);
scale = max(softening,eps);
displayImage = asinh(normalized/scale)/asinh(1/scale);
displayImage = min(max(displayImage,0),1);
end

function value = report_percentile(sortedValues,percentile)
position = 1+(numel(sortedValues)-1)*percentile/100;
lowerIndex = floor(position);
upperIndex = ceil(position);
value = sortedValues(lowerIndex)+(position-lowerIndex)* ...
    (sortedValues(upperIndex)-sortedValues(lowerIndex));
end
