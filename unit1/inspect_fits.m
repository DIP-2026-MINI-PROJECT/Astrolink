clc;
clear;
close all;

%% AstroLink Stage 1: FITS Image Inspection
% Inspects the HST FITS dataset, identifies the science image in the
% drizzled product u2id010gt_drz.fits, reports pixel statistics, and
% saves display figures plus a text report to results/.
% The original FITS files are opened read-only and never modified.
% Normalization is applied only to separate in-memory copies used for
% display; every statistic is computed from the original pixel values.

fprintf("MATLAB version: %s\n", version);
fprintf("MATLAB root:    %s\n", matlabroot);
fprintf("Installed products:\n");
tbx = ver;
for k = 1:numel(tbx)
    fprintf("  - %s\n", tbx(k).Name);
end
fprintf("\n");

% Resolve the project root from this script's location so it can be
% run from any working folder, not only from the project root.
scriptPath = string(mfilename("fullpath"));
scriptDir = fileparts(scriptPath);
projectRoot = fileparts(scriptDir);

dataFolder = fullfile(projectRoot, "data", "orion", ...
    "MAST_2026-10-09T0632", "HST");
resultsFolder = fullfile(projectRoot, "results");

if ~isfolder(dataFolder)
    error("Folder not found: %s", dataFolder);
end

if ~isfolder(resultsFolder)
    mkdir(resultsFolder);
end

%% 1. Find FITS files

files = listFitsFiles(dataFolder);

if isempty(files)
    error(["No FITS files found in:\n%s\n" ...
        "Check whether the downloaded files are still compressed as .fits.gz."], ...
        dataFolder);
end

fprintf("========================================\n");
fprintf(" ASTROLINK: FITS FILE INSPECTION\n");
fprintf("========================================\n\n");
fprintf("Project root: %s\n", projectRoot);
fprintf("Data folder:   %s\n\n", dataFolder);

fprintf("Found %d FITS files:\n\n", numel(files));
for k = 1:numel(files)
    fprintf("%d. %s (%.2f MB)\n", k, files(k).name, files(k).bytes / 1e6);
end

%% 2. Inspect files and HDUs/extensions

reportLines = strings(0, 1);
reportLines(end+1, 1) = "ASTROLINK FITS INSPECTION REPORT";
reportLines(end+1, 1) = "================================";
reportLines(end+1, 1) = "Generated: " + string(datetime("now"));
reportLines(end+1, 1) = "MATLAB: " + version;
reportLines(end+1, 1) = "Project root: " + projectRoot;
reportLines(end+1, 1) = "Data folder: " + dataFolder;
reportLines(end+1, 1) = "";
reportLines(end+1, 1) = "Files found:";
for k = 1:numel(files)
    reportLines(end+1, 1) = sprintf("  %d. %s (%.2f MB)", ...
        k, files(k).name, files(k).bytes / 1e6);
end
reportLines(end+1, 1) = "";
reportLines(end+1, 1) = "Per-file HDU structure:";
reportLines(end+1, 1) = "-----------------------";

errors = strings(0, 1);

for f = 1:numel(files)
    originalPath = fullfile(files(f).folder, files(f).name);
    [readPath, cleanupObj] = prepareFitsPath(originalPath);

    fprintf("\n----------------------------------------\n");
    fprintf("Inspecting file %d/%d: %s\n", f, numel(files), files(f).name);
    fprintf("----------------------------------------\n");

    try
        info = fitsinfo(readPath);
        lines = describeFitsInfo(info);
        for i = 1:numel(lines)
            fprintf("%s\n", lines(i));
            reportLines(end+1, 1) = lines(i);
        end
    catch ME
        msg = sprintf("File %s: metadata read failed: %s", ...
            files(f).name, ME.message);
        warning("%s", msg);
        errors(end+1, 1) = msg;
        reportLines(end+1, 1) = "  ERROR: " + msg;
    end

    if ~isempty(cleanupObj)
        delete(cleanupObj);
    end
end

%% 3. Deep inspection of the drizzled science product u2id010gt_drz.fits

targetName = "u2id010gt_drz.fits";
targetIdx = find(strcmp([files.name], targetName), 1);

if isempty(targetIdx)
    error("Target file %s not found in %s", targetName, dataFolder);
end

targetPath = fullfile(files(targetIdx).folder, files(targetIdx).name);
info = fitsinfo(targetPath);

