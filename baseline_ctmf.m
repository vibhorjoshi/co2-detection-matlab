clear; clc; close all;

fprintf('\n%s\n',  repmat('=',1,60));
fprintf(' STEP 1  |  BASELINE CTMF  (Raw Reflectance)\n');
fprintf('%s\n\n', repmat('=',1,60));

% ── Configuration ─────────────────────────────────────────────────────────
    HDRFILE = ...
'D:\downloads\co2-detection-hyperspectral-main\f250923t01p00r13_rfl.hdr';
    DATAFILE = ...
'D:\downloads\co2-detection-hyperspectral-main\f250923t01p00r13_rfl.bin';

CROP_ROW   = 1;     CROP_NROWS = 1000;
CROP_COL   = 1;     CROP_NCOLS = 1000;
DSAMPLE    = 5;     % spatial downsampling  (200 × 200 working array)
SCALE      = 1e-4;  % raw integer ÷ 10 000 = reflectance

WL_LO      = 1500;  % SWIR lower bound (nm)
WL_HI      = 2200;  % SWIR upper bound (nm)

K_MEANS    = 4;
RNG_SEED   = 1;
LAMBDA_REG = 1e-6;

OUT_MAT    = 'baseline_ctmf_results.mat';
OUT_PNG    = 'baseline_ctmf_preview.png';

% ── Step 1 — Load AVIRIS cube ─────────────────────────────────────────────
fprintf('[1] Loading AVIRIS cube …\n');
[cube, wavelengths] = load_aviris_cube( ...
    DATAFILE, HDRFILE, ...
    CROP_ROW, CROP_NROWS, CROP_COL, CROP_NCOLS, ...
    DSAMPLE, SCALE);

% ── Step 2 — Select SWIR bands ───────────────────────────────────────────
fprintf('[2] Selecting SWIR bands (%.0f – %.0f nm) …\n', WL_LO, WL_HI);
swirMask = wavelengths >= WL_LO & wavelengths <= WL_HI;
cubeSWIR = cube(:,:, swirMask);
wlSWIR   = wavelengths(swirMask);
fprintf('    %d SWIR bands selected.\n', sum(swirMask));

% ── Step 3 — Build CO2 target spectrum ──────────────────────────────────
fprintf('[3] Building dual-Gaussian CO2 target …\n');
d = build_target_spectrum(wlSWIR);

% ── Step 4 — Run CTMF on raw SWIR cube ──────────────────────────────────
fprintf('[4] Running CTMF on RAW reflectance (K=%d, λ=%.0e) …\n', ...
    K_MEANS, LAMBDA_REG);
t0 = tic;
baselineScore = compute_ctmf(cubeSWIR, d, K_MEANS, LAMBDA_REG, RNG_SEED);
fprintf('    Elapsed: %.1f s\n', toc(t0));
fprintf('    Score range: [%.4f, %.4f]\n', ...
    min(baselineScore(:)), max(baselineScore(:)));

% ── Step 5 — Otsu threshold ──────────────────────────────────────────────
fprintf('[5] Applying Otsu threshold …\n');
scoreN            = mat2gray(baselineScore);      % → [0,1]
otsuLevel         = graythresh(scoreN);
scMin             = min(baselineScore(:));
scRange           = max(baselineScore(:)) - scMin;
thresholdBaseline = otsuLevel * scRange + scMin;
baselineMask      = baselineScore > thresholdBaseline;

fprintf('    Otsu threshold : %.4f\n', thresholdBaseline);
fprintf('    Hotspot pixels : %d  (%.2f %% of scene)\n', ...
    sum(baselineMask(:)), 100 * mean(baselineMask(:)));

% ── Step 6 — Save ────────────────────────────────────────────────────────
fprintf('[6] Saving → %s\n', OUT_MAT);
save(OUT_MAT, ...
    'baselineScore', 'baselineMask', 'thresholdBaseline', ...
    'wlSWIR', 'wavelengths', 'd', '-v7.3');

% ── Step 7 — Preview figure ──────────────────────────────────────────────
fig = figure('Name', 'Baseline CTMF Preview', 'Visible', 'off', ...
    'Position', [100 100 720 560]);

imagesc(baselineScore);
colorbar; colormap(gca, 'hot'); axis image;
caxis([prctile(baselineScore(:),1), prctile(baselineScore(:),99)]);
title('Baseline CTMF Score — Raw AVIRIS Reflectance', ...
    'FontSize', 12, 'FontWeight', 'bold');
xlabel('Column index'); ylabel('Row index');

print(fig, OUT_PNG, '-dpng', '-r180');
close(fig);
fprintf('[7] Preview saved → %s\n', OUT_PNG);

fprintf('\nBaseline CTMF complete.\n\n');
