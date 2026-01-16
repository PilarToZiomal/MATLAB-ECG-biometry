function results = train_eval(X, y, groups, cfg)
%TRAIN_EVAL Group-wise cross-validation (leave-one-group-out) evaluation.
% Inputs:
%   X      - feature matrix [N x D]
%   y      - labels [N x 1] (categorical)
%   groups - group ID per sample; all samples in a group are tested together
%   cfg    - config struct (model + hyperparameters + plotting flag)
% Output:
%   results - metrics struct from compute_metrics()

rng(cfg.seed);
folds = cv_split_groups(groups);

y_all  = categorical();
yp_all = categorical();

y_g_all  = categorical();
yp_g_all = categorical();

for i = 1:numel(folds)
    tr = folds{i}.trainIdx;
    te = folds{i}.testIdx;

    Xtr = X(tr,:); ytr = y(tr);
    Xte = X(te,:); yte = y(te);

    % Learn imputation/normalization on training only (prevents leakage)
    [Xtr, imp] = impute_nans(Xtr, []);
    [Xte, ~]   = impute_nans(Xte, imp);

    [Xtrz, zs] = safe_zscore(Xtr, []);
    [Xtez, ~]  = safe_zscore(Xte, zs);

    switch lower(cfg.model)
        case "svm"
            if ~license("test","Statistics_Toolbox")
                error("SVM requires Statistics and Machine Learning Toolbox.");
            end
            if ~isfield(cfg,"svm_C"); cfg.svm_C = 1; end
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

    y_all  = [y_all;  yte];   %#ok<AGROW>
    yp_all = [yp_all; ypred]; %#ok<AGROW>

    y_g_all  = [y_g_all;  majority_vote(yte)];   %#ok<AGROW>
    yp_g_all = [yp_g_all; majority_vote(ypred)]; %#ok<AGROW>
end

Mw = compute_metrics(y_all, yp_all);
Mg = compute_metrics(y_g_all, yp_g_all);

results = Mw;
results.accuracy_group  = Mg.accuracy;
results.F1_macro_group  = Mg.F1_macro;
results.CM_group        = Mg.CM;
results.order_group     = Mg.order;

if isfield(cfg,'plot_confusion') && cfg.plot_confusion
    figure;
    cc = confusionchart(results.CM, string(results.order));
    cc.Title = sprintf('Confusion (window-level: %s, %s)', upper(cfg.model), upper(cfg.cv_mode));
    style_confusionchart(cc);

    figure;
    cc = confusionchart(results.CM_group, string(results.order_group));
    cc.Title = sprintf('Confusion (group vote: %s, %s)', upper(cfg.model), upper(cfg.cv_mode));
    style_confusionchart(cc);
end

end

function yhat = majority_vote(y)
y = categorical(y);
cats = categories(y);
cnt = countcats(y);
[~,i] = max(cnt);
yhat = categorical(cats(i), cats);
end
