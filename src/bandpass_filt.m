function y = bandpass_filt(x, fs, band, ord)
%BANDPASS_FILT Zero-phase Butterworth bandpass filtering with SOS for stability.
% Inputs:
%   x    - signal vector [N x 1]
%   fs   - sampling rate [Hz]
%   band - [f1 f2] passband in Hz
%   ord  - filter order (Butterworth)
% Output:
%   y    - filtered signal [N x 1]

f1 = band(1);
f2 = band(2);

if f1 <= 0; f1 = 0.001; end
if f2 >= fs/2; f2 = fs/2 - 0.001; end
if f2 <= f1
    error("Invalid band: [%g %g]", band(1), band(2));
end

Wn = [f1 f2] / (fs/2);

[b,a] = butter(ord, Wn, "bandpass");

% Zero-phase filtering (no group delay)
% Use direct-form filtfilt to avoid rare SOS blow-ups on some MATLAB versions.
y = filtfilt(b, a, x);
end
