# CO2 Plume Detection — Validation Framework
### Spectral Conditioning (CIBR + JRGE + SFA) vs. Baseline CTMF

---

## 1. Purpose

This package implements the **full validation section** comparing the
*proposed spectral-conditioning pipeline* against the *baseline CTMF*
of Marion et al. (2004).

| Configuration | Pipeline |
|---|---|
| **Baseline** | Raw AVIRIS reflectance → CTMF → Otsu |
| **Proposed** | Raw AVIRIS → CIBR → JRGE → SFA → CTMF → Otsu |

The objective is to demonstrate that CIBR + JRGE + SFA spectral
conditioning produces better plume localisation, reduced background
clutter, and more concentrated anomaly responses compared with applying
CTMF directly to raw reflectance.

---

## 2. Dataset

| Field | Value |
|---|---|
| Sensor | AVIRIS-Classic |
| File | `f250923t01p00r13_rfl`  +  `f250923t01p00r13_rfl.hdr` |
| Format | ENVI BSQ, int16, big-endian |
| Bands | 224 (365 – 2496 nm) |
| Scale | raw_int ÷ 10 000 = reflectance |
| Spatial crop | 1 000 × 1 000 px → block-mean ÷ 5 → 200 × 200 |

Place both files in the **same directory** as the MATLAB scripts before
running.

---

## 3. Toolbox Requirements

| Toolbox | Required by |
|---|---|
| **Statistics and Machine Learning** | `kmeans`, `prctile`, `kmeans` |
| **Image Processing** | `graythresh`, `mat2gray`, `imshow` |

Both are standard MathWorks add-ons available in most MATLAB
installations. Verify with:

```matlab
license('test','statistics_toolbox')
license('test','image_toolbox')
```

---

## 4. File Structure

```
co2_validation/
│
├── Helper functions
│   ├── load_aviris_cube.m      ENVI BSQ reader with crop + downsample
│   ├── build_target_spectrum.m Dual-Gaussian CO2 target  d(λ)
│   ├── compute_ctmf.m          Cluster-Tuned Matched Filter engine
│   ├── compute_cibr.m          Continuum Interpolated Band Ratio
│   ├── compute_jrge.m          Joint Reflectance & Gas Estimator
│   ├── compute_sfa.m           Spectral Fitting Algorithm
│   └── get_rgb_composite.m     Contrast-stretched RGB for display
│
├── Main validation scripts
│   ├── baseline_ctmf.m         Step 1 — Raw AVIRIS → CTMF
│   ├── save_proposed_results.m Step 2 — Full proposed pipeline
│   ├── figure_comparison.m     Step 3 — Six-panel comparison figure
│   ├── histogram_comparison.m  Step 4 — Score histogram analysis
│   ├── profile_analysis.m      Step 5 — Horizontal profile
│   ├── selectivity_metrics.m   Step 6 — Selectivity metrics table
│   ├── ablation_study.m        Step 7 — Four-stage ablation table
│   ├── ablation_figure.m       Step 8 — Ablation 2×2 figure
│   └── threshold_sensitivity.m Step 9 — Threshold sensitivity
│
└── run_all_validation.m        Master script — runs Steps 1–9 in order
```

---

## 5. Quick Start

```matlab
% 1.  Open MATLAB in the co2_validation/ directory  (or cd to it)
cd /path/to/co2_validation

% 2.  Ensure AVIRIS files are present
ls('f250923t01p00r13_rfl*')

% 3.  Run everything
run_all_validation
```

To run individual steps:

```matlab
run baseline_ctmf           % Step 1
run save_proposed_results   % Step 2  (depends on nothing)
run figure_comparison       % Step 3  (depends on Steps 1 & 2)
run histogram_comparison    % Step 4  (depends on Steps 1 & 2)
run profile_analysis        % Step 5  (depends on Steps 1 & 2)
run selectivity_metrics     % Step 6  (depends on Steps 1 & 2)
run ablation_study          % Step 7  (depends on Step 2)
run ablation_figure         % Step 8  (depends on Step 2)
run threshold_sensitivity   % Step 9  (depends on Step 2)
```

