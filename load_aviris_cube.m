function [cube, wavelengths, nR, nC, nB] = load_aviris_cube( ...
    binFile, hdrFile, cropRow, nCropRows, cropCol, nCropCols, dsample, scale)
%% ==========================================================
% DEFAULT PARAMETERS
%% ==========================================================
if nargin == 0
    hdrFile = ...
'D:\downloads\co2-detection-hyperspectral-main\f250923t01p00r13_rfl.hdr';
    binFile = ...
'D:\downloads\co2-detection-hyperspectral-main\f250923t01p00r13_rfl.bin';
    cropRow = 1;
    cropCol = 1;
    nCropRows = inf;
    nCropCols = inf;
    dsample = 5;
    scale = 1e-4;
end

%% ==========================================================
% CHECK FILES
%% ==========================================================
assert(isfile(hdrFile), 'HDR file missing');
assert(isfile(binFile), 'BIN file missing');
fprintf('Files found ✓\n');

%% ==========================================================
% READ HEADER
%% ==========================================================
hdr = local_parse_hdr(hdrFile);
nLines   = hdr.lines;
nSamples = hdr.samples;
nBands   = hdr.bands;
wl       = hdr.wavelength(:)';

%% ==========================================================
% BYTE ORDER
%% ==========================================================
if hdr.byte_order == 0
    byteOrder = 'ieee-le';
else
    byteOrder = 'ieee-be';
end

%% ==========================================================
% DATA TYPE
%% ==========================================================
switch hdr.data_type
    case 1
        bpv = 1;
        fmt = '*uint8';
    case 2
        bpv = 2;
        fmt = '*int16';
    case 3
        bpv = 4;
        fmt = '*int32';
    case 4
        bpv = 4;
        fmt = '*single';
    case 5
        bpv = 8;
        fmt = '*double';
    case 12
        bpv = 2;
        fmt = '*uint16';
    otherwise
        error('Unsupported ENVI datatype');
end

%% ==========================================================
% CROP LIMITS
%% ==========================================================
cropRow = max(1,cropRow);
cropCol = max(1,cropCol);
if isinf(nCropRows)
    nCropRows = nLines-cropRow+1;
end
if isinf(nCropCols)
    nCropCols = nSamples-cropCol+1;
end
nCropRows = min(nCropRows, nLines-cropRow+1);
nCropCols = min(nCropCols, nSamples-cropCol+1);

%% ==========================================================
% OPEN FILE
%% ==========================================================
fid = fopen(binFile,'rb',byteOrder);
if fid < 0
    error('Cannot open binary file');
end
headerOffset = int64(hdr.header_offset);
bandStride   = int64(nLines) * int64(nSamples) * int64(bpv);
rowStride    = int64(nSamples) * int64(bpv);
colOffset    = int64(cropCol-1) * int64(bpv);

%% ==========================================================
% SETUP DOWNSAMPLED DIMENSIONS & PREALLOCATE FINAL CUBE
%% ==========================================================
nRd = floor(nCropRows / dsample);
nCd = floor(nCropCols / dsample);
% Preallocate ONLY the final, downsampled cube to save memory
cube = zeros(nRd, nCd, nBands, 'single');

%% ==========================================================
% READ, SCALE, AND DOWNSAMPLE BAND BY BAND
%% ==========================================================
for b = 1:nBands
    % 1. Allocate temporary storage for JUST this band's cropped region
    tempBand = zeros(nCropRows, nCropCols, 'single');
    
    startPos = headerOffset + ...
               int64(b-1)*bandStride + ...
               int64(cropRow-1)*rowStride + ...
               colOffset;
               
    % 2. Read the band data
    for r = 1:nCropRows
        pos = startPos + int64(r-1)*rowStride;
        fseek(fid, double(pos), 'bof');
        rowData = fread(fid, nCropCols, fmt);
        if numel(rowData) < nCropCols
            rowData(end+1:nCropCols) = 0;
        end
        tempBand(r, :) = single(rowData(:)');
    end
    
    % 3. Scale reflectance immediately for this specific band
    tempBand = tempBand * single(scale);
    tempBand(tempBand < 0) = 0;
    tempBand(tempBand > 1.25) = 0;
    
    % 4. Downsample and store directly into the final cube
    if dsample > 1
        for r = 1:nRd
            rr = (r-1)*dsample+1 : r*dsample;
            for c = 1:nCd
                cc = (c-1)*dsample+1 : c*dsample;
                cube(r, c, b) = mean(mean(tempBand(rr, cc), 1), 2);
            end
        end
    else
        cube(:, :, b) = tempBand;
    end
end
fclose(fid);

%% ==========================================================
% OUTPUTS
%% ==========================================================
wavelengths = double(wl);
[nR,nC,nB] = size(cube);
fprintf('\nCube size : %d × %d × %d\n', nR, nC, nB);
fprintf('Wavelength range : %.1f – %.1f nm\n', wavelengths(1), wavelengths(end));
end % <--- THIS 'END' WAS MISSING AND CAUSED THE ERROR

%% ==========================================================
% HEADER PARSER
%% ==========================================================
function hdr = local_parse_hdr(hdrFile)
hdr = struct( ...
    'lines',1,...
    'samples',1,...
    'bands',1,...
    'data_type',2,...
    'byte_order',1,...
    'header_offset',0,...
    'wavelength',[]);
fid = fopen(hdrFile,'rt');
if fid<0
    error('Cannot open header');
end
txt = fread(fid,'*char')';
fclose(fid);
hdr.lines = hget_int(txt,'lines');
hdr.samples = hget_int(txt,'samples');
hdr.bands = hget_int(txt,'bands');
hdr.data_type = hget_int(txt,'data type');
hdr.byte_order = hget_int(txt,'byte order');
hdr.header_offset = hget_int(txt,'header offset');
hdr.wavelength = hget_list(txt,'wavelength');
if numel(hdr.wavelength) ~= hdr.bands
    warning('Wavelength count mismatch');
    hdr.wavelength = linspace(370,2500,hdr.bands);
end
end

%% ==========================================================
function val = hget_int(str,key)
tok = regexp(str,[key '\s*=\s*(\d+)'],'tokens','ignorecase');
if isempty(tok)
    val = 0;
else
    val = str2double(tok{1}{1});
end
end

%% ==========================================================
function vals = hget_list(str,key)
tok = regexp( ...
    str,...
    [key '\s*=\s*\{([^}]*)\}'],...
    'tokens',...
    'ignorecase',...
    'dotall');
if isempty(tok)
    vals = [];
else
    vals = str2double( ...
        strsplit( ...
        strtrim(tok{1}{1}), ',' ));
end
end