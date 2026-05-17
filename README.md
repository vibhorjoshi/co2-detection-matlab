# 🌍 CO₂ Detection from Hyperspectral Imagery using AVIRIS Data

<p align="center">

![MATLAB](https://img.shields.io/badge/MATLAB-R2020b+-orange)
![Hyperspectral](https://img.shields.io/badge/Data-AVIRIS-blue)
![License](https://img.shields.io/badge/License-MIT-green)
![Remote Sensing](https://img.shields.io/badge/Domain-Hyperspectral%20CO₂-red)

</p>

---

## 📌 Overview

This repository presents a MATLAB framework for **CO₂ detection from hyperspectral imagery** using multiple spectral and gas estimation algorithms on **AVIRIS datasets**.

The framework integrates four complementary methods:

- **CIBR** — Continuum Interpolated Band Ratio
- **CTMF** — Cluster Tuned Matched Filter
- **JRGE** — Joint Reflectance and Gas Estimation
- **SFA** — Spectral Fitting Algorithm

The objective is to detect atmospheric CO₂ signatures from **SWIR absorption regions** and generate hotspot maps for plume analysis.

---

# 🛰 Workflow

```text
AVIRIS Hyperspectral Cube
            │
            ▼

      ┌─────────────┐
      │    CIBR     │
      │ Spectral    │
      │ Anomalies   │
      └──────┬──────┘
             │
             ▼

      ┌─────────────┐
      │    JRGE     │
      │ Background  │
      │ Suppression │
      └──────┬──────┘
             │
             ▼

      ┌─────────────┐
      │     SFA     │
      │ Spectral    │
      │ Matching    │
      └──────┬──────┘
             │
             ▼

      ┌─────────────┐
      │    CTMF     │
      │ Final Plume │
      │ Extraction  │
      └─────────────┘
```

---

# 📂 Repository Structure

```bash
CO2-Hyperspectral-Detection/
│
├── co2_cibr.m
├── co2_ctmf.m
├── co2_jrge.m
├── co2_sfa.m
│
├── main_co2_visualisation.m
│
├── datasets/
│   ├── *.hdr
│   ├── *.bin
│
└── README.md
```

---

# 🛰 Dataset

AVIRIS datasets:

- https://aviris.jpl.nasa.gov/dataportal/
- https://earthexplorer.usgs.gov

Required files:

```text
scene.hdr
scene.bin
```

Example:

```text
f250923t01p00r13_rfl.hdr
f250923t01p00r13_rfl.bin
```

Large AVIRIS scenes may exceed:

```text
30–40 GB
```

Therefore spatial cropping is performed before processing.

---

# ⚙ Requirements

MATLAB R2020b+

Required Toolboxes:

```text
Image Processing Toolbox
Curve Fitting Toolbox
Statistics Toolbox
Hyperspectral Imaging Toolbox
```

Important MATLAB functions:

```matlab
hypercube()
multibandread()
csaps()
fnval()
graythresh()
```

---

# 🔬 Algorithms

---

## 1️⃣ CIBR — Continuum Interpolated Band Ratio

CIBR identifies CO₂ absorption around **2.05 μm**.

Equation:

```math
Continuum=\frac{L+R}{2}
```

Improved formulation:

```math
CIBR = Continuum - Absorption
```

Band selection:

```text
Left Band        : 2000–2020 nm
Absorption Band  : 2040–2060 nm
Right Band       : 2080–2100 nm
```

Run:

```matlab
[idx_cibr, mask_cibr] = co2_cibr();
```

Outputs:

```text
CO₂ index map
Binary hotspot map
```

---

## 2️⃣ CTMF — Cluster Tuned Matched Filter

Pipeline:

```text
K-means Clustering
        ↓
Covariance Estimation
        ↓
Matched Filter
        ↓
CO₂ Detection
```

Run:

```matlab
[idx_ctmf, mask_ctmf] = co2_ctmf();
```

Outputs:

```text
Matched filter image
Binary plume map
```

---

## 3️⃣ JRGE — Joint Reflectance and Gas Estimation

Model:

```math
Observed = Reflectance + Gas + Noise
```

Gas estimation:

```math
Gas = EstimatedReflectance − ObservedSignal
```

Run:

```matlab
[idx_jrge, mask_jrge] = co2_jrge();
```

Outputs:

```text
Gas density map
Binary hotspot mask
```

---

## 4️⃣ SFA — Spectral Fitting Algorithm

Uses dual Gaussian reference spectra.

Reference wavelengths:

```text
1575 nm
2005 nm
```

Run:

```matlab
[idx_sfa, mask_sfa] = co2_sfa();
```

Outputs:

```text
Correlation map
Binary detections
```

---

# 📊 Experimental Results

Results from:

```matlab
main_co2_visualisation
```

| Method | Mean Response | Maximum | Hotspot Coverage |
|---------|--------------|---------|------------------|
| CIBR | 0.516 | 1.000 | 10.8% |
| CTMF | 0.557 | 1.000 | 0.1% |
| JRGE | 0.450 | 1.000 | 7.5% |
| SFA | 0.114 | 1.000 | 16.9% |

---

# 📈 Comparative Analysis

## CIBR

Observed hotspot coverage:

```text
10.8%
```

Characteristics:

✅ Balanced spectral detector

✅ Good anomaly localisation

✅ Moderate plume extraction

---

## CTMF

Observed hotspot coverage:

```text
0.1%
```

Characteristics:

✅ Highly selective

✅ Strong background rejection

✅ Lowest false positives

⚠ May miss weak plumes

---

## JRGE

Observed hotspot coverage:

```text
7.5%
```

Characteristics:

✅ Reflectance reconstruction

✅ Stable gas estimation

✅ Better background suppression

---

## SFA

Observed hotspot coverage:

```text
16.9%
```

Characteristics:

✅ Highest sensitivity

✅ Detects weak absorptions

✅ Larger plume extent

⚠ Higher false alarm probability

---

# 🎯 Recommended Detection Pipeline

```text
AVIRIS Cube
      ↓

CIBR
(candidate anomalies)

      ↓

JRGE
(background suppression)

      ↓

SFA
(plume enhancement)

      ↓

CTMF
(final extraction)
```

---

# 🖼 Outputs

Generated figures:

### CO₂ Index Maps

```text
CIBR
CTMF
JRGE
SFA
```

### Binary Outputs

```text
Hotspots
Gas Density Maps
Plume Masks
```

### Geospatial Outputs

```text
UTM Maps
Heatmaps
CO₂ Overlays
```

---

# 🚀 Run

Execute:

```matlab
main_co2_visualisation
```

---

# 📜 Citation

```bibtex
@software{co2_hyperspectral_detection,
title={CO₂ Detection from Hyperspectral AVIRIS Imagery},
author={Your Name},
year={2026}
}
```

---

# 📄 License

MIT License
