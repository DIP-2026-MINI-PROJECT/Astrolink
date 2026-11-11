function scienceImage = load_sci_image(datasetName)
    %LOAD_SCI_IMAGE Load one configured astronomical FITS science image.
    %   scienceImage = LOAD_SCI_IMAGE(datasetName) returns a 2-D numeric
    %   image for orion, m51, bug_nebula, eagle_nebula, m35, or venus.
    %   FITS input files are read only. Integer and single-precision FITS
    %   data are returned by fitsread as double for downstream arithmetic.
    %
    %   Most configured files store the science image in the primary HDU.
    %   Orion has an empty primary HDU and its SCI image in image extension 1.
    %   The loader is shared by the Unit 1 exercises and integrated pipeline.

    if nargin < 1 || strlength(string(datasetName)) == 0
        datasetName = "orion";
    end
    datasetName = lower(string(datasetName));

    % This file is in unit1/, so resolve data paths from the project root.
    functionPath = string(mfilename("fullpath"));
    projectRoot = fileparts(fileparts(functionPath));

    switch datasetName
        case "orion"
            fitsFile = fullfile(projectRoot, "data", "orion", ...
                "MAST_2026-10-09T0632", "HST", "u2id010gt_drz.fits");
        case "m51"
            fitsFile = fullfile(projectRoot, "data", "m51", ...
                "h_m51_b_s20_drz_sci.fits");
        case "bug_nebula"
            fitsFile = fullfile(projectRoot, "data", "Bug Nebula", ...
                "656nmos.fits");
        case "eagle_nebula"
            fitsFile = fullfile(projectRoot, "data", "Eagle Nebula", ...
                "502nmos.fits");
        case "m35"
            fitsFile = fullfile(projectRoot, "data", "Mesier 35 Cluster", ...
                "m35_40min_blue.fits");
        case "venus"
            fitsFile = fullfile(projectRoot, "data", "Ultraviolet Venus", ...
                "218wmos.fits");
        otherwise
            error("Unknown dataset '%s'. Use orion, m51, bug_nebula, " + ...
                "eagle_nebula, m35, or venus.", datasetName);
    end

    if ~isfile(fitsFile)
        error("FITS file for dataset '%s' was not found: %s", ...
            datasetName, fitsFile);
    end

    info = fitsinfo(fitsFile);
    primarySize = info.PrimaryData.Size;
    if ~isempty(primarySize) && numel(primarySize) == 2 && ...
            all(primarySize > 1)
        % M51, Bug, Eagle, M35, and Venus use a 2-D primary image.
        % Some include an ASCII-table extension, which is not the science plane.
        scienceImage = fitsread(fitsFile);
        return;
    end

    % Orion's primary HDU is empty. Select the named SCI image extension;
    % do not accidentally load the WHT or CTX companion extensions.
    scienceIndex = NaN;
    if isfield(info, "Image")
        for i = 1:numel(info.Image)
            keywords = info.Image(i).Keywords;
            for j = 1:size(keywords, 1)
                if strcmpi(string(keywords{j, 1}), "EXTNAME") && ...
                        strcmpi(string(keywords{j, 2}), "SCI")
                    scienceIndex = i;
                    break;
                end
            end
            if ~isnan(scienceIndex), break; end
        end
    end
    if isnan(scienceIndex)
        error("No 2-D primary image or SCI image extension found in %s", ...
            fitsFile);
    end
    scienceImage = fitsread(fitsFile, "image", scienceIndex);
end
