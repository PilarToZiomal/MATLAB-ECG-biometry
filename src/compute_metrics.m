function M = compute_metrics(ytrue, ypred, order)
%COMPUTE_METRICS Compute confusion matrix and standard classification metrics.
% Inputs:
%   ytrue - true labels (categorical or string/cellstr convertible)
%   ypred - predicted labels (same type/space as ytrue)
%   order - optional class order for confusion matrix
% Output:
%   M     - struct with fields: CM, order, accuracy, F1_macro, precision, recall, F1_per_class

if nargin < 3 || isempty(order)
    if iscategorical(ytrue) || iscategorical(ypred)
        ytrue = categorical(ytrue);
        ypred = categorical(ypred);
        order = categories(ytrue);
        missing = setdiff(categories(ypred), order, "stable");
        order = [order; missing];
    else
        order = unique([ytrue; ypred], "stable");
    end
end

[CM, order] = confusionmat(ytrue, ypred, "Order", order);

acc = sum(diag(CM)) / sum(CM(:));

prec = diag(CM) ./ max(sum(CM,1)', 1);
rec  = diag(CM) ./ max(sum(CM,2), 1);
F1c  = 2*(prec .* rec) ./ max(prec + rec, eps);

M = struct();
M.CM = CM;
M.order = order;
M.accuracy = acc;
M.F1_macro = mean(F1c, "omitnan");  % macro-average over classes
M.precision = prec;
M.recall = rec;
M.F1_per_class = F1c;
end
