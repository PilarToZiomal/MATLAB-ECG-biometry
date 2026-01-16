function h = compute_hrv_features(RR, minCount)
%COMPUTE_HRV_FEATURES Compute basic time-domain HRV features from RR intervals.
% Inputs:
%   RR       - RR intervals in seconds (vector)
%   minCount - minimum number of RR intervals required to compute features
% Output:
%   h        - struct with fields: meanRR, SDNN, RMSSD, pNN50 (NaN if insufficient data)

if nargin < 2; minCount = 5; end

h = struct("meanRR",NaN,"SDNN",NaN,"RMSSD",NaN,"pNN50",NaN);

RR = RR(:);
if numel(RR) < minCount
    return;
end

dRR = diff(RR);

h.meanRR = mean(RR);
h.SDNN   = std(RR);
h.RMSSD  = sqrt(mean(dRR.^2));
h.pNN50  = 100 * mean(abs(dRR) > 0.05);  % 50 ms threshold
end
