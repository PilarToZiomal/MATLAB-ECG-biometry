%RUN_GRIDSEARCH_DEV Grid-search DSP + SVM hyperparameters on DEV split.
cfg0 = config();
cfg0.plot_confusion = false;
rng(cfg0.seed);

addpath(genpath("src"));

% File-level DEV/TEST split for hyperparameter tuning.
T = list_data_files(cfg0.data_dir);

% File-level DEV/TEST split (no window leakage): tuning happens only on DEV
[Tdev, Ttest] = split_dev_test_files(T, 0.2, 42);

fprintf("DEV files: %d | TEST files: %d\n", height(Tdev), height(Ttest));
disp(groupsummary(Tdev, "subject_id"));
disp(groupsummary(Ttest, "subject_id"));

% Small, meaningful parameter grid for DSP + SVM tuning
win_secs    = [8 16];
overlaps    = 0.50;
win_types   = ["rect","hann","hamming"];

resp_bands  = [0.10 0.70];
pulse_bands = [0.70 4.00; 0.70 5.00];
ecg_bands   = [0.50 35.0; 1.00 35.0];

svm_kernels = ["linear","rbf"];
svm_Cs      = [1 10];

rows = {};
k = 0;

% Exhaustive grid over the defined parameter ranges.
for ws = win_secs
for ov = overlaps
for wt = win_types
for rb = 1:size(resp_bands,1)
for pb = 1:size(pulse_bands,1)
for eb = 1:size(ecg_bands,1)
for ker = svm_kernels
for C = svm_Cs

    cfg = cfg0;
    cfg.win_sec   = ws;
    cfg.overlap   = ov;
    cfg.win_type  = wt;

    cfg.resp_band  = resp_bands(rb,:);
    cfg.pulse_band = pulse_bands(pb,:);
    cfg.ecg_band   = ecg_bands(eb,:);

    cfg.model      = "svm";
    cfg.svm_kernel = ker;
    cfg.svm_C      = C;

    % Evaluate configurations only on DEV using LOFO (windows from the same file stay together)
    [X, y, gf, gs] = build_dataset(Tdev, cfg); 
    groups = gf;

    res = train_eval(X, y, groups, cfg);

    k = k + 1;
    rows(k,:) = {ws, ov, char(wt), ...
        mat2str(cfg.resp_band), mat2str(cfg.pulse_band), mat2str(cfg.ecg_band), ...
        char(ker), C, size(X,1), res.accuracy, res.F1_macro};

    fprintf("[%d] win=%d ov=%.2f %s | resp=%s pulse=%s ecg=%s | ker=%s C=%.2g | acc=%.3f f1=%.3f | windows=%d\n", ...
        k, ws, ov, wt, mat2str(cfg.resp_band), mat2str(cfg.pulse_band), mat2str(cfg.ecg_band), ...
        ker, C, res.accuracy, res.F1_macro, size(X,1));

end
end
end
end
end
end
end
end

% Save raw grid and top-N summaries for downstream scripts.
Rdev = cell2table(rows, "VariableNames", ...
    ["win_sec","overlap","win_type","resp_band","pulse_band","ecg_band", ...
     "svm_kernel","svm_C","n_windows","accuracy","F1_macro"]);

if ~exist(cfg0.res_dir, "dir"); mkdir(cfg0.res_dir); end
writetable(Rdev, fullfile(cfg0.res_dir, "gridsearch_dev.csv"));
save(fullfile(cfg0.res_dir, "gridsearch_dev.mat"), "Rdev", "Tdev", "Ttest");

R2 = sortrows(Rdev, "F1_macro", "descend");
disp(R2(1:min(10,height(R2)), :));

% Export top configurations for the final held-out TEST evaluation
top3 = R2(1:min(3,height(R2)), :);
writetable(top3, fullfile(cfg0.res_dir, "gridsearch_dev_top3.csv"));
