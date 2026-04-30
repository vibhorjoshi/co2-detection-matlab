# CO2 Detection from Hyperspectral Data

MATLAB implementation of four CO₂ detection algorithms applied to AVIRIS hyperspectral imagery.

---

## Files

| File | Purpose |
|---|---|
| `co2_cibr.m` | Continuum Interpolated Band Ratio |
| `co2_ctmf.m` | Cluster-Tuned Matched Filter |
| `co2_jrge.m` | Joint Reflectance and Gas Estimator |
| `co2_sfa.m` | Spectral Fitting Algorithm |
| `main_co2_visualisation.m` | Runs all four methods and plots results |

---

## Requirements

- MATLAB R2020b or later
- Image Processing Toolbox (Hyperspectral Imaging Library) — for `hypercube()`
- Statistics and Machine Learning Toolbox — for `cov()`
- Curve Fitting Toolbox — for `csaps()`, `fnval()`

---

## Data

Each function expects a different AVIRIS dataset. Download Level-2 reflectance scenes from:
- https://aviris.jpl.nasa.gov/dataportal/
- https://earthexplorer.usgs.gov

You need two files per scene: a `.hdr` header and a `.img` or `.bin` binary data file.

> **Important:** Do not pass PNG screenshots or map viewer exports to `hypercube()`. It only accepts ENVI binary, NITF, or multi-band GeoTIFF formats.

---

## File Instructions

---

### `co2_cibr.m`

**What it does:** Detects CO₂ by measuring the depth of absorption at the 2.04–2.06 µm SWIR band relative to a continuum estimated from shoulder bands on either side.

**Dataset used:** `f250923t01p00r13_rfl` (AVIRIS Classic)

**Before running:**
1. Update `hdr_file` and `bin_file` to point to your local `.hdr` and `.bin` files:
   ```matlab
   hdr_file = 'your\path\f250923t01p00r13_rfl.hdr';
   bin_file  = 'your\path\f250923t01p00r13_rfl.bin';
   ```
2. The function crops to the first 1000×1000 pixels to avoid loading the full 38 GB file. Adjust the crop range in `cropData(hcube, [1 1000], [1 1000])` if needed.

**Run:**
```matlab
[co2_index, hotspot_mask] = co2_cibr();
```

**Outputs:**
- `co2_index` — normalised 2D CIBR score map (0 to 1, higher = more CO₂)
- `hotspot_mask` — binary detection map (logical array)
- Two figures: CIBR score map and hotspot mask

**CO₂ bands used:**
- Left shoulder: 2000–2020 nm
- Absorption centre: 2040–2060 nm
- Right shoulder: 2080–2100 nm

---

### `co2_ctmf.m`

**What it does:** Groups pixels into spectral clusters using k-means, then applies a matched filter tuned to a CO₂-like absorption signature for each cluster.

**Dataset used:** `GLREFL_Cape_Cod_Jun2016_7_at-sensor_refl_L1G` (AVIRIS)

**Before running:**
1. Update `hdrPath` to your local `.hdr` file:
   ```matlab
   hdrPath = 'your\path\GLREFL_Cape_Cod_Jun2016_7_at-sensor_refl_L1G.hdr';
   ```
2. Note: this dataset covers the visible/NIR range (~750 nm region). It does not extend to the 2.0 µm CO₂ SWIR band, so the matched filter uses a proxy absorption feature near 750–770 nm. For proper CO₂ detection, use an AVIRIS scene with SWIR coverage (wavelengths up to 2500 nm).

**Run:**
```matlab
[mf_image, binaryMap] = co2_ctmf();
```

**Outputs:**
- `mf_image` — normalised matched-filter score image
- `binaryMap` — binary detection map
- Two figures: detection map and hotspot mask

**Parameters you can change in the file:**
- `k = 4` — number of k-means clusters (increase for more spectrally diverse scenes)
- `maxIter = 20` — maximum k-means iterations

**Note:** `simple_kmeans` is a custom k-means function defined at the bottom of `co2_ctmf.m`. It is slower than MATLAB's built-in `kmeans()` but has no additional toolbox requirement.

---

### `co2_jrge.m`

**What it does:** Iteratively estimates surface reflectance using a smoothing spline (CSAPS), then computes a gas density proxy from the residual between observed and estimated reflectance in the CO₂ absorption window.

**Dataset used:** `AVIRIS-Classic_L2_Reflectance.f130503t01p00r23rdn_refl_img_corr`

**Before running:**
1. Update `hdr_file` to your local path:
   ```matlab
   hdr_file = 'your\path\AVIRIS-Classic_L2_Reflectance...rfl_img_corr.hdr';
   ```
