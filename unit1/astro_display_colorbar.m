function astro_display_colorbar(colorbarHandle, intensityLimits, ...
    softeningFraction, unitLabel, textColor)
%ASTRO_DISPLAY_COLORBAR Label asinh display levels with source intensities.

if nargin < 5
    textColor = [0.93 0.94 0.96];
end

ticks = 0:0.25:1;
softeningScale = softeningFraction * diff(intensityLimits);
transformedLimits = asinh(intensityLimits / softeningScale);
tickIntensities = softeningScale .* sinh(transformedLimits(1) + ...
    ticks .* diff(transformedLimits));

colorbarHandle.Ticks = ticks;
colorbarHandle.TickLabels = compose("%.4g", tickIntensities);
colorbarHandle.Color = textColor;
colorbarHandle.FontSize = 9;
colorbarHandle.Label.String = sprintf( ...
    "Intensity (%s; asinh display stretch)", unitLabel);
colorbarHandle.Label.Color = textColor;
end
