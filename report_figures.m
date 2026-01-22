%REPORT_FIGURES Generate report figures/tables and save them to outputs/figures.

cfg = config();
addpath(genpath("src"));

if ~exist(cfg.fig_dir, "dir"); mkdir(cfg.fig_dir); end
if ~exist(cfg.res_dir, "dir"); mkdir(cfg.res_dir); end

% ---------- pick one example file ----------
T = list_data_files(cfg.data_dir);
exRow = 1;  % change to any index if needed
exPath = T.filepaths(exRow);
exSub  = string(T.subject_id(exRow));
exName = string(T.filenames(exRow));

rec = load_record(exPath, cfg.fs);
x_raw = rec.x;
t = rec.t;
fs = rec.fs;

% Use a short segment for time-domain plots (easier to read)
t0 = 0;
t1 = min(30, t(end));
seg = (t >= t0) & (t <= t1);

% ---------- preprocessing ----------
x_filt = preprocess_signals(x_raw, fs, cfg);

% Optional: save to CSV for later comparison across files
rawMaxAbs3  = max(abs(x_raw(:,3)));
filtMaxAbs3 = max(abs(x_filt(:,3)));
dbgRow = table(string(exName), string(exSub), rawMaxAbs3, filtMaxAbs3, ...
    filtMaxAbs3/max(rawMaxAbs3, eps), ...
    'VariableNames', ["file","subject","maxabs_raw_ecg","maxabs_filt_ecg","ratio"]);

dbgPath = fullfile(cfg.res_dir, "debug_ecg_maxabs.csv");
if exist(dbgPath, "file")
    writetable(dbgRow, dbgPath, "WriteMode", "append");
else
    writetable(dbgRow, dbgPath);
end

% ---------- 1) Raw vs filtered time-domain ----------
fig = figure('Name','Raw_vs_Filtered_Time');
chNames = ["Respiration (ch1)","Pulse (ch2)","ECG (ch3)"];

for ch = 1:3
    subplot(3,1,ch);
    plot(t(seg), x_raw(seg,ch)); hold on;
    plot(t(seg), x_filt(seg,ch));
    grid on;
    ylabel(chNames(ch));
    if ch==1
        title(sprintf("Raw vs filtered (file: %s, subject: %s)", exName, exSub));
        legend("raw","filtered");
    end
    if ch==3; xlabel("Time [s]"); end
end
savefig_png(fig, fullfile(cfg.fig_dir, "raw_vs_filtered_time.png"));

% ---------- 2) PSD before/after (resp + pulse) ----------
welch_win = hann(round(cfg.welch_sec * fs));
welch_ov  = round(cfg.welch_ov * numel(welch_win));
nfft      = cfg.welch_nfft;

% Resp PSD
fig = figure('Name','PSD_Resp_Before_After');
[P1,F1] = pwelch(x_raw(:,1),  welch_win, welch_ov, nfft, fs);
[P2,F2] = pwelch(x_filt(:,1), welch_win, welch_ov, nfft, fs);
plot(F1,10*log10(P1)); hold on; plot(F2,10*log10(P2));
grid on; xlim([0 5]);
xlabel("Frequency [Hz]"); ylabel("PSD [dB/Hz]");
title("Respiration PSD: raw vs filtered");
legend("raw","filtered");
savefig_png(fig, fullfile(cfg.fig_dir, "psd_resp_before_after.png"));

% Pulse PSD
fig = figure('Name','PSD_Pulse_Before_After');
[P1,F1] = pwelch(x_raw(:,2),  welch_win, welch_ov, nfft, fs);
[P2,F2] = pwelch(x_filt(:,2), welch_win, welch_ov, nfft, fs);
plot(F1,10*log10(P1)); hold on; plot(F2,10*log10(P2));
grid on; xlim([0 10]);
xlabel("Frequency [Hz]"); ylabel("PSD [dB/Hz]");
title("Pulse PSD: raw vs filtered");
legend("raw","filtered");
savefig_png(fig, fullfile(cfg.fig_dir, "psd_pulse_before_after.png"));

% ---------- 3) Window comparison (rect vs hann) on FFT magnitude ----------
% Take one analysis window from the filtered signal for illustration
winN = round(cfg.win_sec * fs);
if size(x_filt,1) < winN
    warning("Example file shorter than cfg.win_sec window; skipping FFT window comparison.");
