% =========================================================================
%  figure_comparison.m
%  STEP 3 — Six-panel comparison figure
%
%  Panel layout (2 × 3):
%   (a) RGB composite       (b) Baseline CTMF (raw)
%   (c) CIBR response       (d) JRGE response
%   (e) SFA response        (f) Proposed CTMF (conditioned)
%
%  All score panels share:
%   • identical parula colourmap
%   • normalised [0, 1] colour scale
%   • same spatial extent / image size
%
%  OUTPUT
%    comparison_pipeline.png
% =========================================================================

clear; clc; close all;

fprintf('\n%s\n',  repmat('=',1,60));
fprintf(' STEP 3  |  SIX-PANEL COMPARISON FIGURE\n');
fprintf('%s\n\n', repmat('=',1,60));

% ── Load results ─────────────────────────────────────────────────────────
assert(isfile('baseline_ctmf_results.mat'), ...
    'Missing baseline_ctmf_results.mat — run baseline_ctmf.m first.');
assert(isfile('proposed_results.mat'), ...
    'Missing proposed_results.mat — run save_proposed_results.m first.');

B = load('baseline_ctmf_results.mat', 'baselineScore', 'wavelengths');
P = load('proposed_results.mat', ...
    'cibrScore','jrgeScore','sfaScore','ctmfScore','cube','wavelengths');

% ── RGB composite ─────────────────────────────────────────────────────────
rgb = get_rgb_composite(P.cube, P.wavelengths);

% ── Normalise score maps to [0, 1] for uniform display ──────────────────
function M = norm01(M)
    lo = min(M(:)); hi = max(M(:));
    M  = (M - lo) / max(hi - lo, eps);
end

bsN    = norm01(B.baselineScore);
cibrN  = norm01(P.cibrScore);
jrgeN  = norm01(P.jrgeScore);
sfaN   = norm01(P.sfaScore);
ctmfN  = norm01(P.ctmfScore);

[nR, nC] = size(bsN);

% ── Compose figure ────────────────────────────────────────────────────────
fig = figure('Name','Pipeline Comparison', 'Visible','off', ...
    'Units','centimeters','Position',[2 2 36 22]);

cmap    = parula(256);
xlimAll = [0.5, nC+0.5];
ylimAll = [0.5, nR+0.5];
climAll = [0, 1];

panelTitles = { '(a) RGB Composite', ...
                '(b) Baseline CTMF  [Raw Reflectance]', ...
                '(c) CIBR  [Band Ratio]', ...
                '(d) JRGE  [Continuum Removal]', ...
                '(e) SFA   [Template Matching]', ...
                '(f) Proposed CTMF  [Conditioned]' };

scoreMaps = {[], bsN, cibrN, jrgeN, sfaN, ctmfN};

for i = 1 : 6
    ax = subplot(2, 3, i);

    if i == 1
        % True-colour composite
        imshow(rgb, 'Parent', ax);
        title(ax, panelTitles{i}, 'FontSize', 9.5, 'FontWeight', 'bold');
    else
        imagesc(ax, scoreMaps{i});
        colormap(ax, cmap);
        caxis(ax, climAll);
        xlim(ax, xlimAll); ylim(ax, ylimAll);
        axis(ax, 'image');
        cb           = colorbar(ax);
        cb.FontSize  = 8;
        cb.Label.String = 'Normalised Score';
        title(ax, panelTitles{i}, 'FontSize', 9.5, 'FontWeight', 'bold');
    end

    xlabel(ax, 'Column', 'FontSize', 8);
    ylabel(ax, 'Row',    'FontSize', 8);
end

sgtitle(['Spectral Conditioning vs.\ Baseline CTMF', newline, ...
         'Clutter Suppression and Plume Localisation'], ...
    'FontSize', 11, 'FontWeight', 'bold', 'Interpreter', 'none');

% ── Save ─────────────────────────────────────────────────────────────────
OUT_PNG = 'comparison_pipeline.png';
print(fig, OUT_PNG, '-dpng', '-r200');
close(fig);

fprintf('Saved → %s\n', OUT_PNG);
