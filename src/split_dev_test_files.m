function [Tdev, Ttest] = split_dev_test_files(T, test_ratio, seed)
% File-level stratified split by subject_id (prevents window/file leakage).

if nargin < 2 || isempty(test_ratio); test_ratio = 0.2; end
if nargin < 3 || isempty(seed); seed = 42; end

rng(seed);

subs = unique(T.subject_id);
isTest = false(height(T),1);

for s = 1:numel(subs)
    idx = find(T.subject_id == subs(s));
    n = numel(idx);

    % Ensure at least one test file per subject (important for small classes)
    ntest = max(1, round(test_ratio * n));

    p = idx(randperm(n, ntest));
    isTest(p) = true;
end

Ttest = T(isTest,:);
Tdev  = T(~isTest,:);

end