else
    w = x_filt(1:winN, 2);  % use pulse channel (often has clear periodic content)
    NFFT = 2^nextpow2(winN);
    f = (0:(NFFT/2))*(fs/NFFT);

    w_rect = w .* ones(winN,1);
    w_hann = w .* hann(winN);

    Xr = fft(w_rect, NFFT);
    Xh = fft(w_hann, NFFT);

    magR = abs(Xr(1:NFFT/2+1));
    magH = abs(Xh(1:NFFT/2+1));

    fig = figure('Name','FFT_Window_Comparison');
    plot(f, magR); hold on; plot(f, magH);
    grid on; xlim([0 10]);
    xlabel("Frequency [Hz]"); ylabel("|FFT|");
    title(sprintf("FFT magnitude: rect vs hann (pulse, %ds window)", cfg.win_sec));
    legend("rect","hann");
    savefig_png(fig, fullfile(cfg.fig_dir, "fft_window_rect_vs_hann.png"));
end

% ---------- 4) ECG R-peaks + RR histogram ----------
seg_sec = 15;

ecg_f = x_filt(:,3);
i0 = pick_high_energy_segment(ecg_f, fs, seg_sec);
i1 = min(size(x_filt,1), i0 + round(seg_sec*fs) - 1);

tseg = t(i0:i1);
ecgseg = ecg_f(i0:i1);

qrs = detect_qrs_pantompkins(ecg_f, fs, cfg);

if ~isempty(qrs) && isfield(qrs,'r_locs') && numel(qrs.r_locs) >= 2

    r = qrs.r_locs;
    r = r(r>=i0 & r<=i1);

    fig = figure('Name','ECG_Rpeaks');
    plot(tseg, ecgseg); hold on;
    plot(t(r), ecg_f(r), 'o');
    grid on;
    xlabel("Time [s]"); ylabel("ECG (filtered)");
    title("ECG with detected R-peaks (Pan–Tompkins-like)");
    legend("ECG","R-peaks");
    savefig_png(fig, fullfile(cfg.fig_dir, "ecg_rpeaks.png"));
    close(fig);

    RR = diff(qrs.r_locs) / fs;
    fig = figure('Name','RR_Histogram');
    histogram(RR, 30);
    grid on;
    xlabel("RR interval [s]"); ylabel("Count");
    title("RR interval histogram");
    savefig_png(fig, fullfile(cfg.fig_dir, "rr_histogram.png"));
    close(fig);

else
    warning("QRS detection returned <2 peaks for the example file; skipping ECG peak plots.");
end


% ---------- 5) PCA on features + confusion matrix ----------
resPath = fullfile(cfg.res_dir, "results.mat");
if exist(resPath, "file")
    S = load(resPath, "results", "cfg", "metaWin");
    results = S.results;

    % Confusion matrix (saved as PNG)
    fig = figure('Name','Confusion_Matrix');
    cc = confusionchart(results.CM, string(results.order));
    cc.Title = sprintf("Confusion matrix (%s, %s)", upper(cfg.model), upper(cfg.cv_mode));
    style_confusionchart(cc);
    savefig_png(fig, fullfile(cfg.fig_dir, "confusion_matrix.png"));

    % PCA on full feature dataset (visualization only)
    % Rebuild X,y once using current cfg to match the result structure
    [Xall, yall] = build_dataset(T, cfg);

    [Ximp, imp] = impute_nans(Xall, []);
    [Xz, zs]    = safe_zscore(Ximp, []);

    [coeff, score, ~] = pca(Xz);

    fig = figure('Name','PCA_Features');
    gscatter(score(:,1), score(:,2), yall);
    grid on;
    xlabel("PC1"); ylabel("PC2");
    title("PCA of window-level features (visualization)");
    savefig_png(fig, fullfile(cfg.fig_dir, "pca_features_pc1_pc2.png"));
else
    warning("results.mat not found in outputs/results; run main_experiment first to get confusion matrix.");
end