extNames = ["SCI", "WHT", "CTX"];
extLabels = ["SCI (science image, COUNTS/S)";
             "WHT (weight map, COUNTS)";
             "CTX (context map, COUNTS)"];
extArrays = cell(1, numel(extNames));
extIdx = NaN(1, numel(extNames));

fprintf("\n----------------------------------------\n");
fprintf("Science product inspection: %s\n", targetName);
fprintf("----------------------------------------\n");

for i = 1:numel(extNames)
    extIdx(i) = findExtensionIndex(info, extNames(i));
    if isnan(extIdx(i))
        error("Extension %s not found in %s", extNames(i), targetName);
    end
    extArrays{i} = fitsread(targetPath, "image", extIdx(i));
end

sci = extArrays{1};

primaryKw = info.PrimaryData.Keywords;
sciKw = info.Image(extIdx(1)).Keywords;

fprintf("\nScience image identified as extension SCI (EXTNAME=SCI, EXTVER=1).\n");
fprintf("\nSelected keywords:\n");
reportLines(end+1, 1) = "";
reportLines(end+1, 1) = "Science product: " + targetName;
reportLines(end+1, 1) = "Science image identified as extension SCI (EXTNAME=SCI, EXTVER=1).";
reportLines(end+1, 1) = "";
reportLines(end+1, 1) = "Selected keywords:";

headerKeys = ["TELESCOP", "INSTRUME", "DETECTOR", "FILTER1", "FILTER2", ...
    "TARGNAME", "RA_TARG", "DEC_TARG", "DATE-OBS", "TIME-OBS", ...
    "EXPTIME", "EXPSTART", "PROPOSID"];
for i = 1:numel(headerKeys)
    v = keywordValue(primaryKw, headerKeys(i));
    if isempty(v), v = "-"; end
    fprintf("  %-10s = %s\n", headerKeys(i), v);
    reportLines(end+1, 1) = sprintf("  %-10s = %s", headerKeys(i), v);
end
extKeys = ["EXTNAME", "EXTVER", "BUNIT", "BITPIX", "NAXIS1", "NAXIS2", ...
    "CRPIX1", "CRPIX2", "CD1_1", "CD2_2"];
for i = 1:numel(extKeys)
    v = keywordValue(sciKw, extKeys(i));
    if isempty(v), v = "-"; end
    fprintf("  %-10s = %s\n", extKeys(i), v);
    reportLines(end+1, 1) = sprintf("  %-10s = %s", extKeys(i), v);
end

fprintf("\nPixel statistics (original, unnormalized values):\n\n");
reportLines(end+1, 1) = "";
reportLines(end+1, 1) = "Pixel statistics (original, unnormalized values):";

stats = cell(1, numel(extArrays));
for i = 1:numel(extArrays)
    st = pixelStats(extArrays{i});
    stats{i} = st;
    printPixelStats(extLabels(i), st);
    reportLines(end+1, 1) = "  " + extLabels(i);
    reportLines = [reportLines; statsToLines(st)];
end

%% 4. Display figures
% A percentile stretch is applied only to separate copies of the
% data that are used for display. The arrays sci/wht/ctx above
% keep their original pixel values for numerical experiments.

sciStats = stats{1};
lo = sciStats.p1;
hi = sciStats.p99;
if hi <= lo
    hi = sciStats.max;
end
sciDisplay = mat2gray(double(sci), [lo, hi]);   % normalized copy, display only

try
    fig1 = figure("Visible", "off", "Name", "Orion SCI display", ...
        "Color", [0.07 0.08 0.10], "Position", [100 100 1000 700]);
    set(fig1, "DefaultAxesColor", [0.07 0.08 0.10], ...
        "DefaultAxesXColor", [0.93 0.94 0.96], ...
        "DefaultAxesYColor", [0.93 0.94 0.96], ...
        "DefaultAxesFontName", "Calibri", "DefaultAxesFontSize", 10);
    imagesc(sciDisplay);
    axis image;
    colormap(turbo(256));
    cb = colorbar;
    cb.Color = [0.93 0.94 0.96];
    cb.Label.String = "display level (percentile stretch; display only)";
    cb.Label.Color = [0.93 0.94 0.96];
    title(sprintf("Orion | %s, SCI extension | display stretch [%.3g, %.3g]", ...
        targetName, lo, hi), "Color", [0.93 0.94 0.96]);
    xlabel("pixel column");
    ylabel("pixel row");
    exportgraphics(fig1, ...
        fullfile(resultsFolder, "u2id010gt_drz_SCI_display.png"), ...
        "Resolution", 150);
    close(fig1);
    fprintf("Saved figure: %s\n", ...
        fullfile(resultsFolder, "u2id010gt_drz_SCI_display.png"));
