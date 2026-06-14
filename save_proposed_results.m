clear; clc; close all;
fprintf('\n%s\n',  repmat('=',1,60));
fprintf(' STEP 2  |  PROPOSED PIPELINE  (CIBR → JRGE → SFA → CTMF)\n');
fprintf('%s\n\n', repmat('=',1,60));

% ── Configuration ─────────────────────────────────────────────────────────
HDRFILE = 'D:\downloads\co2-detection-hyperspectral-main\f250923t01p00r13_rfl.hdr';
DATAFILE = 'D:\downloads\co2-detection-hyperspectral-main\f250923t01p00r13_rfl.bin';
CROP_ROW   = 1;     CROP_NROWS = 1000;
CROP_COL   = 1;     CROP_NCOLS = 1000;
DSAMPLE    = 5;
SCALE      = 1e-4;
WL_LO      = 1500;
WL_HI      = 2200;
K_MEANS    = 4;
RNG_SEED   = 1;
LAMBDA_REG = 1e-6;
JRGE_ALPHA = 0.05;
JRGE_T     = 3;
OUT_MAT    = 'proposed_results.mat';
OUT_PNG    = 'proposed_ctmf_preview.png';

% ── 1. Load AVIRIS cube ───────────────────────────────────────────────────
fprintf('[1] Loading AVIRIS cube …\n');
[cube, wavelengths] = load_aviris_cube( ...
    DATAFILE, HDRFILE, ...
    CROP_ROW, CROP_NROWS, CROP_COL, CROP_NCOLS, ...
    DSAMPLE, SCALE);

% ── 2. CIBR ─ Continuum Interpolated Band Ratio ──────────────────────────
fprintf('[2] CIBR …\n');
cibrScore = co2_cibr(cube, wavelengths);
fprintf('    range [%.4f, %.4f]\n', min(cibrScore(:)), max(cibrScore(:)));

% ── 3. JRGE ─ Joint Reflectance & Gas Estimator ──────────────────────────
fprintf('[3] JRGE  (α=%.2f, T=%d) …\n', JRGE_ALPHA, JRGE_T);
t0 = tic;
[jrgeScore, condCube] = compute_jrge(cube, wavelengths, JRGE_ALPHA, JRGE_T);
fprintf('    Elapsed: %.1f s\n', toc(t0));
fprintf('    range [%.4f, %.4f]\n', min(jrgeScore(:)), max(jrgeScore(:)));

% ── 4. SFA ─ Spectral Fitting Algorithm (on JRGE-conditioned cube) ────────
fprintf('[4] SFA (on conditioned cube) …\n');
sfaScore = compute_sfa(condCube, wavelengths);
fprintf('    range [%.4f, %.4f]\n', min(sfaScore(:)), max(sfaScore(:)));

% ── 5. CTMF ─ Cluster-Tuned Matched Filter (on conditioned SWIR cube) ────
fprintf('[5] CTMF on JRGE-conditioned cube (K=%d, λ=%.0e) …\n', K_MEANS, LAMBDA_REG);
swirMask = wavelengths >= WL_LO & wavelengths <= WL_HI;

condSWIR = condCube(:,:, swirMask);
wlSWIR   = wavelengths(swirMask);
d        = build_target_spectrum(wlSWIR);

t0 = tic;
ctmfScore = compute_ctmf(condSWIR, d, K_MEANS, LAMBDA_REG, RNG_SEED);
fprintf('    Elapsed: %.1f s\n', toc(t0));
fprintf('    range [%.4f, %.4f]\n', min(ctmfScore(:)), max(ctmfScore(:)));

% ── 6. Otsu threshold ────────────────────────────────────────────────────
fprintf('[6] Otsu threshold …\n');
scoreN             = mat2gray(ctmfScore);
otsuLevel          = graythresh(scoreN);
scMin              = min(ctmfScore(:));
scRange            = max(ctmfScore(:)) - scMin;
thresholdProposed  = otsuLevel * scRange + scMin;
binaryMask         = ctmfScore > thresholdProposed;
fprintf('    Threshold : %.4f\n', thresholdProposed);
fprintf('    Hotspot px: %d  (%.2f %%)\n', sum(binaryMask(:)), 100 * mean(binaryMask(:)));

% ── 7. Save all intermediate maps ────────────────────────────────────────
fprintf('[7] Saving → %s\n', OUT_MAT);
save(OUT_MAT, ...
    'cibrScore', 'jrgeScore', 'sfaScore', 'ctmfScore', 'binaryMask', ...
    'thresholdProposed', 'wlSWIR', 'wavelengths', 'd', 'cube', '-v7.3');

% ── 8. Preview ───────────────────────────────────────────────────────────
fig = figure('Name', 'Proposed CTMF Preview', 'Visible', 'off', 'Position', [100 100 720 560]);
imagesc(ctmfScore);
colorbar; colormap(gca, 'hot'); axis image;
clim([prctile(ctmfScore(:),1), prctile(ctmfScore(:),99)]);
title('Proposed CTMF Score — CIBR + JRGE + SFA Conditioning', 'FontSize', 12, 'FontWeight', 'bold');
xlabel('Column index'); ylabel('Row index');
print(fig, OUT_PNG, '-dpng', '-r180');
close(fig);
fprintf('[8] Preview saved → %s\n', OUT_PNG);
fprintf('\nProposed pipeline complete.\n\n');


%% =========================================================================
% LOCAL FUNCTIONS
% Placing functions here guarantees the script uses the correct version!
%% =========================================================================

function cibrScore = co2_cibr(cube, wavelengths)
    wl = wavelengths(:)';

    % ── Band-group masks ─────────────────────────────────────────────────────
    maskL = wl >= 2000 & wl <= 2020;   % left continuum
    maskA = wl >= 2040 & wl <= 2060;   % CO2 absorption
    maskR = wl >= 2080 & wl <= 2100;   % right continuum

    if sum(maskA) == 0
        error('compute_cibr: no bands in CO2 absorption window 2040–2060 nm.');
    end
    if sum(maskL) == 0 || sum(maskR) == 0
        error('compute_cibr: missing left or right baseline bands.');
    end

    % ── Mean reflectance over each group ────────────────────────────────────
    RL = double(mean(cube(:,:,maskL), 3));
    RA = double(mean(cube(:,:,maskA), 3));
    RR = double(mean(cube(:,:,maskR), 3));

    % ── Interpolation weights (spectral distance) ────────────────────────────
    wlL = mean(wl(maskL));   % centre of left group  (nm)
    wlA = mean(wl(maskA));   % centre of absorption  (nm)
    wlR = mean(wl(maskR));   % centre of right group (nm)

    span = wlR - wlL;
    wW   = (wlR - wlA) / span;   % weight on left  shoulder
    wE   = (wlA - wlL) / span;   % weight on right shoulder

    % ── Interpolated continuum and CIBR ─────────────────────────────────────
    Rcont     = wW .* RL + wE .* RR;
    CIBR      = RA ./ max(Rcont, 1e-8);
    cibrScore = max(0, 1 - CIBR);      % higher ⟹ stronger CO2 absorption
end