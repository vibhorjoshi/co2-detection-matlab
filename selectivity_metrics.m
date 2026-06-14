% =========================================================================
%  selectivity_metrics.m
%  STEP 6 — Quantitative selectivity metrics
%
%  Computes the following for both Baseline CTMF and Proposed CTMF:
%    • Mean score                (spatial average of all pixels)
%    • Maximum score             (strongest anomaly response)
%    • Standard deviation        (spread of the score distribution)
%    • 95th percentile           (upper tail concentration)
%    • Hotspot pixel count       (pixels exceeding Otsu threshold)
%    • Hotspot coverage  (%)
%    • Selectivity Ratio = Max / |Mean|
%                         (higher ⟹ response more concentrated at plume)
%
%  OUTPUT
%    quantitative_metrics.csv
% =========================================================================

clear; clc; close all;

fprintf('\n%s\n',  repmat('=',1,60));
fprintf(' STEP 6  |  SELECTIVITY METRICS\n');
fprintf('%s\n\n', repmat('=',1,60));

% ── Load ─────────────────────────────────────────────────────────────────
assert(isfile('baseline_ctmf_results.mat'), 'Run baseline_ctmf.m first.');
assert(isfile('proposed_results.mat'),      'Run save_proposed_results.m first.');

B = load('baseline_ctmf_results.mat', 'baselineScore', 'baselineMask');
P = load('proposed_results.mat',      'ctmfScore',     'binaryMask');

bs  = double(B.baselineScore);
cs  = double(P.ctmfScore);
bm  = logical(B.baselineMask);
pm  = logical(P.binaryMask);

% ── Metric computation ────────────────────────────────────────────────────
nPix = numel(bs);

% Baseline
b_mean  = mean(bs(:));
b_max   = max(bs(:));
b_std   = std(bs(:));
b_p95   = prctile(bs(:), 95);
b_nhot  = sum(bm(:));
b_cov   = 100 * b_nhot / nPix;
b_selr  = b_max / max(abs(b_mean), eps);

% Proposed
c_mean  = mean(cs(:));
c_max   = max(cs(:));
c_std   = std(cs(:));
c_p95   = prctile(cs(:), 95);
c_nhot  = sum(pm(:));
c_cov   = 100 * c_nhot / nPix;
c_selr  = c_max / max(abs(c_mean), eps);

% ── Console display ───────────────────────────────────────────────────────
hdr_fmt  = '%-28s  %-16s  %-16s\n';
row_fmt  = '%-28s  %-16.5f  %-16.5f\n';
row_int  = '%-28s  %-16d  %-16d\n';

fprintf(hdr_fmt, 'Metric', 'RawCTMF', 'ProposedFramework');
fprintf('%s\n', repmat('-', 64, 1));
fprintf(row_fmt,  'Mean Score',          b_mean,  c_mean);
fprintf(row_fmt,  'Maximum Score',       b_max,   c_max);
fprintf(row_fmt,  'Std Deviation',       b_std,   c_std);
fprintf(row_fmt,  '95th Percentile',     b_p95,   c_p95);
fprintf(row_int,  'Hotspot Pixels',      b_nhot,  c_nhot);
fprintf('%-28s  %-16.3f  %-16.3f\n',    'Coverage (%)', b_cov, c_cov);
fprintf('%-28s  %-16.2f  %-16.2f\n',    'Selectivity Ratio', b_selr, c_selr);
fprintf('\n');

% ── Write CSV ─────────────────────────────────────────────────────────────
OUT_CSV = 'quantitative_metrics.csv';
fid = fopen(OUT_CSV, 'wt');
if fid < 0, error('Cannot write %s', OUT_CSV); end

fprintf(fid, 'Metric,RawCTMF,ProposedFramework\n');
fprintf(fid, 'MeanScore,%.8f,%.8f\n',        b_mean,  c_mean);
fprintf(fid, 'MaximumScore,%.8f,%.8f\n',     b_max,   c_max);
fprintf(fid, 'StdDeviation,%.8f,%.8f\n',     b_std,   c_std);
fprintf(fid, '95thPercentile,%.8f,%.8f\n',   b_p95,   c_p95);
fprintf(fid, 'HotspotPixels,%d,%d\n',        b_nhot,  c_nhot);
fprintf(fid, 'CoveragePct,%.6f,%.6f\n',      b_cov,   c_cov);
fprintf(fid, 'SelectivityRatio,%.6f,%.6f\n', b_selr,  c_selr);

fclose(fid);
fprintf('Saved → %s\n', OUT_CSV);
