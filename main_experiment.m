function main_experiment()
%MAIN_EXPERIMENT Train/evaluate on the full dataset using current config.
cfg = config();
rng(cfg.seed);

if ~exist(cfg.out_dir, "dir"); mkdir(cfg.out_dir); end
if ~exist(cfg.fig_dir, "dir"); mkdir(cfg.fig_dir); end
if ~exist(cfg.res_dir, "dir"); mkdir(cfg.res_dir); end

addpath(genpath("src"));

% Discover dataset files and labels.
T = list_data_files(cfg.data_dir);

% Quick sanity-check: file list and per-subject file counts
disp(head(T, 10));
disp(groupsummary(T, "subject_id"));

fprintf("Found %d files.\n", height(T));

% Build window-level features/labels and grouping variables.
[X, y, groups_file, groups_subject, metaWin] = build_dataset(T, cfg);

fprintf("Dataset: %d windows, %d features, %d classes\n", ...
    size(X,1), size(X,2), numel(categories(y)));

% Select grouping variable to avoid leakage:
% LOFO -> all windows from the same file stay in the same fold
% LOSO -> all windows from the same subject stay in the same fold
switch upper(cfg.cv_mode)
    case "LOFO"
        groups = groups_file;
    case "LOSO"
        groups = groups_subject;
    otherwise
        error("Unknown cv_mode");
end

% Cross-validated training/evaluation.
results = train_eval(X, y, groups, cfg);

% Persist results and metadata for reporting.
save(fullfile(cfg.res_dir, "results.mat"), "results", "cfg", "metaWin");

fprintf("Accuracy: %.4f | Macro-F1: %.4f\n", results.accuracy, results.F1_macro);
end
