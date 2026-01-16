function f = compute_psd_features(x, fs, welch_win, welch_ov, nfft, bp_band)
%COMPUTE_PSD_FEATURES Compute basic spectral features from Welch PSD.
% Inputs:
%   x         - signal vector [N x 1]
%   fs        - sampling rate [Hz]
%   welch_win - Welch window vector (e.g., hann(round(sec*fs)))
%   welch_ov  - overlap in samples (integer)
%   nfft      - FFT length for PSD
%   bp_band   - [f1 f2] band (Hz) for bandpower feature
% Output:
%   f         - struct with fields: domfreq, centroid, bandwidth, bandpower

[P,F] = pwelch(x, welch_win, welch_ov, nfft, fs);

[~,i] = max(P);
dom = F(i);

cent = sum(F .* P) / sum(P);
bw = sqrt(sum(((F - cent).^2) .* P) / sum(P));

bp = bandpower(P, F, bp_band, "psd");

f = struct();
f.domfreq = dom;
f.centroid = cent;
f.bandwidth = bw;
f.bandpower = bp;
end
