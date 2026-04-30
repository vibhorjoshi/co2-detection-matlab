function [gas_map, binary_hotspots] = co2_jrge()

clc; close all;

% STEP 1: Load hyperspectral data
%% ----------------------------------

hdr_file = 'D:\downloads\co2-detection-hyperspectral-main\AVIRIS-Classic_L2_Reflectance.f130503t01p00r23rdn_refl_img_corr.hdr';

% Load using hypercube
hcube = hypercube(hdr_file);

% 🔥 IMPORTANT: load full cube (not preview)
cube = double(gather(hcube));
wavelength = double(hcube.Wavelength);

[rows, cols, bands] = size(cube);
fprintf('Loaded cube: %d x %d x %d\n', rows, cols, bands);

%% ----------------------------------
% STEP 2: FIX DATA SCALING (CRITICAL)

% Many AVIRIS datasets are scaled (0–10000)
if max(cube(:)) > 10
    cube = cube / 10000;   % convert to 0–1 reflectance
end

% Remove invalid values safely
cube(cube <= 0) = NaN;
cube(cube > 1) = NaN;

%% ----------------------------------
% STEP 3: Downsample (faster processing)
%% ----------------------------------

ds = 5;
cube = cube(1:ds:end, 1:ds:end, :);
[rows, cols, bands] = size(cube);

%% ----------------------------------
% STEP 4: Reshape
%% ----------------------------------

reshapedData = reshape(cube, [], bands);

%% ----------------------------------
% STEP 5: Smooth reflectance
%% ----------------------------------

reflectance_estimate = reshapedData;

for i = 1:size(reshapedData,1)

    spectrum = reshapedData(i,:);

    if any(isnan(spectrum)) || std(spectrum)==0
        continue;
    end

    % slightly reduced smoothing → better accuracy
    reflectance_estimate(i,:) = ...
        fnval(csaps(1:bands, spectrum, 0.9), 1:bands);
end

%% ----------------------------------
% STEP 6: CO₂ band selection (correct)
%% ----------------------------------

% Try real CO₂ band (~2000 nm)
absorp_band = find(wavelength >= 2000 & wavelength <= 2100);

% fallback if not present
if isempty(absorp_band)
    warning('CO₂ band not found → using proxy band');
    absorp_band = find(wavelength >= 640 & wavelength <= 660);
end

% final safety fallback
if isempty(absorp_band)
    absorp_band = round(bands/2);
end

%% ----------------------------------
% STEP 7: Gas estimation (robust)
%% ----------------------------------

gas_density = median(reflectance_estimate(:, absorp_band), 2) - ...
              median(reshapedData(:, absorp_band), 2);

%% ----------------------------------
% STEP 8: Iterative refinement
%% ----------------------------------

for iter = 1:3

    reflectance_estimate = reflectance_estimate + ...
        0.05 * (reshapedData - reflectance_estimate);

    gas_density = median(reflectance_estimate(:, absorp_band), 2) - ...
                  median(reshapedData(:, absorp_band), 2);
end

%% ----------------------------------
% STEP 9: Reshape
%% ----------------------------------

gas_map = reshape(gas_density, rows, cols);

%% ----------------------------------
% STEP 10: Normalize safely
%% ----------------------------------

gas_map = gas_map - nanmin(gas_map(:));
gas_map = gas_map / (nanmax(gas_map(:)) + eps);

%% ----------------------------------
% STEP 11: Thresholding
%% ----------------------------------

threshold = graythresh(gas_map);
binary_hotspots = gas_map > threshold;

%% ----------------------------------
% STEP 12: Visualization

figure;
imagesc(gas_map);
colorbar;
title('JRGE Gas Density Map');

figure;
imshow(binary_hotspots);
title('Detected Hotspots');

fprintf('Done ✅\n');

end
