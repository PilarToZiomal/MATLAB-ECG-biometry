function results = train_eval_holdout(Xtr, ytr, Xte, yte, cfg)
%TRAIN_EVAL_HOLDOUT Train once on (Xtr,ytr) and evaluate once on (Xte,yte).
% Inputs:
%   Xtr, ytr - training features/labels
%   Xte, yte - test features/labels
%   cfg      - config struct (model + hyperparameters + plotting flag)
% Output:
%   results  - metrics struct from compute_metrics()

rng(cfg.seed);
% Apply imputation/normalization learned only from the training split
[Xtr, imp] = impute_nans(Xtr, []);
[Xte, ~]   = impute_nans(Xte, imp);

[Xtrz, zs] = safe_zscore(Xtr, []);
[Xtez, ~]  = safe_zscore(Xte, zs);

switch lower(cfg.model)
    case "svm"
        if ~license("test","Statistics_Toolbox")
            error("SVM requires Statistics and Machine Learning Toolbox.");
        end
        t = templateSVM('KernelFunction', cfg.svm_kernel, ...
                        'KernelScale', 'auto', ...
                        'BoxConstraint', cfg.svm_C);
        mdl = fitcecoc(Xtrz, ytr, 'Learners', t, 'Coding', 'onevsall');

    case "knn"
        if ~license("test","Statistics_Toolbox")
            error("kNN requires Statistics and Machine Learning Toolbox.");
        end
        mdl = fitcknn(Xtrz, ytr, "NumNeighbors", cfg.knn_k, "Standardize", false);

    otherwise
        error("Unknown model: %s", cfg.model);
end

ypred = predict(mdl, Xtez);
results = compute_metrics(yte, ypred);

if isfield(cfg,'plot_confusion') && cfg.plot_confusion
    figure;
    cc = confusionchart(results.CM, string(results.order));
    cc.Title = "Final test confusion";
    style_confusionchart(cc);
end
end
