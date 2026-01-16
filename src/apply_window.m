function wout = apply_window(win, win_type)
%APPLY_WINDOW Apply a 1D window (rect/hann/hamming) to a multi-channel segment.
% Inputs:
%   win      - [N x C] windowed segment (N samples, C channels)
%   win_type - "rect" | "hann" | "hamming"
% Output:
%   wout     - [N x C] segment after windowing

N = size(win,1);

switch lower(string(win_type))
    case "rect"
        w = ones(N,1);
    case "hann"
        w = hann(N);
    case "hamming"
        w = hamming(N);
    otherwise
        error("Unknown win_type: %s", win_type);
end

% Apply the same window to all channels (implicit expansion)
wout = win .* w;
end
