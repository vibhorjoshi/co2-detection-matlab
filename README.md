# 🌍 CO₂ Detection from Hyperspectral Imagery using AVIRIS Data

<p align="center">

![MATLAB](https://img.shields.io/badge/MATLAB-R2020b+-orange)
![Hyperspectral](https://img.shields.io/badge/Data-AVIRIS-blue)
![License](https://img.shields.io/badge/License-MIT-green)
![Remote Sensing](https://img.shields.io/badge/Domain-Hyperspectral%20CO₂-red)

</p>

---

## 📌 Overview

This repository implements multiple **CO₂ detection algorithms** for **AVIRIS hyperspectral imagery**, enabling spectral anomaly detection, gas density estimation, plume extraction, and spectral fitting.

The framework evaluates four different approaches:

- **CIBR** → Continuum Interpolated Band Ratio
- **CTMF** → Cluster Tuned Matched Filter
- **JRGE** → Joint Reflectance and Gas Estimation
- **SFA** → Spectral Fitting Algorithm

The objective is to identify atmospheric CO₂ signatures from SWIR absorption bands using hyperspectral remote sensing.

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
