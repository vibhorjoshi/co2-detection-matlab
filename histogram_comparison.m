% =========================================================================
%  histogram_comparison.m
%  STEP 4 — Score distribution comparison
%
%  Plots normalised probability histograms of:
%    • baselineScore  (raw CTMF)
%    • ctmfScore      (proposed CTMF)
%
%  Both distributions are shown on identical bin edges.
%
%  Reports five descriptive statistics for each distribution:
%    mean | median | standard deviation | maximum | 95th percentile
%
%  OUTPUT
%    histogram_scores.png
% =========================================================================

clear; clc; close all;

fprintf('\n%s\n',  repmat('=',1,60));
fprintf(' STEP 4  |  SCORE HISTOGRAM COMPARISON\n');
fprintf('%s\n\n', repmat('=',1,60));

% ── Load ─────────────────────────────────────────────────────────────────
assert(isfile('baseline_ctmf_results.mat'), ...
    'Run baseline_ctmf.m first.');
assert(isfile('proposed_results.mat'), ...
    'Run save_proposed_results.m first.');

B = load('baseline_ctmf_results.mat', 'baselineScore');
P = load('proposed_results.mat',      'ctmfScore');

bs = double(B.baselineScore(:));
cs = double(P.ctmfScore(:));

% ── Descriptive statistics ────────────────────────────────────────────────
stat_names = {'Mean', 'Median', 'StdDev', 'Maximum', '95th Pctile'};
st_b = [mean(bs), median(bs), std(bs), max(bs), prctile(bs, 95)];
st_c = [mean(cs), median(cs), std(cs), max(cs), prctile(cs, 95)];

fprintf('%-18s  %-14s  %-14s\n', 'Metric', 'Baseline CTMF', 'Proposed CTMF');
fprintf('%s\n', repmat('-',50,1));
for k = 1 : 5
    fprintf('%-18s  %-14.5f  %-14.5f\n', stat_names{k}, st_b(k), st_c(k));
end
fprintf('\n');

% ── Common bin edges (0.5th – 99.5th percentile of combined data) ────────
all_vals  = [bs; cs];
lo_edge   = prctile(all_vals, 0.5);
hi_edge   = prctile(all_vals, 99.5);
N_BINS    = 120;
edges     = linspace(lo_edge, hi_edge, N_BINS + 1);

% ── Figure ────────────────────────────────────────────────────────────────
fig = figure('Name','Score Histograms','Visible','off', ...
    'Units','centimeters','Position',[3 3 22 12]);

hold on;

h1 = histogram(bs, edges, ...
    'Normalization','probability', ...
    'FaceColor',  [0.22 0.47 0.74], ...
    'FaceAlpha',  0.65, ...
    'EdgeColor',  'none', ...
    'DisplayName','Baseline CTMF (Raw)');

h2 = histogram(cs, edges, ...
    'Normalization','probability', ...
    'FaceColor',  [0.84 0.19 0.13], ...
    'FaceAlpha',  0.65, ...
    'EdgeColor',  'none', ...
    'DisplayName','Proposed CTMF (Conditioned)');

% Mean indicator lines
xline(mean(bs), '--', ...
    'Color', [0.22 0.47 0.74], 'LineWidth', 1.6, ...
    'Label', sprintf('\\mu_{base}=%.3f', mean(bs)), ...
    'LabelVerticalAlignment','bottom', 'HandleVisibility','off');
xline(mean(cs), '--', ...
    'Color', [0.84 0.19 0.13], 'LineWidth', 1.6, ...
    'Label', sprintf('\\mu_{prop}=%.3f', mean(cs)), ...
    'LabelVerticalAlignment','top',    'HandleVisibility','off');

hold off;

legend([h1, h2], 'Location','northeast', 'FontSize', 9);
xlabel('Matched-Filter Score',  'FontSize', 10);
ylabel('Probability',           'FontSize', 10);
title('Score Distribution: Baseline vs.\ Proposed CTMF', ...
    'FontSize', 11, 'FontWeight', 'bold', 'Interpreter', 'none');

% Statistics annotation box
ann_str = sprintf( ...
    'Baseline  —  Max = %.3f   95th = %.3f   σ = %.4f\n', ...
    st_b(4), st_b(5), st_b(3));
ann_str = [ann_str, sprintf( ...
    'Proposed  —  Max = %.3f   95th = %.3f   σ = %.4f', ...
    st_c(4), st_c(5), st_c(3))];

annotation('textbox', [0.12 0.72 0.42 0.16], ...
    'String',          ann_str, ...
    'FitBoxToText',    'off', ...
    'BackgroundColor', [1 1 0.96], ...
    'EdgeColor',       [0.6 0.6 0.6], ...
    'FontSize',        7.5, ...
    'Interpreter',     'none');

grid on; box on;
set(gca,'FontSize',9);

OUT_PNG = 'histogram_scores.png';
print(fig, OUT_PNG, '-dpng', '-r200');
close(fig);

fprintf('Saved → %s\n', OUT_PNG);
