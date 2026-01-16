function folds = cv_split_groups(groups)
%CV_SPLIT_GROUPS Create leave-one-group-out folds from a grouping variable.
% Input:
%   groups - grouping ID per sample (string/categorical/char vector); all samples
%            with the same group are kept together in the test fold
% Output:
%   folds  - cell array of structs with fields: trainIdx, testIdx, group

ug = unique(groups);
folds = cell(numel(ug), 1);

for i = 1:numel(ug)
    testIdx  = (groups == ug(i));
    trainIdx = ~testIdx;
    folds{i} = struct("trainIdx", trainIdx, "testIdx", testIdx, "group", ug(i));
end
end