catch ME
    msg = sprintf("SCI display figure failed: %s", ME.message);
    warning("%s", msg);
    errors(end+1, 1) = msg;
end

try
    fig2 = figure("Visible", "off", "Name", "Orion FITS extensions", ...
        "Color", [0.07 0.08 0.10], "Position", [100 100 1450 520]);
    set(fig2, "DefaultAxesColor", [0.07 0.08 0.10], ...
        "DefaultAxesXColor", [0.93 0.94 0.96], ...
        "DefaultAxesYColor", [0.93 0.94 0.96], ...
        "DefaultAxesFontName", "Calibri", "DefaultAxesFontSize", 10);
    tiledlayout(1, 3);
    for i = 1:numel(extArrays)
        st = stats{i};
        loI = st.p1;
        hiI = st.p99;
        if hiI <= loI
            hiI = st.max;
        end
        nexttile;
        imagesc(mat2gray(double(extArrays{i}), [loI, hiI]));
        axis image;
        colormap(turbo(256));
        cb = colorbar;
        cb.Color = [0.93 0.94 0.96];
        cb.Label.String = "display level (stretch, display only)";
        cb.Label.Color = [0.93 0.94 0.96];
        title(extNames(i), "Color", [0.93 0.94 0.96]);
    end
    sgtitle(targetName + ": SCI / WHT / CTX (each normalized for display)");
    exportgraphics(fig2, ...
        fullfile(resultsFolder, "u2id010gt_drz_extensions_display.png"), ...
        "Resolution", 150);
    close(fig2);
    fprintf("Saved figure: %s\n", ...
        fullfile(resultsFolder, "u2id010gt_drz_extensions_display.png"));
catch ME
    msg = sprintf("Extensions display figure failed: %s", ME.message);
    warning("%s", msg);
    errors(end+1, 1) = msg;
end

try
    fig3 = figure("Visible", "off", "Name", "Orion SCI histogram", ...
        "Color", [0.07 0.08 0.10], "Position", [100 100 900 600]);
    set(fig3, "DefaultAxesColor", [0.07 0.08 0.10], ...
        "DefaultAxesXColor", [0.93 0.94 0.96], ...
        "DefaultAxesYColor", [0.93 0.94 0.96], ...
        "DefaultAxesFontName", "Calibri", "DefaultAxesFontSize", 10);
    histogram(double(sci(:)), 200, "BinLimits", [0, 10]);
    title(targetName + " SCI pixel-value histogram (original values)", ...
        "Color", [0.93 0.94 0.96]);
    xlabel("original SCI intensity (COUNTS/S)");
    ylabel("number of pixels");
    exportgraphics(fig3, ...
        fullfile(resultsFolder, "u2id010gt_drz_SCI_histogram.png"), ...
        "Resolution", 150);
    close(fig3);
    fprintf("Saved figure: %s\n", ...
        fullfile(resultsFolder, "u2id010gt_drz_SCI_histogram.png"));
catch ME
    msg = sprintf("SCI histogram figure failed: %s", ME.message);
    warning("%s", msg);
    errors(end+1, 1) = msg;
end

%% 5. Save the text report

reportLines(end+1, 1) = "";
reportLines(end+1, 1) = "Display figures saved to results/:";
reportLines(end+1, 1) = "  u2id010gt_drz_SCI_display.png";
reportLines(end+1, 1) = "  u2id010gt_drz_extensions_display.png";
reportLines(end+1, 1) = "  u2id010gt_drz_SCI_histogram.png";
reportLines(end+1, 1) = "";
reportLines(end+1, 1) = "Notes:";
reportLines(end+1, 1) = "  - Original FITS files were opened read-only and not modified.";
reportLines(end+1, 1) = "  - All statistics above are computed from the original pixel values.";
reportLines(end+1, 1) = "  - Percentile-stretch normalization was applied only to separate";
reportLines(end+1, 1) = "    in-memory copies used to render the display figures.";
reportLines(end+1, 1) = "  - Stage 1 is inspection only: no sampling, quantization, transforms,";
reportLines(end+1, 1) = "    compression, or RF communication is implemented in this script.";