% ---------- 6) DEV grid-search summaries (from gridsearch_dev.csv) ----------
gridCSV = fullfile(cfg.res_dir, "gridsearch_dev.csv");
if exist(gridCSV, "file")
    R = readtable(gridCSV);
    if any(strcmpi(R.Properties.VariableNames, "F1_macro")) && any(strcmpi(R.Properties.VariableNames, "win_sec"))
        % Aggregate best F1 per win_sec (max over other params)
        winU = unique(R.win_sec);
        bestF1 = NaN(size(winU));
        for i = 1:numel(winU)
            bestF1(i) = max(R.F1_macro(R.win_sec == winU(i)));
        end

        fig = figure('Name','F1_vs_Window');
        plot(winU, bestF1, '-o');
        grid on;
        xlabel("Window length [s]"); ylabel("Best DEV Macro-F1");
        title("Best Macro-F1 vs window length (DEV grid-search)");
        savefig_png(fig, fullfile(cfg.fig_dir, "macroF1_vs_window_length.png"));
    else
        warning("gridsearch_dev.csv missing expected columns (win_sec, F1_macro).");
    end

    % Top-1 one-factor-at-a-time plots (vary one param, keep others fixed)
    if all(ismember(["accuracy","F1_macro"], R.Properties.VariableNames))
        plot_top1_ofat(R, cfg.fig_dir);
    else
        warning("gridsearch_dev.csv missing expected columns (accuracy, F1_macro).");
    end

    % Save top-10 table
    if any(strcmpi(R.Properties.VariableNames, "F1_macro"))
        R2 = sortrows(R, "F1_macro", "descend");
        top10 = R2(1:min(10,height(R2)), :);
        writetable(top10, fullfile(cfg.res_dir, "gridsearch_top10.csv"));
    end
else
    warning("gridsearch_dev.csv not found; run run_gridsearch_dev first to get F1 vs window length.");
end

fprintf("Report artifacts saved to: %s\n", cfg.fig_dir);

function idx0 = pick_high_energy_segment(x, fs, seg_sec)
N = numel(x);
segN = max(1, round(seg_sec*fs));
segN = min(segN, N);

e = movmean(x.^2, segN, "Endpoints", "shrink");
[~, i] = max(e);
idx0 = max(1, i - segN + 1);
idx0 = min(idx0, N - segN + 1);
end


function plot_top1_ofat(R, fig_dir)
%PLOT_TOP1_OFAT Plot ACC/F1 while varying one parameter, others fixed to TOP-1.
if ~all(ismember(["accuracy","F1_macro"], R.Properties.VariableNames))
    return;
end

R2 = sortrows(R, ["F1_macro","accuracy"], "descend");
base = R2(1,:);

params_num = ["win_sec","overlap","svm_C"];
params_cat = ["win_type","svm_kernel","resp_band","pulse_band","ecg_band"];

for p = params_num
    if any(strcmpi(R.Properties.VariableNames, p))
        plot_ofat_numeric(R, base, p, fig_dir);
    end
end
for p = params_cat
    if any(strcmpi(R.Properties.VariableNames, p))
        plot_ofat_categorical(R, base, p, fig_dir);
    end
end
end

function plot_ofat_numeric(R, base, param, fig_dir)
mask = true(height(R),1);
vars = R.Properties.VariableNames;
for i = 1:numel(vars)
    v = vars{i};
    if strcmpi(v, param) || strcmpi(v, "accuracy") || strcmpi(v, "F1_macro") || strcmpi(v, "n_windows")
        continue;
    end
    mask = mask & strcmp(string(R.(v)), string(base.(v)));
end
S = R(mask,:);
if height(S) < 2; return; end

[x, order] = sort(S.(param));
acc = S.accuracy(order);
f1  = S.F1_macro(order);

fig = figure('Name', sprintf('Top1_OFAT_%s', param));
plot(x, acc, '-o'); hold on;
plot(x, f1,  '-o');
grid on;
xlabel(strrep(param, "_", " "));
ylabel("DEV score");
title(sprintf("TOP1 OFAT: %s", strrep(param, "_", " ")));
legend("ACC", "F1_macro", "Location", "best");
savefig_png(fig, fullfile(fig_dir, sprintf("top1_ofat_%s.png", param)));
end

function plot_ofat_categorical(R, base, param, fig_dir)
mask = true(height(R),1);
vars = R.Properties.VariableNames;
for i = 1:numel(vars)
    v = vars{i};
    if strcmpi(v, param) || strcmpi(v, "accuracy") || strcmpi(v, "F1_macro") || strcmpi(v, "n_windows")
        continue;
    end
    mask = mask & strcmp(string(R.(v)), string(base.(v)));
end
S = R(mask,:);
if height(S) < 2; return; end

vals = string(S.(param));
[u, ia] = unique(vals, "stable");
acc = S.accuracy(ia);
f1  = S.F1_macro(ia);

x = 1:numel(u);
fig = figure('Name', sprintf('Top1_OFAT_%s', param));
plot(x, acc, '-o'); hold on;
plot(x, f1,  '-o');
grid on;
set(gca, "XTick", x, "XTickLabel", u);
xlabel(strrep(param, "_", " "));
ylabel("DEV score");
title(sprintf("TOP1 OFAT: %s", strrep(param, "_", " ")));
legend("ACC", "F1_macro", "Location", "best");
savefig_png(fig, fullfile(fig_dir, sprintf("top1_ofat_%s.png", param)));
end
