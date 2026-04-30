function [co2_map, binary_map] = co2_sfa(hcube, threshold)

%% ---- Input validation --------------------------------------------------
    arguments
        hcube     (1,1)
        threshold (1,1) double {mustBePositive} = 1.0
    end

%% ---- Setup -------------------------------------------------------------
    wavelengths = hcube.Wavelength;
    datacube    = double(hcube.DataCube);
    [nRows, nCols, ~] = size(datacube);

%% ---- Select SWIR window covering both CO2 bands (1500–2100 nm) --------
    swir_mask = wavelengths >= 1500 & wavelengths <= 2100;
    swir_idx  = find(swir_mask);
    wl_swir   = wavelengths(swir_idx);
    n_swir    = numel(swir_idx);

    if n_swir < 10
        error('co2_sfa:insufficientBands', ...
            'Fewer than 10 bands found in 1500-2100 nm. Insufficient for SFA.');
    end

    fprintf('SFA: working with %d SWIR bands (%.0f–%.0f nm).\n', ...
        n_swir, wl_swir(1), wl_swir(end));

%% ---- Build dual-Gaussian CO2 reference absorption spectrum ------------
%   CO2 bands: 1.6 µm (~1575 nm, weaker) and 2.0 µm (~2005 nm, stronger)
%   The reference represents fractional absorption depth (positive = absorbed).

    amp1    = 0.30;   cen1 = 1575;  sig1 = 15;   % 1.6 µm band
    amp2    = 0.70;   cen2 = 2005;  sig2 = 12;   % 2.0 µm band  (dominant)

    ref_spectrum = amp1 * exp(-0.5*((wl_swir - cen1)/sig1).^2) + ...
                   amp2 * exp(-0.5*((wl_swir - cen2)/sig2).^2);

    % Normalise reference to unit length
    ref_norm = ref_spectrum / norm(ref_spectrum);

%% ---- Normalised cross-correlation pixel-wise --------------------------
    co2_map = zeros(nRows, nCols);

    swir_data = datacube(:,:,swir_idx);   % [R x C x nSWIR]

    for r = 1:nRows
        for c = 1:nCols
            spec  = swir_data(r, c, :);
            spec  = double(spec(:));   % [nSWIR x 1]

            s_std = std(spec);
            if s_std < 1e-10
                co2_map(r,c) = 0;
                continue;
            end

            % Normalised cross-correlation at zero lag
            spec_norm       = (spec - mean(spec)) / s_std;
            ref_norm_zero   = ref_norm - mean(ref_norm);
            co2_map(r,c)    = dot(spec_norm, ref_norm_zero) / n_swir;
        end
    end

    % Clip negatives (anti-correlated pixels) and normalise to [0, 1]
    co2_map(co2_map < 0) = 0;
    mx = max(co2_map(:));
    if mx > 0
        co2_map = co2_map / mx;
    end

%% ---- Binary detection map (Otsu) -------------------------------------
    t_otsu     = graythresh(co2_map) * threshold;
    binary_map = co2_map > t_otsu;

    fprintf('SFA complete. Otsu threshold = %.4f | Detections = %d / %d pixels\n', ...
        t_otsu, sum(binary_map(:)), nRows*nCols);
end
