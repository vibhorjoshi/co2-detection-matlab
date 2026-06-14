function [jrgeScore, condCube] = compute_jrge(cube, wavelengths, alpha, T)
if nargin < 3, alpha = 0.05; end
if nargin < 4, T     = 3;    end

[nR, nC, ~] = size(cube);
wl   = wavelengths(:)';

% ── CO2 absorption window ────────────────────────────────────────────────
co2Mask = wl >= 2000 & wl <= 2100;
nBw     = sum(co2Mask);
wlW     = wl(co2Mask);                   % [1 × nBw]

if nBw < 3
    warning('compute_jrge: fewer than 3 bands in 2000–2100 nm; returning zeros.');
    jrgeScore = zeros(nR, nC);
    condCube  = cube;
    return
end

% Normalised wavelength axis for linear continuum [0, 1]
wlN = (wlW - wlW(1)) / (wlW(end) - wlW(1));   % [1 × nBw]

% ── Reshape CO2 window → [nPix × nBw] ───────────────────────────────────
nPix = nR * nC;
X    = double(reshape(cube(:,:,co2Mask), nPix, nBw));

gasCol = zeros(nPix, 1);

% ── Iterative continuum removal ──────────────────────────────────────────
for t = 1 : T

    % Linear continuum: C(λ) = x(λ_0) + (x(λ_end)-x(λ_0)) × wlN
    % Shape: [nPix × nBw]  (broadcast via repmat-free arithmetic)
    slope = X(:,end) - X(:,1);            % [nPix × 1]
    C     = X(:,1) + slope .* wlN;        % [nPix × nBw]

    % Absorption below continuum (≥ 0)
    residual = max(C - X, 0);             % [nPix × nBw]

    % Gas column: integral of absorption, scaled by α
    tau = alpha * sum(residual, 2) / nBw; % [nPix × 1]
    gasCol = gasCol + tau;

    % Normalised absorption shape for spectral update
    rowSum = sum(residual, 2) + 1e-10;    % [nPix × 1]
    shape  = residual ./ rowSum;          % [nPix × nBw], sums to 1 per pixel

    % Update X: remove estimated gas contribution
    X = X + tau .* shape;                 % [nPix × nBw]
end

% Averaged gas column estimate
gasCol = gasCol / T;

% ── Pack outputs ─────────────────────────────────────────────────────────
jrgeScore = reshape(gasCol, nR, nC);

condCube = cube;
condCube(:,:,co2Mask) = single(reshape(X, nR, nC, nBw));
end
