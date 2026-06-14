
clc; clear; close all;

t_total = tic;

fprintf('\n%s\n', repmat('#', 1, 65));
fprintf('  CO2 PLUME DETECTION — FULL VALIDATION SUITE\n');
fprintf('  Proposed: CIBR + JRGE + SFA + CTMF\n');
fprintf('  Baseline: Raw AVIRIS → CTMF  (Marion et al., 2004)\n');
fprintf('%s\n\n', repmat('#', 1, 65));

% ── Toolbox checks ────────────────────────────────────────────────────────
if ~exist('kmeans', 'file')
    error(['Statistics and Machine Learning Toolbox required ', ...
           '(provides kmeans).']);
end
if ~exist('graythresh', 'file')
    error(['Image Processing Toolbox required ', ...
           '(provides graythresh / mat2gray).']);
end

% ── Add current directory to path so helpers are found ───────────────────
addpath(pwd);

% ─────────────────────────────────────────────────────────────────────────
%  STEP 1 — Baseline pipeline
% ─────────────────────────────────────────────────────────────────────────
fprintf('[STEP 1]  Baseline CTMF …\n');
run('baseline_ctmf.m');

% ─────────────────────────────────────────────────────────────────────────
%  STEP 2 — Proposed pipeline + save intermediates
% ─────────────────────────────────────────────────────────────────────────
fprintf('[STEP 2]  Proposed pipeline (CIBR+JRGE+SFA+CTMF) …\n');
run('save_proposed_results.m');

% ─────────────────────────────────────────────────────────────────────────
%  STEP 3 — Six-panel comparison figure
% ─────────────────────────────────────────────────────────────────────────
fprintf('[STEP 3]  Six-panel comparison figure …\n');
run('figure_comparison.m');

% ─────────────────────────────────────────────────────────────────────────
%  STEP 4 — Histogram comparison
% ─────────────────────────────────────────────────────────────────────────
fprintf('[STEP 4]  Score histogram analysis …\n');
run('histogram_comparison.m');

% ─────────────────────────────────────────────────────────────────────────
%  STEP 5 — Horizontal profile analysis
% ─────────────────────────────────────────────────────────────────────────
fprintf('[STEP 5]  Profile analysis …\n');
run('profile_analysis.m');

% ─────────────────────────────────────────────────────────────────────────
%  STEP 6 — Selectivity metrics table
% ─────────────────────────────────────────────────────────────────────────
fprintf('[STEP 6]  Selectivity metrics …\n');
run('selectivity_metrics.m');

% ─────────────────────────────────────────────────────────────────────────
%  STEP 7 — Ablation study
% ─────────────────────────────────────────────────────────────────────────
fprintf('[STEP 7]  Ablation study …\n');
run('ablation_study.m');

% ─────────────────────────────────────────────────────────────────────────
%  STEP 8 — Ablation figure
% ─────────────────────────────────────────────────────────────────────────
fprintf('[STEP 8]  Ablation figure …\n');
run('ablation_figure.m');

% ─────────────────────────────────────────────────────────────────────────
%  STEP 9 — Threshold sensitivity
% ─────────────────────────────────────────────────────────────────────────
fprintf('[STEP 9]  Threshold sensitivity …\n');
run('threshold_sensitivity.m');

% ─────────────────────────────────────────────────────────────────────────
%  Summary
% ─────────────────────────────────────────────────────────────────────────
fprintf('\n%s\n', repmat('=', 1, 65));
fprintf('  ALL STEPS COMPLETE  (total time: %.1f s)\n', toc(t_total));
fprintf('%s\n', repmat('=', 1, 65));
fprintf('\nFigures\n');
fprintf('  comparison_pipeline.png\n');
fprintf('  histogram_scores.png\n');
fprintf('  profile_comparison.png\n');
fprintf('  ablation_maps.png\n');
fprintf('  threshold_sensitivity.png\n');
fprintf('\nTables\n');
fprintf('  quantitative_metrics.csv\n');
fprintf('  ablation_results.csv\n');
fprintf('  threshold_results.csv\n\n');
