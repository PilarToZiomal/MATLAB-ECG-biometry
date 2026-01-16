function [Ximp, imp] = impute_nans(X, imp)
%IMPUTE_NANS Replace NaNs using statistics computed on the training split.
% Inputs:
%   X   - feature matrix
%   imp - struct with field "val" (per-feature imputation values); if empty, it is learned from X
% Outputs:
%   Ximp - imputed feature matrix
%   imp  - imputation parameters (to reuse on test data)

if nargin < 2 || isempty(imp)
    imp.val = median(X, 1, "omitnan");
end

Ximp = X;
mask = isnan(Ximp);

if any(mask, "all")
    for j = 1:size(Ximp, 2)
        Ximp(mask(:,j), j) = imp.val(j);
    end
end
end
