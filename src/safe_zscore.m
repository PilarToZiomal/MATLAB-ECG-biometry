function [Xz, stats] = safe_zscore(X, stats)
%SAFE_ZSCORE Z-score normalization with parameters learned on training data.
% Inputs:
%   X     - feature matrix
%   stats - struct with fields mu, sig; if empty, computed from X
% Outputs:
%   Xz    - normalized features
%   stats - normalization parameters (reuse on test data)

if nargin < 2 || isempty(stats)
    stats.mu  = mean(X, 1, "omitnan");
    stats.sig = std(X, 0, 1, "omitnan");
    stats.sig(stats.sig == 0) = 1;
end

Xz = (X - stats.mu) ./ stats.sig;
end