if ~isempty(errors)
    reportLines(end+1, 1) = "";
    reportLines(end+1, 1) = "Errors encountered:";
    for i = 1:numel(errors)
        reportLines(end+1, 1) = "  - " + errors(i);
    end
else
    reportLines(end+1, 1) = "";
    reportLines(end+1, 1) = "Errors encountered: none.";
end

reportPath = fullfile(resultsFolder, "fits_inspection_report.txt");
writelines(reportLines, reportPath);

fprintf("\n========================================\n");
fprintf(" Stage 1 complete\n");
fprintf("========================================\n");
fprintf("Report:  %s\n", reportPath);
fprintf("Figures: %s\n", fullfile(resultsFolder, "u2id010gt_drz_SCI_display.png"));
fprintf("         %s\n", fullfile(resultsFolder, "u2id010gt_drz_extensions_display.png"));
fprintf("         %s\n", fullfile(resultsFolder, "u2id010gt_drz_SCI_histogram.png"));

function files = listFitsFiles(folder)
    % List FITS files (plain or gzip-compressed) in a folder.
    patterns = ["*.fits", "*.fts", "*.fits.gz", "*.fts.gz"];
    files = struct("name", {}, "folder", {}, "bytes", {}, "date", {});
    for p = 1:numel(patterns)
        d = dir(fullfile(folder, patterns(p)));
        for k = 1:numel(d)
            files(end+1, 1) = struct( ...
                "name", string(d(k).name), ...
                "folder", string(d(k).folder), ...
                "bytes", d(k).bytes, ...
                "date", d(k).date);
        end
    end
    if ~isempty(files)
        names = [files.name];
        [~, order] = sort(names);
        files = files(order);
    end
end

function [readPath, cleanupObj] = prepareFitsPath(originalPath)
    % Return a path that fitsinfo/fitsread can open. Gzip-compressed
    % .gz files are decompressed into a temporary folder; plain FITS
    % files are passed through unchanged.
    readPath = originalPath;
    cleanupObj = [];
    if endsWith(lower(originalPath), ".gz")
        tempFolder = tempname;
        mkdir(tempFolder);
        gunzip(originalPath, tempFolder);
        d = dir(fullfile(tempFolder, "*"));
        d = d(~[d.isdir]);
        if isempty(d)
            error("Decompression produced no files for %s", originalPath);
        end
        readPath = fullfile(d(1).folder, d(1).name);
        cleanupObj = onCleanup(@() rmdir(tempFolder, "s"));
    end
end

function lines = describeFitsInfo(info)
    % Human-readable summary of a fitsinfo structure.
    lines = strings(0, 1);
    lines(end+1, 1) = sprintf("  File size: %.2f MB (%d bytes)", ...
        info.FileSize / 1e6, info.FileSize);
    lines(end+1, 1) = sprintf("  HDU contents: %s", ...
        strjoin(string(info.Contents), ", "));

    if isfield(info, "PrimaryData") && ~isempty(info.PrimaryData)
        pd = info.PrimaryData;
        sz = strjoin(string(pd.Size), " x ");
        if isempty(sz)
            sz = "empty";
        end
        lines(end+1, 1) = sprintf("  Primary HDU: %s [%s], DataSize = %d", ...
            pd.DataType, sz, pd.DataSize);
    end

    if isfield(info, "Image")
        for i = 1:numel(info.Image)
            ext = getKeyword(info.Image(i), "EXTNAME");
            ver = getKeyword(info.Image(i), "EXTVER");
            bunit = getKeyword(info.Image(i), "BUNIT");
            sz = strjoin(string(info.Image(i).Size), " x ");
             lines(end+1, 1) = sprintf( ...
                "  Image HDU %d: EXTNAME=%s EXTVER=%s %s [%s] BUNIT=%s", ...
                i, ext, ver, info.Image(i).DataType, sz, bunit);
        end
    end

    if isfield(info, "AsciiTable")
        lines(end+1, 1) = "  ASCII Table extension: present";
    end
    if isfield(info, "BinaryTable")
        lines(end+1, 1) = "  Binary Table extension: present";
    end
