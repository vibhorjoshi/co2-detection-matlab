function [co2_index, hotspot_mask] = co2_cibr()

clc; close all;

%% ============================================
% STEP 1: FILE PATHS (ENVI DATA)
%% ============================================

hdr_file = 'D:\downloads\co2-detection-hyperspectral-main\f250923t01p00r13_rfl.hdr';
bin_file = 'D:\downloads\co2-detection-hyperspectral-main\f250923t01p00r13_rfl.bin';

assert(isfile(hdr_file), 'HDR file missing');
assert(isfile(bin_file), 'BIN file missing');

%% ============================================
% STEP 2: LOAD DATA (CORRECT METHOD)
%% ============================================

hcube = hypercube(bin_file, hdr_file);

% ⚠️ DO NOT load full 38GB blindly
cube = double(gather(cropData(hcube, [1 1000], [1 1000])));

wavelength = double(hcube.Wavelength);

[rows, cols, bands] = size(cube);
fprintf('Loaded subset: %d x %d x %d\n', rows, cols, bands);

%% ============================================
% STEP 3: SCALE + CLEAN
%% ============================================

if max(cube(:)) > 10
    cube = cube / 10000;
end

cube(cube <= 0) = NaN;

%% ============================================
% STEP 4: DOWNSAMPLE
%% ============================================

cube = cube(1:5:end, 1:5:end, :);

%% ============================================
% STEP 5: CO₂ BAND SELECTION
%% ============================================

band_left   = find(wavelength >= 2000 & wavelength <= 2020);
band_absorb = find(wavelength >= 2040 & wavelength <= 2060);
band_right  = find(wavelength >= 2080 & wavelength <= 2100);

if isempty(band_left) || isempty(band_absorb) || isempty(band_right)
    error('CO₂ bands not found');
end

band_left   = round(mean(band_left));
band_absorb = round(mean(band_absorb));
band_right  = round(mean(band_right));

%% ============================================
% STEP 6: CIBR
%% ============================================

img_left   = cube(:, :, band_left);
img_absorb = cube(:, :, band_absorb);
img_right  = cube(:, :, band_right);

continuum = (img_left + img_right) / 2;
co2_index = continuum ./ (img_absorb + eps);

%% ============================================
% STEP 7: NORMALIZE
%% ============================================

co2_index = co2_index - nanmin(co2_index(:));
co2_index = co2_index / (nanmax(co2_index(:)) + eps);

%% ============================================
% STEP 8: THRESHOLD
%% ============================================

threshold = graythresh(co2_index);
hotspot_mask = co2_index > threshold;

%% ============================================
% STEP 9: DISPLAY
%% ============================================

figure;
imagesc(co2_index);
colorbar;
title('CIBR CO₂ Index');

figure;
imshow(hotspot_mask);
title('Hotspots');

fprintf('Done ✅\n');

end
