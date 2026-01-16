%EVAL_FINAL_TEST Evaluate top DEV configs on the held-out TEST split.
cfg0 = config();
cfg0.plot_confusion = true;
rng(cfg0.seed);

addpath(genpath("src"));

% Load DEV grid-search results and the corresponding DEV/TEST file split
load(fullfile(cfg0.res_dir, "gridsearch_dev.mat"), "Rdev", "Tdev", "Ttest");

% Select top-N configurations based on DEV Macro-F1
R2 = sortrows(Rdev, "F1_macro", "descend");
top = R2(1:min(3,height(R2)), :);

% One-shot train on DEV, test on held-out TEST for each top config.
for i = 1:height(top)
    cfg = cfg0;

    cfg.win_sec  = top.win_sec(i);
    cfg.overlap  = top.overlap(i);
    cfg.win_type = string(top.win_type(i));

    % Bands were stored as strings (e.g., "[0.1 0.7]") in the results table
    cfg.resp_band  = str2num(top.resp_band{i});  %#ok<ST2NM>
    cfg.pulse_band = str2num(top.pulse_band{i}); %#ok<ST2NM>
    cfg.ecg_band   = str2num(top.ecg_band{i});   %#ok<ST2NM>

    cfg.model      = "svm";
    cfg.svm_kernel = string(top.svm_kernel(i));
    cfg.svm_C      = top.svm_C(i);

    % Build features separately for DEV and TEST to avoid any leakage
    [Xdev, ydev] = build_dataset(Tdev, cfg);
    [Xte,  yte ] = build_dataset(Ttest, cfg);

    % Train on DEV once, evaluate once on the held-out TEST split
    res = train_eval_holdout(Xdev, ydev, Xte, yte, cfg);

    fprintf("\nFINAL TEST #%d | win=%d ov=%.2f %s | ker=%s C=%.2g\n", ...
        i, cfg.win_sec, cfg.overlap, cfg.win_type, cfg.svm_kernel, cfg.svm_C);
    fprintf("Accuracy=%.4f | Macro-F1=%.4f\n", res.accuracy, res.F1_macro);
end
