clear; clc; close all;

fprintf('\n%s\n',  repmat('=',1,60));
fprintf(' STEP 7  |  ABLATION STUDY\n');
fprintf('%s\n\n', repmat('=',1,60));

% ── Load proposed pipeline results ────────────────────────────────────────
assert(isfile('proposed_results.mat'), 'Run save_proposed_results.m first.');
P = load('proposed_results.mat', ...
    'cibrScore','jrgeScore','sfaScore','ctmfScore');

% ── Normalise each stage score to [0, 1] before Otsu ──────────────────────
% (allows fair comparison across stages with different scales)
n01 = @(M) (M - min(M(:))) / max(M(:) - min(M(:)) + eps);

stageScores = { n01(P.cibrScore), ...    % Stage 1
                n01(P.jrgeScore), ...    % Stage 2
                n01(P.sfaScore),  ...    % Stage 3
                n01(P.ctmfScore) };      % Stage 4

stageNames  = {'CIBR', ...
               'CIBR+JRGE', ...
               'CIBR+JRGE+SFA', ...
               'CIBR+JRGE+SFA+CTMF'};

nStages = numel(stageScores);
nPix    = numel(stageScores{1});

% ── Compute metrics ───────────────────────────────────────────────────────
cov_pct  = zeros(1, nStages);
mn_score = zeros(1, nStages);
mx_score = zeros(1, nStages);
sd_score = zeros(1, nStages);
p95      = zeros(1, nStages);
n_hot    = zeros(1, nStages);

for i = 1 : nStages
    sc   = stageScores{i};
    sv   = sc(:);

    % Otsu threshold on normalised [0,1] score
    lvl  = graythresh(sc);          % Otsu on [0,1] map
    mask = sc > lvl;

    cov_pct(i)  = 100 * sum(mask(:)) / nPix;
    mn_score(i) = mean(sv);
    mx_score(i) = max(sv);
    sd_score(i) = std(sv);
    p95(i)      = prctile(sv, 95);
    n_hot(i)    = sum(mask(:));
end

% ── Console display ───────────────────────────────────────────────────────
w = 22;
fprintf('%-*s  %-10s  %-10s  %-10s  %-10s  %-10s  %-10s\n', ...
    w,'Stage','Cover%','MeanSc','MaxSc','StdDev','P95','Hotspots');
fprintf('%s\n', repmat('-', w+64, 1));
for i = 1 : nStages
    fprintf('%-*s  %-10.3f  %-10.5f  %-10.5f  %-10.5f  %-10.5f  %-10d\n', ...
        w, stageNames{i}, cov_pct(i), mn_score(i), mx_score(i), ...
        sd_score(i), p95(i), n_hot(i));
end
fprintf('\n');

% ── Write CSV ─────────────────────────────────────────────────────────────
OUT_CSV = 'ablation_results.csv';
fid = fopen(OUT_CSV, 'wt');
if fid < 0, error('Cannot write %s', OUT_CSV); end

fprintf(fid, 'Stage,CoveragePct,MeanScore,MaxScore,StdDev,Pctile95,HotspotPixels\n');
for i = 1 : nStages
    fprintf(fid, '%s,%.6f,%.8f,%.8f,%.8f,%.8f,%d\n', ...
        stageNames{i}, cov_pct(i), mn_score(i), mx_score(i), ...
        sd_score(i), p95(i), n_hot(i));
end
fclose(fid);

fprintf('Saved → %s\n', OUT_CSV);
