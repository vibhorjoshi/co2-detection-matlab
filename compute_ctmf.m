function score = co2_ctmf(cube, d, K, lambda, seed)
if nargin < 3, K      = 4;    end
if nargin < 4, lambda = 1e-6; end
if nargin < 5, seed   = 1;    end

[nR, nC, nB] = size(cube);
nPix = nR * nC;
d    = double(d(:));       % [nB × 1], double for numeric stability

% ── Flatten to 2-D ─────────────────────────────────────────────────────
X = double(reshape(cube, nPix, nB));   % [nPix × nB]

% ── Mask invalid pixels ─────────────────────────────────────────────────
validMask = all(isfinite(X), 2) & any(X > 0, 2);
Xv        = X(validMask, :);
nValid    = size(Xv, 1);

% Clamp K to available data
K = min(K, floor(nValid / (nB + 2)));
K = max(K, 1);

% ── K-means clustering ──────────────────────────────────────────────────
rng(seed, 'twister');
[labels, ~] = kmeans(Xv, K, ...
    'MaxIter',   300,          ...
    'Replicates', 5,           ...
    'Distance',  'sqeuclidean', ...
    'Display',   'off');

% ── Per-cluster matched filter ──────────────────────────────────────────
validIdx  = find(validMask);
scoreVec  = zeros(nPix, 1, 'double');
I_reg     = lambda * eye(nB);

for k = 1 : K
    clMask = (labels == k);
    nk     = sum(clMask);
    if nk < nB + 2, continue; end        % skip under-populated clusters

    Xk   = Xv(clMask, :);               % [nk × nB]
    mu   = mean(Xk, 1)';                 % [nB × 1]
    Xc   = Xk - mu';                     % centred, [nk × nB]

    % Regularised sample covariance
    Sig  = (Xc' * Xc) / (nk - 1) + I_reg;  % [nB × nB]

    % Solve Sig * v = d  (stable substitute for Sig^{-1} * d)
    v    = Sig \ d;                          % [nB × 1]
    denom = sqrt(max(d' * v, eps));          % scalar

    % Scores for all pixels in this cluster
    sc_k = (Xc * v) / denom;                % [nk × 1]

    % Write back to full-size vector
    fullIdx = validIdx(clMask);
    scoreVec(fullIdx) = sc_k;
end

% ── Reshape and return ───────────────────────────────────────────────────
score = reshape(scoreVec, nR, nC);
end
