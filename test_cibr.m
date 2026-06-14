%% --- TOP PART: THE CONTROLLER SCRIPT ---
% This part runs automatically when you click the "Run" button.
clear; 
clc;

disp('1. Creating test data...');
% Create a dummy list of wavelengths (e.g., 2000nm to 2100nm)
my_wavelengths = 2000:2:2100; 

% Create a dummy 5x5 hyperspectral image with 51 bands
my_cube = rand(5, 5, length(my_wavelengths));

disp('2. Feeding data into the CIBR machine...');
% This successfully passes the data to the function below
my_result = co2_cibr(my_cube, my_wavelengths);

disp('3. Success! No errors. Here is a preview of the CIBR score:');
disp(my_result(1:3, 1:3)); 


%% --- BOTTOM PART: THE FUNCTION ---
% By putting the function at the bottom of the script, MATLAB knows 
% exactly where to find it without throwing an input error.

function cibrScore = co2_cibr(cube, wavelengths)
    wl = wavelengths(:)';

    % ── Band-group masks ─────────────────────────────────────────────────────
    maskL = wl >= 2000 & wl <= 2020;   % left continuum
    maskA = wl >= 2040 & wl <= 2060;   % CO2 absorption
    maskR = wl >= 2080 & wl <= 2100;   % right continuum

    if sum(maskA) == 0
        error('compute_cibr: no bands in CO2 absorption window 2040–2060 nm.');
    end
    if sum(maskL) == 0 || sum(maskR) == 0
        error('compute_cibr: missing left or right baseline bands.');
    end

    % ── Mean reflectance over each group ────────────────────────────────────
    RL = double(mean(cube(:,:,maskL), 3));
    RA = double(mean(cube(:,:,maskA), 3));
    RR = double(mean(cube(:,:,maskR), 3));

    % ── Interpolation weights (spectral distance) ────────────────────────────
    wlL = mean(wl(maskL));   % centre of left group  (nm)
    wlA = mean(wl(maskA));   % centre of absorption  (nm)
    wlR = mean(wl(maskR));   % centre of right group (nm)

    span = wlR - wlL;
    wW   = (wlR - wlA) / span;   % weight on left  shoulder
    wE   = (wlA - wlL) / span;   % weight on right shoulder

    % ── Interpolated continuum and CIBR ─────────────────────────────────────
    Rcont     = wW .* RL + wE .* RR;
    CIBR      = RA ./ max(Rcont, 1e-8);
    cibrScore = max(0, 1 - CIBR);      % higher ⟹ stronger CO2 absorption
end