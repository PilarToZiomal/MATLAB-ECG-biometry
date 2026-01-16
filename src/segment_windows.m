function [W, meta] = segment_windows(x, fs, win_sec, overlap)
%SEGMENT_WINDOWS Split a multi-channel signal into overlapping time windows.
% Inputs:
%   x       - signal [N x C]
%   fs      - sampling rate [Hz]
%   win_sec - window length [s]
%   overlap - fraction in [0,1) (e.g., 0.5)
% Outputs:
%   W       - cell array of windows, each [winN x C]
%   meta    - struct with sample indices and window parameters

winN = round(win_sec * fs);
hopN = max(1, round(winN * (1 - overlap)));

N = size(x,1);
starts = 1:hopN:(N - winN + 1);
K = numel(starts);

W = cell(K,1);
meta.start_idx = zeros(K,1);
meta.end_idx = zeros(K,1);

for k = 1:K
    s = starts(k);
    e = s + winN - 1;
    W{k} = x(s:e,:);
    meta.start_idx(k) = s;
    meta.end_idx(k) = e;
end

meta.winN = winN;
meta.hopN = hopN;
end
