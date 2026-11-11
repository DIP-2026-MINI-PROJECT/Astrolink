%% Compare the inherited fixed DCT step with a scale-relative step
% This experiment does not change the integrated pipeline: its production
% setting remains 8x8 blocks and Delta=2. It measures whether that fixed
% source-unit step produces comparable relative error across the six inputs.
clear; close all; clc;
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'unit1'));
names = ["orion","m51","bug_nebula","eagle_nebula","m35","venus"];
block = 8;
fixedStep = 2;
percentiles = [1 99.7];
robustSpan = zeros(numel(names),1);

% Estimate each image's robust intensity span without changing its science
% array. The same p1-p99.7 interval is used by the display-limit method.
for k = 1:numel(names)
    image = double(load_sci_image(names(k)));
    finiteValues = sort(image(isfinite(image)));
    if isempty(finiteValues)
        error('Dataset %s has no finite pixels.', names(k));
    end
    limits = [percentile_sorted(finiteValues,percentiles(1)), ...
        percentile_sorted(finiteValues,percentiles(2))];
    robustSpan(k) = limits(2)-limits(1);
    if robustSpan(k) <= 0
        error('Dataset %s has a degenerate robust intensity span.', names(k));
    end
end

% One scale-relative rule, calibrated so the median robust span retains the
% inherited step of 2: Delta_i = 2 * span_i / median(span_1...span_6).
medianSpan = median(robustSpan);
adaptiveStep = fixedStep * robustSpan / medianSpan;
FixedMSE = zeros(numel(names),1); FixedPSNR_dB = FixedMSE;
FixedGlobalSSIM = FixedMSE; FixedResidualSNR_dB = FixedMSE;
FixedNRMSE_Robust = FixedMSE;
AdaptiveMSE = FixedMSE; AdaptivePSNR_dB = FixedMSE;
AdaptiveGlobalSSIM = FixedMSE; AdaptiveResidualSNR_dB = FixedMSE;
AdaptiveNRMSE_Robust = FixedMSE;

for k = 1:numel(names)
    original = double(load_sci_image(names(k)));
    if isempty(original) || ~ismatrix(original) || ~any(isfinite(original(:)))
        error('Input %s must be a finite, nonempty 2-D science image.', names(k));
    end
    original(~isfinite(original)) = 0;
    [height,width] = size(original);
    paddedHeight = ceil(height/block)*block;
    paddedWidth = ceil(width/block)*block;
    padded = zeros(paddedHeight,paddedWidth);
    padded(1:height,1:width) = original;
    fixedReconstruction = zeros(paddedHeight,paddedWidth);
    adaptiveReconstruction = zeros(paddedHeight,paddedWidth);

    for row = 1:block:paddedHeight
        for column = 1:block:paddedWidth
            rows = row:row+block-1;
            columns = column:column+block-1;
            coefficients = dct2(padded(rows,columns));
            fixedCoefficients = round(coefficients/fixedStep)*fixedStep;
            adaptiveCoefficients = round(coefficients/adaptiveStep(k))*adaptiveStep(k);
            fixedReconstruction(rows,columns) = idct2(fixedCoefficients);
            adaptiveReconstruction(rows,columns) = idct2(adaptiveCoefficients);
        end
    end

    fixedReconstruction = fixedReconstruction(1:height,1:width);
    adaptiveReconstruction = adaptiveReconstruction(1:height,1:width);
    [FixedMSE(k),FixedPSNR_dB(k),FixedGlobalSSIM(k), ...
        FixedResidualSNR_dB(k),FixedNRMSE_Robust(k)] = ...
        measure_pair(original,fixedReconstruction,robustSpan(k));
    [AdaptiveMSE(k),AdaptivePSNR_dB(k),AdaptiveGlobalSSIM(k), ...
        AdaptiveResidualSNR_dB(k),AdaptiveNRMSE_Robust(k)] = ...
        measure_pair(original,adaptiveReconstruction,robustSpan(k));
    fprintf('%s: Delta fixed %.9g, adaptive %.9g; robust-NRMSE fixed %.6g, adaptive %.6g\n', ...
        names(k),fixedStep,adaptiveStep(k),FixedNRMSE_Robust(k),AdaptiveNRMSE_Robust(k));
end

T = table(names(:),robustSpan,adaptiveStep,FixedMSE,FixedPSNR_dB, ...
    FixedGlobalSSIM,FixedResidualSNR_dB,FixedNRMSE_Robust,AdaptiveMSE, ...
    AdaptivePSNR_dB,AdaptiveGlobalSSIM,AdaptiveResidualSNR_dB, ...
    AdaptiveNRMSE_Robust,'VariableNames',{'Image','RobustSpan_P1_P99_7', ...
    'AdaptiveDelta','FixedMSE','FixedPSNR_dB','FixedGlobalSSIM', ...
    'FixedResidualSNR_dB','FixedNRMSE_Robust','AdaptiveMSE', ...
    'AdaptivePSNR_dB','AdaptiveGlobalSSIM','AdaptiveResidualSNR_dB', ...
    'AdaptiveNRMSE_Robust'});
disp(T);
outFolder = fullfile(root,'results','integrated','metrics');
if ~isfolder(outFolder), mkdir(outFolder); end
writetable(T,fullfile(outFolder,'quantization_scale_experiment.csv'));

function q = percentile_sorted(sortedValues,p)
t = 1+(numel(sortedValues)-1)*p/100;
lo = floor(t); hi = ceil(t);
q = sortedValues(lo)+(t-lo)*(sortedValues(hi)-sortedValues(lo));
end

function [mse,psnrDb,ssimValue,snrDb,nrmseRobust] = measure_pair(original,reconstructed,robustSpan)
errorImage = original-reconstructed;
errorVector = errorImage(:);
sourceVector = original(:);
mse = mean(errorVector.^2);
peak = max(sourceVector)-min(sourceVector);
if mse == 0
    psnrDb = Inf;
else
    psnrDb = 10*log10(peak^2/mse);
end
snrDb = 10*log10(sum(sourceVector.^2)/max(sum(errorVector.^2),realmin));
nrmseRobust = sqrt(mse)/robustSpan;

% Global-statistics SSIM. This is not MATLAB's local-window ssim metric.
dynamicRange = max(peak,1);
C1 = (0.01*dynamicRange)^2;
C2 = (0.03*dynamicRange)^2;
sourceMean = mean(sourceVector);
reconstructionMean = mean(reconstructed(:));
sourceVariance = mean((sourceVector-sourceMean).^2);
reconstructionVariance = mean((reconstructed(:)-reconstructionMean).^2);
covariance = mean((sourceVector-sourceMean).* ...
    (reconstructed(:)-reconstructionMean));
ssimValue = ((2*sourceMean*reconstructionMean+C1)*(2*covariance+C2))/ ...
    ((sourceMean^2+reconstructionMean^2+C1)* ...
    (sourceVariance+reconstructionVariance+C2));
end
