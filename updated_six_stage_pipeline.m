%% --- PART 1: DATA PREPARATION ---
clear; clc; close all;

disp('1. Loading data from the proposed pipeline...');
load('proposed_results.mat'); 

disp('2. Calculating Baseline CTMF for comparison...');
swirMask = wavelengths >= 1500 & wavelengths <= 2200;
rawSWIR = cube(:, :, swirMask);

baselineScore = compute_ctmf(rawSWIR, d, 4, 1e-6, 1);

disp('3. Generating P95 thresholds and masks...');
ctmfScore_p = ctmfScore;

p95_b = prctile(baselineScore(:), 95);
p95_p = prctile(ctmfScore_p(:), 95);

mask_b95 = baselineScore >= p95_b;
mask_p95 = ctmfScore_p >= p95_p;

%% --- PART 2: FIGURE GENERATION ---
disp('4. Generating Figures...');

OUT = 'output_figures';
if ~exist(OUT, 'dir')
    mkdir(OUT);
end

% ======================================================================
% NEW FIG 1 : CDFs (CDF_comparison.png)
% ======================================================================
bs = sort(baselineScore(:));
cp = sort(ctmfScore_p(:));
n = numel(bs);
cdf_y = (1:n)' / n;

grid_pts = linspace(min([bs; cp]), max([bs; cp]), 4000);

[bs_unq, bs_idx] = unique(bs, 'last');
[cp_unq, cp_idx] = unique(cp, 'last');

cdf_b_g = interp1(bs_unq, cdf_y(bs_idx), grid_pts, 'previous', 'extrap');
cdf_b_g(grid_pts < bs_unq(1)) = 0; cdf_b_g(grid_pts >= bs_unq(end)) = 1;

cdf_p_g = interp1(cp_unq, cdf_y(cp_idx), grid_pts, 'previous', 'extrap');
cdf_p_g(grid_pts < cp_unq(1)) = 0; cdf_p_g(grid_pts >= cp_unq(end)) = 1;

[ks, ks_idx] = max(abs(cdf_b_g - cdf_p_g));
ks_x = grid_pts(ks_idx);

fig1 = figure('Name', 'CDF of matched-filter scores', 'Color', 'w', 'Position', [100 100 500 400]);
hold on; grid on;
plot(bs, cdf_y, 'Color', '#3a72b4', 'LineWidth', 1.8, 'DisplayName', 'Baseline CTMF');
plot(cp, cdf_y, 'Color', '#d6352a', 'LineWidth', 1.4, 'LineStyle', '--', 'DisplayName', 'Proposed framework');
xline(0, 'Color', [0.5 0.5 0.5], 'LineWidth', 0.6, 'LineStyle', ':');

xlabel('Matched-filter score');
ylabel('Cumulative probability');
title('CDF of matched-filter scores');
legend('Location', 'northwest', 'Box', 'off');
xlim([-0.04, 0.03]);

txt = sprintf('max |\\DeltaCDF| = %.2e\nat score = %.2e', ks, ks_x);
text(0.98, 0.04, txt, 'Units', 'normalized', 'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom', ...
    'BackgroundColor', 'w', 'EdgeColor', [0.7 0.7 0.7], 'FontSize', 9);

saveas(fig1, fullfile(OUT, 'fig_cdf.png'));
close(fig1);

% ======================================================================
% NEW FIG 2 : Difference map (proposed - baseline)
% ======================================================================
diffmap = ctmfScore_p - baselineScore;
vmax = max(abs(diffmap(:)));

fig2 = figure('Name', 'Proposed - Baseline CTMF score', 'Color', 'w', 'Position', [100 100 500 450]);
imagesc(diffmap);
axis image;
title('Proposed $-$ Baseline CTMF score');
xlabel('Column index'); ylabel('Row index');

c1 = [linspace(0,1,128)', linspace(0,1,128)', ones(128,1)];
c2 = [ones(128,1), linspace(1,0,128)', linspace(1,0,128)'];
colormap(gca, [c1; c2]);
clim([-vmax, vmax]);

