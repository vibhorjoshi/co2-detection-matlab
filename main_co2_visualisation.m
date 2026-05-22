clc;

% 2.1 Run each detection method
[idx_cibr, mask_cibr] = co2_cibr();
[idx_ctmf, mask_ctmf] = co2_ctmf();
[idx_jrge, mask_jrge] = co2_jrge();
[idx_sfa,  mask_sfa ] = co2_sfa();

% 2.2 Display Index Maps side‑by‑side
figure('Name','CO₂ Index Maps','NumberTitle','off');
methods = {'CIBR','CTMF','JRGE','SFA'};
idx_maps = {idx_cibr,idx_ctmf,idx_jrge,idx_sfa};
for i = 1:4
    subplot(2,2,i);
    imagesc(idx_maps{i});
    colormap(jet); colorbar; axis image off;
    title([methods{i} ' Index']);
end

% 2.3 Display Hotspot Masks
figure('Name','CO₂ Hotspot Masks','NumberTitle','off');
hs_maps = {mask_cibr,mask_ctmf,mask_jrge,mask_sfa};
for i = 1:4
    subplot(2,2,i);
    imshow(hs_maps{i});
    title([methods{i} ' Hotspots']);
end

% 2.4 Basic Statistics
for i = 1:4
    idx = idx_maps{i};
    th = mean(idx(:)) + std(idx(:));
    pct = sum(idx(:)>th)/numel(idx)*100;
    fprintf('%s: mean=%.3f, max=%.3f, hotspot%%=%.1f%%\n', ...
        methods{i}, mean(idx(:)), max(idx(:)), pct);
end

% 2.5 Geospatial Mapping of CO₂ Hotspots 
ulx = 314881.49;     % Upper-left Easting from .hdr
uly = 4218923.9;     % Upper-left Northing from .hdr
pixel_size = 14.1 * 5; 

rows = size(hs_maps{1}, 1);
cols = size(hs_maps{1}, 2);

% Compute X and Y world coordinates
xWorld = ulx + (0:cols-1) * pixel_size;     % Easting
yWorld = uly - (0:rows-1) * pixel_size;     % Northing

% Plot geospatial hotspot maps
figure('Name','Geospatial Mapping of CO₂ Hotspots','NumberTitle','off');
for i = 1:4
    subplot(2,2,i);
    imagesc(xWorld, yWorld, double(hs_maps{i}));
    axis image;
    set(gca, 'YDir', 'normal');  %  map orientation
    colormap(gray);
    title([methods{i} ' Geospatial Hotspots']);
    xlabel('Easting (m)');
    ylabel('Northing (m)');
end
