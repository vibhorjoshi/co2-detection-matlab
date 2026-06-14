clear; clc; close all;

fprintf('\n%s\n',  repmat('=',1,60));
fprintf(' STEP 8  |  ABLATION MAPS FIGURE\n');
fprintf('%s\n\n', repmat('=',1,60));

% ── Load ─────────────────────────────────────────────────────────────────
assert(isfile('proposed_results.mat'), 'Run save_proposed_results.m first.');
P = load('proposed_results.mat','cibrScore','jrgeScore','sfaScore','ctmfScore');

% ── Normalise each map to [0, 1] ─────────────────────────────────────────
n01 = @(M) (M - min(M(:))) / max(M(:) - min(M(:)) + eps);

maps   = { n01(P.cibrScore), ...
           n01(P.jrgeScore), ...
           n01(P.sfaScore),  ...
           n01(P.ctmfScore) };

titles = { '(a) CIBR  [Band Ratio]', ...
           '(b) JRGE  [Continuum Removal]', ...
           '(c) SFA   [Template Matching]', ...
           '(d) Proposed CTMF  [Full Framework]' };

% ── Unified colour limits and map ────────────────────────────────────────
climAll = [0, 1];
cmap    = parula(256);
[nR, nC] = size(maps{1});

% ── Figure ────────────────────────────────────────────────────────────────
fig = figure('Name','Ablation Maps','Visible','off', ...
    'Units','centimeters','Position',[2 2 28 24]);

for i = 1 : 4
    ax = subplot(2, 2, i);

    imagesc(ax, maps{i});
    colormap(ax, cmap);
    caxis(ax, climAll);
    axis(ax, 'image');
    xlim(ax, [0.5, nC + 0.5]);
    ylim(ax, [0.5, nR + 0.5]);

    cb          = colorbar(ax);
    cb.FontSize = 8;
    cb.Label.String = 'Normalised Score';

    title(ax, titles{i}, 'FontSize', 10, 'FontWeight', 'bold');
    xlabel(ax, 'Column', 'FontSize', 8);
    ylabel(ax, 'Row',    'FontSize', 8);

    set(ax, 'FontSize', 8);
end

sgtitle({'Ablation Study:', ...
         'Progressive Background Clutter Suppression'}, ...
    'FontSize', 11, 'FontWeight', 'bold');

% ── Save ─────────────────────────────────────────────────────────────────
OUT_PNG = 'ablation_maps.png';
print(fig, OUT_PNG, '-dpng', '-r200');
close(fig);

fprintf('Saved → %s\n', OUT_PNG);