cb = colorbar;
cb.Label.String = 'Score difference';
saveas(fig2, fullfile(OUT, 'fig_diffmap.png'));
close(fig2);

fprintf('diffmap range: [%.4f, %.4f], frac>0: %.4f, frac<0: %.4f, frac==0: %.4f\n', ...
    min(diffmap(:)), max(diffmap(:)), mean(diffmap(:)>0), mean(diffmap(:)<0), mean(diffmap(:)==0));

% ======================================================================
% NEW FIG 3 : 3D surfaces baseline vs proposed
% ======================================================================
step = 2;
Zb = baselineScore(1:step:end, 1:step:end);
Zp = ctmfScore_p(1:step:end, 1:step:end);
zmin = min(min(Zb(:)), min(Zp(:)));
zmax = max(max(Zb(:)), max(Zp(:)));

[X, Y] = meshgrid(1:size(Zb,2), 1:size(Zb,1));
fig3 = figure('Name', 'Three-dimensional response surfaces', 'Color', 'w', 'Position', [100 100 900 400]);

subplot(1,2,1);
surf(X, Y, Zb, 'EdgeColor', 'none');
view(-60, 28);
title('Baseline CTMF');
xlabel('Col'); ylabel('Row'); zlabel('Score');
zlim([zmin, zmax]); colormap('parula');

subplot(1,2,2);
surf(X, Y, Zp, 'EdgeColor', 'none');
view(-60, 28);
title('Proposed framework');
xlabel('Col'); ylabel('Row'); zlabel('Score');
zlim([zmin, zmax]); colormap('parula');

sgtitle('Three-dimensional response surfaces', 'FontSize', 12, 'FontWeight', 'bold');
saveas(fig3, fullfile(OUT, 'fig_3dsurface.png'));
close(fig3);

% ======================================================================
% NEW FIG 4 : Connected components @ P95 (top 5%)
% ======================================================================
fig4 = figure('Name', 'Connected components of the P95 hotspot mask', 'Color', 'w', 'Position', [100 100 900 450]);
masks = {mask_b95, mask_p95};
titles = {'Baseline CTMF (top 5%)', 'Proposed framework (top 5%)'};
p95_vals = [p95_b, p95_p];

for i = 1:2
    mask = masks{i};
    CC = bwconncomp(mask, 8); 
    stats = regionprops(CC, 'Area', 'Perimeter', 'PixelIdxList');

    n_comp = CC.NumObjects;
    dispImg = zeros(size(mask));

    if n_comp > 0
        [maxArea, maxIdx] = max([stats.Area]);
        perim = stats(maxIdx).Perimeter;
        if perim == 0, perim = 1.0; end
        comp = 4 * pi * maxArea / (perim^2);

        dispImg(mask) = 1; 
        dispImg(stats(maxIdx).PixelIdxList) = 2; 
    else
        maxArea = 0; comp = 0;
    end

    ax = subplot(1,2,i);
    imagesc(dispImg);
    axis image;
    
    colormap(ax, [0.94 0.94 0.94; 0.62 0.79 0.88; 0.84 0.21 0.16]);
    clim([0 2]);
    title(titles{i});
    xlabel('Column index'); ylabel('Row index');

    txt = sprintf('components=%d\nlargest=%dpx (%.2f%%)\ncompactness=%.3f\nthreshold=%.5f', ...
        n_comp, maxArea, 100*maxArea/numel(mask), comp, p95_vals(i));
    text(0.02, 0.02, txt, 'Units', 'normalized', 'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom', ...
        'BackgroundColor', 'w', 'EdgeColor', [0.7 0.7 0.7], 'FontSize', 8);
end

sgtitle('Connected components of the P95 hotspot mask', 'FontSize', 12, 'FontWeight', 'bold');
saveas(fig4, fullfile(OUT, 'fig_connected.png'));
close(fig4);

disp('All Phase-1 figures successfully written to the output_figures folder!');