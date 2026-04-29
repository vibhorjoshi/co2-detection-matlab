function [mf_image, binaryMap] = co2_ctmf()

%% Load data
hdrPath = 'D:\downloads\co2-detection-hyperspectral-main\GLREFL_Cape_Cod_Jun2016_7_at-sensor_refl_L1G\GLREFL_Cape_Cod_Jun2016_7_at-sensor_refl_L1G.hdr';

hcube = hypercube(hdrPath);
cube = double(gather(hcube)); 
wavelength = hcube.Wavelength;

% Downsample
cube = cube(1:5:end, 1:5:end, :);
[rows, cols, b] = size(cube);

reshapedData = reshape(cube, [], b);

fprintf('Data loaded: %d x %d x %d\n', rows, cols, b);

%% Band selection (valid for your dataset)
band_center = find(wavelength >= 750 & wavelength <= 770);
band_left   = find(wavelength >= 730 & wavelength <= 740);
band_right  = find(wavelength >= 780 & wavelength <= 800);

if isempty(band_center), band_center = round(b/2); end
if isempty(band_left),   band_left   = band_center-2; end
if isempty(band_right),  band_right  = band_center+2; end

%% Signature
left_spec  = mean(reshapedData(:, band_left), 2);
right_spec = mean(reshapedData(:, band_right), 2);
continuum  = (left_spec + right_spec) / 2;

absorp_spec = mean(reshapedData(:, band_center), 2);
signature_value = mean(continuum - absorp_spec);

co2_signature = zeros(1, b);
co2_signature(band_center) = signature_value;
co2_signature = co2_signature / (norm(co2_signature) + eps);

%% Clustering
k = 4;
clusterIdx = simple_kmeans(reshapedData, k, 20);
%% Matched filter
mf_output = zeros(size(reshapedData,1),1);

for i = 1:k
    idx = (clusterIdx == i);
    clusterData = reshapedData(idx,:);

    if isempty(clusterData)
        continue;
    end

    C = cov(clusterData) + eye(b)*1e-6;
    mf_output(idx) = clusterData * (C \ co2_signature');
end

%% Output
mf_image = reshape(mf_output, rows, cols);
mf_image = mat2gray(mf_image);

threshold = graythresh(mf_image);
binaryMap = imbinarize(mf_image, threshold);

%% Visualization
figure;
imagesc(mf_image); colorbar;
title('CTMF Detection Map');

figure;
imshow(binaryMap);
title('Detected Hotspots');

end

function idx = simple_kmeans(X, k, maxIter)

[n, d] = size(X);

% Random initialization
rng(1);
centroids = X(randperm(n, k), :);

idx = zeros(n,1);

for iter = 1:maxIter
    
    % Assign clusters
    for i = 1:n
        distances = sum((centroids - X(i,:)).^2, 2);
        [~, idx(i)] = min(distances);
    end
    
    % Update centroids
    new_centroids = zeros(k, d);
    for j = 1:k
        points = X(idx == j, :);
        if ~isempty(points)
            new_centroids(j,:) = mean(points,1);
        else
            new_centroids(j,:) = centroids(j,:);
        end
    end
    
    % Stop if converged
    if norm(new_centroids - centroids) < 1e-6
        break;
    end
    
    centroids = new_centroids;
end

end
