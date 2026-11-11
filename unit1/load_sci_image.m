function scienceImage = load_sci_image(datasetName)
    %LOAD_SCI_IMAGE  Load the science image of a dataset.
    %   scienceImage = LOAD_SCI_IMAGE(datasetName) reads
    %   the science image of the dataset named datasetName
    %   ("orion" or "m51") and returns its pixel values.
    %
    %   The original FITS files are only read, never
    %   modified. Every Unit 1 script calls this
    %   function, so the FITS loading work is written
    %   once and reused.
    %
    %   The two datasets have different FITS layouts:
    %     Orion: the science image is an image EXTENSION
    %            named SCI of a multi-extension file.
    %     M51:   the science image is the PRIMARY data
    %            array of a single-HDU file.

    % Use the Orion dataset if no name is given.
    if nargin < 1
        datasetName = "orion";
    end

    % Find the project root: this file is in unit1/.
    functionPath = string(mfilename("fullpath"));
    projectRoot = fileparts(fileparts(functionPath));

    % Full path of the FITS file for each dataset.
    switch datasetName
        case "orion"
            fitsFile = fullfile(projectRoot, "data", "orion", ...
                "MAST_2026-10-09T0632", "HST", "u2id010gt_drz.fits");
        case "m51"
            fitsFile = fullfile(projectRoot, "data", "m51", ...
                "h_m51_b_s20_drz_sci.fits");
        otherwise
            error("Unknown dataset: %s (use 'orion' or 'm51')", ...
                datasetName);
    end

    % fitsinfo reads the FITS metadata.
    info = fitsinfo(fitsFile);

    if info.PrimaryData.DataSize > 0
        % Layout B (M51): the science image is the
        % primary data array, so fitsread without
        % options reads it directly.
        scienceImage = fitsread(fitsFile);
    else
        % Layout A (Orion): the primary HDU is empty
        % and the science image is an image extension
        % whose EXTNAME keyword is "SCI".
        scienceIndex = NaN;
        for i = 1:numel(info.Image)
            keywords = info.Image(i).Keywords;
            for j = 1:size(keywords, 1)
                if strcmp(keywords{j, 1}, "EXTNAME") && ...
                        strcmp(keywords{j, 2}, "SCI")
                    scienceIndex = i;
                end
            end
        end

        % Stop with a clear message if SCI is missing.
        if isnan(scienceIndex)
            error("SCI extension not found in %s", fitsFile);
        end

        % fitsread reads the pixel values of one image
        % extension. Syntax: fitsread(filename, "image", index)
        scienceImage = fitsread(fitsFile, "image", scienceIndex);
    end
end
