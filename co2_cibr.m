function [co2_index, hotspot_mask] = co2_cibr()

clc;
close all;

%% ==========================================================
% STEP 1: FILE PATHS
%% ==========================================================

hdr_file = ...
'D:\downloads\co2-detection-hyperspectral-main\f250923t01p00r13_rfl.hdr';

bin_file = ...
'D:\downloads\co2-detection-hyperspectral-main\f250923t01p00r13_rfl.bin';

assert(isfile(hdr_file), 'HDR file missing');
assert(isfile(bin_file), 'BIN file missing');

fprintf('Files found ✓\n');

%% ==========================================================
% STEP 2: READ METADATA ONLY
%% ==========================================================

txt = fileread(hdr_file);

samples = sscanf( ...
regexp(txt,'samples\s*=\s*(\d+)','match','once'), ...
'samples = %d');

lines = sscanf( ...
regexp(txt,'lines\s*=\s*(\d+)','match','once'), ...
'lines = %d');

bands = sscanf( ...
regexp(txt,'bands\s*=\s*(\d+)','match','once'), ...
'bands = %d');

fprintf('Metadata: %d x %d x %d\n', ...
lines,samples,bands);

%% ==========================================================
% STEP 3: LOAD SUBSET ONLY
%% ==========================================================

subset_rows = 1000;
subset_cols = 1000;

cube = multibandread( ...
bin_file,...
[lines samples bands],...
'single',...
0,...
'bsq',...
'ieee-le',...
{'Row','Range',[1 subset_rows]},...
{'Column','Range',[1 subset_cols]});

cube = double(cube);

fprintf('Loaded subset: %d x %d x %d\n', ...
size(cube));

%% ==========================================================
% STEP 4: READ WAVELENGTHS
%% ==========================================================

expr = 'wavelength\s*=\s*\{([^}]*)\}';

tokens = regexp(txt,expr,'tokens');

wl_text = tokens{1}{1};

wavelength = sscanf(wl_text,'%f,');

if isempty(wavelength)

    wavelength = 1:bands;

end

fprintf('Loaded wavelengths: %d\n', ...
length(wavelength));

%% ==========================================================
% STEP 5: CLEAN DATA
%% ==========================================================

cube(cube<0)=NaN;

cube(cube>2)=NaN;

cube(isinf(cube))=NaN;

cube = cube(1:5:end,1:5:end,:);

[rows,cols,bands] = size(cube);

%% ==========================================================
% STEP 6: CO2 BANDS
%% ==========================================================

band_left = ...
find(wavelength>=2000 & wavelength<=2020);

band_absorb = ...
find(wavelength>=2040 & wavelength<=2060);

band_right = ...
find(wavelength>=2080 & wavelength<=2100);

if isempty(band_left)

    band_left=176;

end

if isempty(band_absorb)

    band_absorb=180;

end

if isempty(band_right)

    band_right=184;

end

band_left = round(mean(band_left));

band_absorb = round(mean(band_absorb));

band_right = round(mean(band_right));

fprintf('Bands: %d %d %d\n', ...
band_left,...
band_absorb,...
band_right);

%% ==========================================================
% STEP 7: EXTRACT
%% ==========================================================

left = cube(:,:,band_left);

absorb = cube(:,:,band_absorb);

right = cube(:,:,band_right);

left(left<=0)=NaN;

absorb(absorb<=0)=NaN;

right(right<=0)=NaN;

%% ==========================================================
% DEBUG
%% ==========================================================

fprintf( ...
'LEFT min %.4f max %.4f\n', ...
min(left(:)),...
max(left(:)));

fprintf( ...
'ABSORB min %.4f max %.4f\n', ...
min(absorb(:)),...
max(absorb(:)));

fprintf( ...
'RIGHT min %.4f max %.4f\n', ...
min(right(:)),...
max(right(:)));

%% ==========================================================
% STEP 8: IMPROVED CIBR
%% ==========================================================

continuum = (left+right)/2;

co2_index = continuum - absorb;

co2_index(isnan(co2_index))=0;

co2_index(isinf(co2_index))=0;

%% ==========================================================
% STEP 9: CONTRAST ENHANCEMENT
%% ==========================================================

p2 = prctile( ...
co2_index(:),2);

p98 = prctile( ...
co2_index(:),98);

co2_index = ...
(co2_index-p2)/...
(p98-p2+eps);

co2_index(co2_index<0)=0;

co2_index(co2_index>1)=1;

%% ==========================================================
% STEP 10: SPATIAL FILTER
%% ==========================================================

co2_index = medfilt2( ...
co2_index,...
[3 3]);

%% ==========================================================
% STEP 11: THRESHOLD
%% ==========================================================

thr = graythresh(co2_index);

hotspot_mask = ...
co2_index>thr;

hotspot_mask = ...
bwareaopen( ...
hotspot_mask,...
10);

%% ==========================================================
% STEP 12: VISUALIZATION
%% ==========================================================

figure;

imagesc(co2_index);

axis image;

colormap(jet);

colorbar;

title('Improved CIBR CO2');

figure;

imshow(hotspot_mask);

title('Hotspots');

fprintf('Done\n');

end
