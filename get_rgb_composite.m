function rgb = get_rgb_composite(cube, wavelengths)

wl      = wavelengths(:)';
targets = [660, 550, 470];    % R, G, B target wavelengths (nm)
half_w  = 10;                 % half-width of averaging window (nm)

rawRGB  = zeros(size(cube,1), size(cube,2), 3);

for ch = 1 : 3
    mask = wl >= targets(ch) - half_w & wl <= targets(ch) + half_w;
    if sum(mask) == 0
        % Fallback: nearest single band
        [~, idx] = min(abs(wl - targets(ch)));
        mask = false(size(wl));
        mask(idx) = true;
    end
    rawRGB(:,:,ch) = double(mean(cube(:,:,mask), 3));
end

% ── Per-channel contrast stretch ─────────────────────────────────────────
stretchedRGB = zeros(size(rawRGB));
for ch = 1 : 3
    img    = rawRGB(:,:,ch);
    valid  = img(img > 0);
    if isempty(valid)
        stretchedRGB(:,:,ch) = 0;
        continue
    end
    lo  = prctile(valid, 2);
    hi  = prctile(valid, 98);
    img = (img - lo) / max(hi - lo, eps);
    stretchedRGB(:,:,ch) = img;
end

rgb = uint8(min(max(stretchedRGB, 0), 1) * 255);
end
