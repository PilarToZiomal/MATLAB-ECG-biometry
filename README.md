# CPS\_proj

Pipeline for person identification from physiological signals (respiration, pulse, ECG).

## Project layout

- `config.m` central configuration (sampling, filters, windows, models).
- `main_experiment.m` train/evaluate on full dataset (cross-validation).
- `run_gridsearch_dev.m` grid-search on DEV split.
- `eval_final_test.m` evaluate top DEV configs on held-out TEST.
- `report_figures.m` generate report plots into `outputs/figures`.
- `config.m` central configuration for sampling rate, filtering, windowing, features, and model defaults.
- `src/` helper functions (loading, preprocessing, features, training).
- `Data/` input recordings (not included in repo).
- `outputs/` generated results and figures.

## Data structure

Expected folder layout under `Data/`:

```
Data/
  AS/
    AS_F_03_01.txt
    AS_F_03_02.txt
    ...
  BS/
  DA/
  ...
```

Each `.txt` file should contain a text header followed by numeric rows with four columns:

```
time  ch1  ch2  ch3
```

Where channel order is assumed to be:
- ch1: respiration
- ch2: pulse
- ch3: ECG

The parent folder name is used as the subject label (class).

## Outputs

Generated outputs are written to `outputs/`:

- `outputs/results/`:
  - `gridsearch_dev.csv` full DEV grid-search results.
  - `gridsearch_dev_top3.csv` top DEV configs for TEST.
  - `results.mat` metrics and metadata from `main_experiment`.
- `outputs/figures/`:
  - `raw_vs_filtered_time.png`, `psd_*`, `ecg_rpeaks.png`, `rr_histogram.png`,
    `confusion_matrix.png`, `pca_features_pc1_pc2.png`, `fft_window_rect_vs_hann.png`,
    `macroF1_vs_window_length.png`, `top1_ofat_*.png`.

## Quick start

1. Set paths and parameters in `config.m`.
2. Run grid-search on DEV and create top configs:
   ```
   run_gridsearch_dev
   ```
   Grid-search parameters (windowing, bands, SVM settings) are defined at the top of `run_gridsearch_dev.m`.
3. Evaluate top configs on TEST:
   ```
   eval_final_test
   ```
4. Train/evaluate on the full dataset:
   ```
   main_experiment
   ```
5. Generate figures for the report:
   ```
   report_figures
   ```
   This will also create OFAT plots (`top1_ofat_*.png`) showing the impact of changing one parameter at a time
   around the best DEV configuration.

## Install from GitHub

Clone the repository and open it in MATLAB:

```bash
git clone https://github.com/PilarToZiomal/MATLAB-ECG-biometry.git
cd MATLAB-ECG-biometry
```

Then in MATLAB:

```matlab
addpath(genpath("src"))
```

Set `cfg.data_dir` in `config.m` to point to your `Data/` directory.

## Notes

- The pipeline avoids leakage by splitting DEV/TEST at the file level.
- Normalization and imputation are learned only from training splits.
- Figures are saved via `src/savefig_png.m` with consistent styling.

## Requirements

- MATLAB with Signal Processing Toolbox.
- Statistics and Machine Learning Toolbox for SVM/kNN.
