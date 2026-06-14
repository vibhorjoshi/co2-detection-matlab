function map_spatial_overlay(scoreMap, hotMask)
    % =====================================================
    % AVIRIS metadata (from header)
    % =====================================================
    ulx = 577561.590;
    uly = 4228899.200;
    pixelSize = 14.4;
    utmZone = '11N';
    
    % =====================================================
    % Find hotspot pixels
    % =====================================================
    [row, col] = find(hotMask);
    scores = scoreMap(sub2ind(size(scoreMap), row, col));
    
    % =====================================================
    % Pixel coordinates -> UTM coordinates
    % =====================================================
    X = ulx + (col-1)*pixelSize;
    Y = uly - (row-1)*pixelSize;
    
    % =====================================================
    % UTM -> Latitude / Longitude
    % =====================================================
    utmstruct = defaultm('utm');
    utmstruct.zone = utmZone;
    utmstruct.geoid = wgs84Ellipsoid;
    utmstruct = defaultm(utmstruct);
    [lat, lon] = minvtran(utmstruct, X, Y);
    
    % =====================================================
    % Satellite basemap
    % =====================================================
    figure('Color', 'white');
    geobasemap satellite
    hold on
    
    geoscatter(lat, lon, 15, scores, 'filled')
    colorbar
    title('CO_2 Hotspots Projected onto Geographic Coordinates')
    
    % =====================================================
    % Connected component boundaries
    % =====================================================
    B = bwboundaries(hotMask);
    for k = 1:length(B)
        rows_b = B{k}(:,1);
        cols_b = B{k}(:,2);
        Xb = ulx + (cols_b-1)*pixelSize;
        Yb = uly - (rows_b-1)*pixelSize;
        [latb, lonb] = minvtran(utmstruct, Xb, Yb);
        geoplot(latb, lonb, 'r', 'LineWidth', 1.5);
    end
    
    % =====================================================
    % Largest component
    % =====================================================
    CC = bwconncomp(hotMask);
    numPixels = cellfun(@numel, CC.PixelIdxList);
    [~, idx] = max(numPixels);
    largestMask = false(size(hotMask));
    largestMask(CC.PixelIdxList{idx}) = true;
    
    B2 = bwboundaries(largestMask);
    rows_l = B2{1}(:,1);
    cols_l = B2{1}(:,2);
    Xb_l = ulx + (cols_l-1)*pixelSize;
    Yb_l = uly - (rows_l-1)*pixelSize;
    [latb_l, lonb_l] = minvtran(utmstruct, Xb_l, Yb_l);
    
    geoplot(latb_l, lonb_l, 'g', 'LineWidth', 3)
    legend('Hotspot pixels', 'Connected regions', 'Largest component')
    
    % =====================================================
    % Save
    % =====================================================
    exportgraphics(gcf, 'fig_geospatial_overlay.png', 'Resolution', 600)
    disp('Geospatial overlay saved.')
end