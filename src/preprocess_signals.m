function xp = preprocess_signals(x, fs, cfg)
%PREPROCESS_SIGNALS Detrend and bandpass-filter each channel (resp/pulse/ECG).
% Inputs:
%   x   - raw signals [N x 3] (columns: respiration, pulse, ECG)
%   fs  - sampling rate [Hz]
%   cfg - config struct with band definitions and filter order
% Output:
%   xp  - preprocessed signals [N x 3]

xp = zeros(size(x));

for ch = 1:3
    xp(:,ch) = detrend(x(:,ch), "linear");  % remove baseline drift/trend before filtering
end

xp(:,1) = bandpass_filt(xp(:,1), fs, cfg.resp_band,  cfg.filt_order);
xp(:,2) = bandpass_filt(xp(:,2), fs, cfg.pulse_band, cfg.filt_order);
xp(:,3) = bandpass_filt(xp(:,3), fs, cfg.ecg_band,   cfg.filt_order);
end
