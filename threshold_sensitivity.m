% =========================================================================
%  threshold_sensitivity.m
%  STEP 9 — Threshold sensitivity analysis
%
%  Tests four threshold strategies on the proposed CTMF score map:
%    (1) Otsu   — automatic, data-adaptive
%    (2) P85    — 85th percentile of the score distribution
%    (3) P90    — 90th percentile
%    (4) P95    — 95th percentile
%
%  For each threshold records:
%    • Threshold value
%    • Coverage (% of scene classified as hotspot)
%    • Hotspot pixel count
%    • Mean hotspot score  (quality of detections above threshold)
%
%  Purpose: demonstrate that the qualitative conclusions (plume detected,
%  clutter suppressed) are robust across a range of decision boundaries.
%
%  OUTPUT
%    threshold_sensitivity.png
%    threshold_results.csv
% =========================================================================

clear; clc; close all;

fprintf('\n%s\n',  repmat('=',1,60));
fprintf(' STEP 9  |  THRESHOLD SENSITIVITY ANALYSIS\n');
fprintf('%s\n\n', repmat('=',1,60));

% ── Load proposed CTMF score ─────────────────────────────────────────────
assert(isfile('proposed_results.mat'), 'Run save_proposed_results.m first.');
P  = load('proposed_results.mat', 'ctmfScore');
cs = double(P.ctmfScore);
nPix = numel(cs);

% ── Define thresholds ────────────────────────────────────────────────────
scoreNorm  = mat2gray(cs);
otsuLevel  = graythresh(scoreNorm);
otsuThresh = otsuLevel * (max(cs(:)) - min(cs(:))) + min(cs(:));

pctVals   = prctile(cs(:), [85, 90, 95]);
tNames    = {'Otsu', 'P85', 'P90', 'P95'};
tValues   = [otsuThresh, pctVals];
nT        = numel(tValues);

% ── Compute metrics ───────────────────────────────────────────────────────
cov_pct  = zeros(1, nT);
n_hot    = zeros(1, nT);
mn_hot   = zeros(1, nT);

for i = 1 : nT
    mask = cs > tValues(i);
    n_hot(i)   = sum(mask(:));
    cov_pct(i) = 100 * n_hot(i) / nPix;
    hv         = cs(mask);
    if ~isempty(hv)
        mn_hot(i) = mean(hv);
    end
end

% ── Console display ───────────────────────────────────────────────────────
fprintf('%-8s  %-12s  %-12s  %-14s  %-14s\n', ...
    'Method','ThreshValue','Coverage%','HotspotPixels','MeanHotScore');
fprintf('%s\n', repmat('-', 65, 1));
for i = 1 : nT
    fprintf('%-8s  %-12.5f  %-12.3f  %-14d  %-14.5f\n', ...
        tNames{i}, tValues(i), cov_pct(i), n_hot(i), mn_hot(i));
end
fprintf('\n');

% ── Write CSV ─────────────────────────────────────────────────────────────
OUT_CSV = 'threshold_results.csv';
fid = fopen(OUT_CSV, 'wt');
if fid < 0, error('Cannot write %s', OUT_CSV); end
fprintf(fid, 'Threshold,ThreshValue,CoveragePct,HotspotPixels,MeanHotspotScore\n');
for i = 1 : nT
    fprintf(fid, '%s,%.8f,%.6f,%d,%.8f\n', ...
        tNames{i}, tValues(i), cov_pct(i), n_hot(i), mn_hot(i));
end
fclose(fid);

% ── Figure: dual-axis bar + line chart ───────────────────────────────────
fig = figure('Name','Threshold Sensitivity','Visible','off', ...
    'Units','centimeters','Position',[3 3 22 11]);

xPos   = 1 : nT;
colors = { [0.22 0.47 0.74], [0.47 0.72 0.42], ...
           [0.84 0.61 0.22], [0.84 0.19 0.13] };

ax1 = axes(fig);

% Coverage bars
for i = 1 : nT
    bar(ax1, xPos(i), cov_pct(i), 0.55, ...
        'FaceColor', colors{i}, 'EdgeColor','none', ...
        'DisplayName', tNames{i});
    hold(ax1, 'on');
end
hold(ax1, 'off');

ylabel(ax1, 'Coverage (%)', 'FontSize', 10);
ylim(ax1,  [0,  max(cov_pct) * 1.45]);
xticks(ax1, xPos);
xticklabels(ax1, tNames);
set(ax1, 'FontSize', 9);

% Mean hotspot score on right axis
ax2 = axes(fig, 'Position', ax1.Position, ...
    'XAxisLocation','top', 'YAxisLocation','right', ...
    'Color','none', 'XTick', [], 'YColor', [0.50 0.18 0.56]);

hold(ax2,'on');
plot(ax2, xPos, mn_hot, '-s', ...
    'Color', [0.50 0.18 0.56], ...
    'LineWidth', 2, ...
    'MarkerSize', 8, ...
    'MarkerFaceColor', [0.50 0.18 0.56]);
hold(ax2,'off');

xlim(ax2, [0.4, nT + 0.6]);
ylim(ax2, [min(mn_hot)*0.90, max(mn_hot)*1.15]);
ylabel(ax2, 'Mean Hotspot Score', 'FontSize', 10);

% Annotation: pixel counts above each bar
for i = 1 : nT
    text(ax1, xPos(i), cov_pct(i) + max(cov_pct)*0.04, ...
        sprintf('%d px', n_hot(i)), ...
        'HorizontalAlignment','center', 'FontSize', 7.5);
end

title(ax1, 'Threshold Sensitivity — Proposed CTMF', ...
    'FontSize', 11, 'FontWeight', 'bold');

% Manual legend
legend(ax1, tNames, 'Location', 'northwest', 'FontSize', 9);

xlabel(ax1, 'Threshold Method', 'FontSize', 10);

OUT_PNG = 'threshold_sensitivity.png';
print(fig, OUT_PNG, '-dpng', '-r200');
close(fig);

fprintf('Saved → %s\n', OUT_PNG);
fprintf('Saved → %s\n', OUT_CSV);
