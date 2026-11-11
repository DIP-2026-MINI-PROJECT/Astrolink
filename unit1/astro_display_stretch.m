function [displayImage, intensityLimits] = astro_display_stretch( ...
    scienceImage, intensityLimits, percentiles, softeningFraction)
%ASTRO_DISPLAY_STRETCH Make a display-only, percentile-limited asinh copy.
%   [DISPLAYIMAGE, LIMITS] = ASTRO_DISPLAY_STRETCH(SCIENCEIMAGE) maps finite
%   values through an asinh stretch. The input array is never modified.
%   LIMITS default to the 1st and 99.7th finite-value percentiles.
%
%   Optional inputs are LIMITS (a shared [low high] pair, or [] to compute
%   limits), PERCENTILES, and SOFTENINGFRACTION (default 0.02). The
%   softening scale is SOFTENINGFRACTION times the intensity range.
%   NaNs map to the display floor; infinities are clipped to the limits.

if nargin < 2
    intensityLimits = [];
end
if nargin < 3 || isempty(percentiles)
    percentiles = [1 99.7];
end
if nargin < 4 || isempty(softeningFraction)
    softeningFraction = 0.02;
end

if ~isnumeric(scienceImage) || ~isreal(scienceImage) || isempty(scienceImage)
    error("astro_display_stretch:InvalidImage", ...
        "scienceImage must be a nonempty, real numeric array.");
end
if ~isnumeric(percentiles) || numel(percentiles) ~= 2 || ...
        any(~isfinite(percentiles)) || percentiles(1) < 0 || ...
        percentiles(2) > 100 || percentiles(1) >= percentiles(2)
    error("astro_display_stretch:InvalidPercentiles", ...
        "percentiles must be an increasing pair between 0 and 100.");
end
if ~isnumeric(softeningFraction) || ~isscalar(softeningFraction) || ...
        ~isfinite(softeningFraction) || softeningFraction <= 0
    error("astro_display_stretch:InvalidSoftening", ...
        "softeningFraction must be a positive finite scalar.");
end
if ~isempty(intensityLimits) && ...
        (~isnumeric(intensityLimits) || numel(intensityLimits) ~= 2 || ...
        any(~isfinite(intensityLimits)) || intensityLimits(1) > intensityLimits(2))
    error("astro_display_stretch:InvalidLimits", ...
        "intensityLimits must be an increasing pair of finite values.");
end

finiteValues = double(scienceImage(isfinite(scienceImage)));
displayImage = zeros(size(scienceImage), "double");
if isempty(finiteValues)
    if isempty(intensityLimits)
        intensityLimits = [0 1];
    end
    return;
end

if isempty(intensityLimits)
    sortedValues = sort(finiteValues(:));
    intensityLimits = [interpolatedPercentile(sortedValues, percentiles(1)), ...
        interpolatedPercentile(sortedValues, percentiles(2))];
end
intensityLimits = double(intensityLimits(:)');

if intensityLimits(1) == intensityLimits(2)
    halfWidth = max(abs(intensityLimits(1)), 1) * sqrt(eps);
    intensityLimits = intensityLimits(1) + [-halfWidth halfWidth];
end

softeningScale = softeningFraction * diff(intensityLimits);
transformedLimits = asinh(intensityLimits / softeningScale);
boundedImage = min(max(double(scienceImage), intensityLimits(1)), ...
    intensityLimits(2));
displayImage = (asinh(boundedImage / softeningScale) - ...
    transformedLimits(1)) / diff(transformedLimits);
displayImage(~isfinite(displayImage)) = 0;
displayImage = min(max(displayImage, 0), 1);
end

function value = interpolatedPercentile(sortedValues, percentile)
position = (percentile / 100) * (numel(sortedValues) - 1) + 1;
lowerIndex = floor(position);
upperIndex = ceil(position);
fraction = position - lowerIndex;
value = sortedValues(lowerIndex) + fraction * ...
    (sortedValues(upperIndex) - sortedValues(lowerIndex));
end
