function sfaScore = compute_sfa(cube, wavelengths)
%COMPUTE_SFA  Spectral Fitting Algorithm for CO2 detection.
%
%  Projects each background-subtracted pixel spectrum onto the dual-
%  Gaussian CO2 template using cosine similarity in the SWIR window.
%
%  SWIR window : 1500 – 2100 nm
%  Template    : d(λ) = 0.30 G(λ; 1575, 15) + 0.70 G(λ; 2005, 12)
%                (positive where CO2 absorbs)
%  Score       : cos(θ) = (d' (x – µ_bg)) / (‖d‖ ‖x – µ_bg‖)
%
%  Background mean µ_bg is the spatial mean of the scene (robust
%  approximation when the plume covers a small fraction of the image).
%
%  Negative cosine similarity (x departs from background in the
%  absorption direction) is negated so that the returned score is
%  POSITIVE for CO2 plumes.
%
%  INPUT
%    cube        single  [nR × nC × nB]   reflectance cube
%    wavelengths double  [1 × nB]         band-centre wavelengths (nm)
%
%  OUTPUT
%    sfaScore    double  [nR × nC]        spectral fitting score
%                                         (positive ⟹ CO2-like signature)

wl = wavelengths(:)';

% ── SWIR band selection ──────────────────────────────────────────────────
swirMask   = wl >= 1500 & wl <= 2100;
wlSWIR     = wl(swirMask);
cubeSWIR   = double(cube(:,:,swirMask));   % [nR × nC × nBs]

[nR, nC, nBs] = size(cubeSWIR);
nPix = nR * nC;

% ── Dual-Gaussian template (absorption = positive) ───────────────────────
g1 = exp(-((wlSWIR - 1575).^2) ./ (2 * 15^2));
g2 = exp(-((wlSWIR - 2005).^2) ./ (2 * 12^2));
d  = (0.30 * g1 + 0.70 * g2)';        % [nBs × 1]
d  = d / norm(d);                     % L2 normalise

% ── Background subtraction ───────────────────────────────────────────────
X    = reshape(cubeSWIR, nPix, nBs);   % [nPix × nBs]
muBg = mean(X, 1);                     % [1 × nBs]
Xc   = X - muBg;                       % background-subtracted

% ── Cosine similarity ─────────────────────────────────────────────────────
norms = sqrt(sum(Xc.^2, 2));           % [nPix × 1]
norms(norms < eps) = 1;                % guard against zero-norm pixels

% Raw cosine: positive where x–µ aligns with d (absorption template)
% Because CO2 causes REDUCED reflectance, (x-µ) is negative in CO2 bands;
% d is positive there; so cos(θ) < 0 for CO2.
% We negate so that positive sfaScore ⟹ CO2 plume.
cosRaw   = (Xc * d) ./ norms;         % [nPix × 1]
sfaVec   = -cosRaw;                   % flip: positive = CO2

sfaScore = reshape(sfaVec, nR, nC);
end