end

function value = getKeyword(hduInfo, keyName)
    % Look up a FITS keyword value in a fitsinfo HDU structure.
    % Values are returned as character vectors; numeric keywords
    % (e.g. EXTVER) are converted so %s formatting shows the number.
    value = "";
    if isfield(hduInfo, "Keywords")
        kw = hduInfo.Keywords;
        for j = 1:size(kw, 1)
            if strcmp(kw{j, 1}, keyName)
                value = char(string(kw{j, 2}));
                return;
            end
        end
    end
end

function value = keywordValue(kw, keyName)
    % Look up a keyword value in a fitsinfo keywords cell array.
    % Values are returned as character vectors; numeric keywords
    % (e.g. EXPTIME) are converted so %s formatting shows the number.
    value = "";
    for j = 1:size(kw, 1)
        if strcmp(kw{j, 1}, keyName)
            value = char(string(kw{j, 2}));
            return;
        end
    end
end

function idx = findExtensionIndex(info, extName)
    % Index of the image extension whose EXTNAME keyword equals extName.
    idx = NaN;
    if ~isfield(info, "Image")
        return;
    end
    for i = 1:numel(info.Image)
        if strcmp(getKeyword(info.Image(i), "EXTNAME"), extName)
            idx = i;
            return;
        end
    end
end

function st = pixelStats(a)
    % Summary statistics of an image array, computed on the original
    % values. Percentiles use linear interpolation (type-7) so that
    % the Statistics and Machine Learning Toolbox is not required.
    st.className = class(a);
    st.size = size(a);
    v = double(a(:));
    st.numel = numel(v);
    st.min = min(v);
    st.max = max(v);
    st.mean = mean(v);
    st.median = median(v);
    st.std = std(v);
    st.nNan = sum(isnan(v));
    st.nInf = sum(isinf(v));
    st.nZero = sum(v == 0);
    st.nNeg = sum(v < 0);
    qs = [1, 5, 50, 95, 99];
    sv = sort(v(~isnan(v)));
    n = numel(sv);
    if n == 0
        p = NaN(1, numel(qs));
    else
        h = (qs / 100) * (n - 1) + 1;
        lo = floor(h);
        hi = ceil(h);
        w = h - lo;
        p = sv(lo) + w .* (sv(hi) - sv(lo));
    end
    st.p1 = p(1);
    st.p5 = p(2);
    st.p50 = p(3);
    st.p95 = p(4);
    st.p99 = p(5);
end

function printPixelStats(label, st)
    % Print pixel statistics to the command window.
    sz = strjoin(string(st.size), " x ");
    fprintf("  %s\n", label);
    fprintf("    class: %s, dimensions: [%s], pixels: %d\n", ...
        st.className, sz, st.numel);
    fprintf("    min: %.6g, max: %.6g\n", st.min, st.max);
    fprintf("    mean: %.6g, median: %.6g, std: %.6g\n", ...
        st.mean, st.median, st.std);
    fprintf("    NaNs: %d, Infs: %d, zeros: %d, negatives: %d\n", ...
        st.nNan, st.nInf, st.nZero, st.nNeg);
    fprintf("    percentiles 1/5/50/95/99: %.6g / %.6g / %.6g / %.6g / %.6g\n", ...
        st.p1, st.p5, st.p50, st.p95, st.p99);
    fprintf("\n");
end

function lines = statsToLines(st)
    % Pixel statistics formatted as text-report lines.
    sz = strjoin(string(st.size), " x ");
    lines = strings(0, 1);
    lines(end+1, 1) = sprintf("    class: %s, dimensions: [%s], pixels: %d", ...
        st.className, sz, st.numel);
    lines(end+1, 1) = sprintf("    min: %.6g, max: %.6g", st.min, st.max);
    lines(end+1, 1) = sprintf("    mean: %.6g, median: %.6g, std: %.6g", ...
        st.mean, st.median, st.std);
    lines(end+1, 1) = sprintf("    NaNs: %d, Infs: %d, zeros: %d, negatives: %d", ...
        st.nNan, st.nInf, st.nZero, st.nNeg);
    lines(end+1, 1) = sprintf("    percentiles 1/5/50/95/99: %.6g / %.6g / %.6g / %.6g / %.6g", ...
        st.p1, st.p5, st.p50, st.p95, st.p99);
end




