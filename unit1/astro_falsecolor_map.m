function colorMap = astro_falsecolor_map(count)
%ASTRO_FALSECOLOR_MAP Single-image display palette; not astronomical RGB.

if nargin < 1
    count = 256;
end
if ~isnumeric(count) || ~isscalar(count) || ~isfinite(count) || ...
        count < 2 || count ~= floor(count)
    error("astro_falsecolor_map:InvalidCount", ...
        "count must be an integer greater than or equal to 2.");
end

stops = [0 0.16 0.34 0.52 0.70 0.86 1];
colors = [ ...
    0.008 0.012 0.055
    0.025 0.100 0.430
    0.000 0.570 0.780
    0.280 0.820 0.840
    0.980 0.720 0.260
    0.880 0.260 0.090
    1.000 0.910 0.720];
colorMap = interp1(stops, colors, linspace(0, 1, count), "linear");
end