2. The function automatically scales reflectance from 0–10000 to 0–1 if needed.
3. It downsamples spatially by a factor of 5 before processing.

**Run:**
```matlab
[gas_map, binary_hotspots] = co2_jrge();
```

**Outputs:**
- `gas_map` — normalised 2D gas density map (0 to 1)
- `binary_hotspots` — binary detection mask
- Two figures: gas density map and hotspot mask

**CO₂ band logic:**
- Primary target: 2000–2100 nm (SWIR, correct CO₂ window)
- Fallback if SWIR bands absent: 640–660 nm (visible red proxy — not physically meaningful for CO₂)
- The fallback prints a warning. If it triggers, your dataset likely does not cover SWIR wavelengths.

**Parameters you can change:**
- `ds = 5` — spatial downsampling factor (line starting `cube = cube(1:ds:end...`)
- Smoothing parameter `0.9` in `csaps(1:bands, spectrum, 0.9)` — closer to 1 = less smoothing

---

### `co2_sfa.m`

**What it does:** Matches each pixel's SWIR spectrum against a reference CO₂ absorption shape using normalised cross-correlation. The reference is a dual-Gaussian approximating CO₂ absorption at 1575 nm and 2005 nm.

**How it differs from the other three:** This is the only function that takes a `hypercube` object as input rather than loading data internally. It must be called from `main_co2_visualisation.m` or after loading a hypercube manually.

**Before running:**  
Load your data first, then pass it in:
```matlab
hcube = hypercube('your\path\scene.hdr');
[co2_map, binary_map] = co2_sfa(hcube);
```

Or with a custom threshold multiplier (default = 1.0):
```matlab
[co2_map, binary_map] = co2_sfa(hcube, 1.2);
```

**Outputs:**
- `co2_map` — normalised correlation score map (0 to 1)
- `binary_map` — binary hotspot mask
- Prints threshold and detection count to Command Window

**Requirement:** Dataset must have bands in the 1500–2100 nm range (at least 10 bands). The function errors if this condition is not met.

**CO₂ reference bands:**
- 1575 nm — 1.6 µm absorption feature (amplitude 0.30)
- 2005 nm — 2.0 µm absorption feature (amplitude 0.70, dominant)

---

### `main_co2_visualisation.m`

**What it does:** Calls all four detection functions, displays 2×2 index maps and hotspot mask figures, prints statistics, and plots geospatial hotspot maps using manually computed world coordinates.

**Before running:**

1. Each detection function (`co2_cibr`, `co2_ctmf`, `co2_jrge`) loads its own dataset internally. Make sure the file paths inside each of those functions are updated first.

2. `co2_sfa` is called without arguments in this script — update the line to pass a loaded hypercube:
   ```matlab
   % Replace this:
   [idx_sfa, mask_sfa] = co2_sfa();
   
   % With this:
   hcube = hypercube('your\path\scene.hdr');
   [idx_sfa, mask_sfa] = co2_sfa(hcube);
   ```

3. Update the geospatial coordinates to match your scene's `.hdr` metadata:
   ```matlab
   ulx        = 314881.49;   % Upper-left Easting (from .hdr map info)
   uly        = 4218923.9;   % Upper-left Northing (from .hdr map info)
   pixel_size = 14.1 * 5;   % Native pixel size × downsample factor
   ```
   These values are found in the `map info` field of your ENVI `.hdr` file.

**Run:**
```matlab
main_co2_visualisation
```

**Outputs — 3 figures:**
1. 2×2 grid of CO₂ index maps (CIBR, CTMF, JRGE, SFA)
2. 2×2 grid of binary hotspot masks
3. 2×2 geospatial hotspot maps with Easting/Northing axes

**Statistics printed to Command Window:**
```
CIBR: mean=0.312, max=1.000, hotspot%=14.2%
CTMF: mean=0.274, max=1.000, hotspot%=11.8%
...
```

---

## Known Limitations

- **No Mapping Toolbox:** Geospatial plots use `imagesc` with manually computed UTM coordinates. This works but does not produce a projected basemap. For proper georeferencing, use `worldmap` + `geoshow` with a `georasterref` object from the Mapping Toolbox.
- **Different datasets per function:** Each function uses a different AVIRIS scene with different wavelength coverage. Results are not directly comparable across algorithms.
- **CTMF dataset wavelength range:** The Cape Cod dataset used in `co2_ctmf.m` does not cover the 2.0 µm CO₂ SWIR band. The absorption signature used is a NIR proxy, not true CO₂.
- **`co2_sfa` input mismatch in main script:** The main script calls `co2_sfa()` with no arguments, but the function requires a `hypercube` object. This will error unless fixed as shown above.

---

## License

MIT