---

## 6. Output Files

### Figures

| File | Contents |
|---|---|
| `comparison_pipeline.png` | RGB + Baseline CTMF + CIBR + JRGE + SFA + Proposed CTMF |
| `histogram_scores.png` | Overlaid probability histograms of baseline vs. proposed scores |
| `profile_comparison.png` | Horizontal profile through plume centre row |
| `ablation_maps.png` | 2×2 grid: CIBR / JRGE / SFA / CTMF score maps |
| `threshold_sensitivity.png` | Coverage (%) and mean hotspot score vs. threshold method |

### Tables (CSV)

| File | Contents |
|---|---|
| `quantitative_metrics.csv` | Mean, Max, σ, P95, hotspot count, coverage, selectivity ratio |
| `ablation_results.csv` | Same metrics for each of the four ablation stages |
| `threshold_results.csv` | Coverage / hotspot count / mean hotspot score per threshold |

### MAT files

| File | Variables |
|---|---|
| `baseline_ctmf_results.mat` | `baselineScore`, `baselineMask`, `thresholdBaseline`, `wlSWIR` |
| `proposed_results.mat` | `cibrScore`, `jrgeScore`, `sfaScore`, `ctmfScore`, `binaryMask`, `cube` |

---

## 7. Algorithm Parameters

| Parameter | Value | Location |
|---|---|---|
| Spatial crop | rows 1–1000, cols 1–1000 | `baseline_ctmf.m`, `save_proposed_results.m` |
| Downsampling | ×5 block mean → 200×200 | same |
| Reflectance scale | ÷ 10 000 | same |
| SWIR window | 1 500 – 2 200 nm | same |
| CTMF clusters K | 4 | same |
| CTMF regularisation λ | 10⁻⁶ | same |
| RNG seed | 1 | same |
| Target spectrum | 0.30·G(1575,15) + 0.70·G(2005,12) | `build_target_spectrum.m` |
| CIBR left baseline | 2 000 – 2 020 nm | `compute_cibr.m` |
| CIBR absorption | 2 040 – 2 060 nm | same |
| CIBR right baseline | 2 080 – 2 100 nm | same |
| JRGE window | 2 000 – 2 100 nm | `compute_jrge.m` |
| JRGE α | 0.05 | same |
| JRGE iterations T | 3 | same |
| SFA SWIR window | 1 500 – 2 100 nm | `compute_sfa.m` |
| Threshold | Otsu (auto) | all main scripts |

---

## 8. Sign Convention

All score maps are signed so that **positive values indicate a CO2-like
anomaly** and background pixels cluster near zero:

- **CIBR**: `score = 1 − CIBR`  (positive = absorption below continuum)
- **JRGE**: integral of absorption residual below the linear continuum
- **SFA**: negated cosine similarity (CO2 reduces reflectance, negation gives positive score)
- **CTMF**: matched-filter output; the dual-Gaussian target is negated in
  `build_target_spectrum.m` so the dot product with a CO2 deficit spectrum
  is positive.

---

## 9. What the Metrics Show

| Metric | What it demonstrates |
|---|---|
| **Selectivity Ratio** (Max/Mean) | Concentration of the anomaly response at the plume vs. the whole scene |
| **Coverage (%)** | Background suppression — lower is better (fewer false positives) |
| **95th Percentile** | Upper-tail score concentration near the true plume |
| **Std Deviation** | Distribution spread — lower means the background is flatter |
| **PBR (Profile)** | Peak-to-background ratio along the plume row — higher = sharper localisation |

---

## 10. Reference

Marion, R., Michel, R., & Faye, C. (2004).
**Measuring trace gases in plumes from hyperspectral remotely sensed data.**
*IEEE Transactions on Geoscience and Remote Sensing*, 42(4), 854–864.
