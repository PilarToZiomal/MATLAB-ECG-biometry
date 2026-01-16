function cfg = config()
%CONFIG Central configuration for preprocessing, features, and models.
cfg = struct();

cfg.fs = 100;
cfg.seed = 42;

cfg.data_dir = "/Data";
cfg.out_dir  = "outputs";
cfg.fig_dir  = fullfile(cfg.out_dir, "figures");
cfg.res_dir  = fullfile(cfg.out_dir, "results");

% Channel-specific bandpass ranges (Hz); tune based on physiology + data quality
cfg.filt_order = 4;
cfg.resp_band  = [0.1 0.7];
cfg.pulse_band = [0.7  4.0];
cfg.ecg_band   = [1.0 35.0];

% Windowing for feature extraction (controls time/frequency resolution trade-off)
cfg.win_sec     = 16;
cfg.overlap     = 0.50;
cfg.win_type    = "rect";  % "rect" | "hann" | "hamming"

% Separate (longer) windowing for HRV can be used if you decide to compute HRV on longer segments
cfg.hrv_win_sec   = 60;
cfg.hrv_overlap   = 0.50;

% Welch PSD settings (segment length/overlap/nfft affect PSD smoothness and resolution)
cfg.welch_sec   = 4;
cfg.welch_ov    = 0.50;
cfg.welch_nfft  = 1024;

% Bandpower integration bands (Hz) used as spectral features
cfg.resp_bp_band   = [0.10 0.35];
cfg.pulse_bp_band  = [0.70 3.00];
cfg.pulse_hi_band  = [3.00 5.00];
cfg.ecg_qrs_band   = [5.00 15.0];

% Pan–Tompkins-like QRS detector parameters (thresholding + refractory period)
cfg.qrs_band        = [5 15];
cfg.qrs_filt_order  = 3;
cfg.qrs_mwi_ms      = 150;
cfg.qrs_min_rr_s    = 0.25;
cfg.qrs_refine_ms   = 80;
cfg.qrs_thr_k       = 4;  % typical tuning range: 3..5
cfg.qrs_ignore_s    = 0.5;

% Validation and model selection
cfg.cv_mode = "LOFO";   % "LOFO" keeps all windows from the same file together; "LOSO" keeps subjects together
cfg.model   = "svm";    % "svm" | "knn"
cfg.svm_kernel = "linear"; % "rbf" | "linear"
cfg.svm_C = 10;
cfg.knn_k = 5;

% HRV feature reliability guard (skip HRV if too few RR intervals in a window)
cfg.min_rr_count_for_hrv = 8;

cfg.plot_confusion = false;

end
