function feat = extract_features(win, fs, cfg, rr_info)
%EXTRACT_FEATURES Extract time-domain, spectral, and HRV features from a 3-channel window.
% Inputs:
%   win     - [N x 3] windowed segment: columns = [respiration, pulse, ECG]
%   fs      - sampling rate [Hz]
%   cfg     - config struct (Welch + band definitions + HRV guard)
%   rr_info - struct with rr_info.RR (seconds) for RR intervals inside this window (optional)
% Output:
%   feat    - 1 x F feature row (fixed ordering)

resp  = win(:,1);
pulse = win(:,2);
ecg   = win(:,3);

% Minimal time-domain set (stable and cheap)

f_resp_td  = [rms(resp),  var(resp),  peak2peak(resp),  kurtosis(resp)];
f_pulse_td = [rms(pulse), var(pulse), peak2peak(pulse), kurtosis(pulse)];
f_ecg_td   = [rms(ecg),   var(ecg),   kurtosis(ecg)];

win_w = apply_window(win, cfg.win_type);
respw  = win_w(:,1);
pulsew = win_w(:,2);
ecgw   = win_w(:,3);

fr = compute_psd_features(respw,  fs, cfg.welch_win, cfg.welch_ov, cfg.welch_nfft, cfg.resp_bp_band);
fp = compute_psd_features(pulsew, fs, cfg.welch_win, cfg.welch_ov, cfg.welch_nfft, cfg.pulse_bp_band);
fe = compute_psd_features(ecgw,   fs, cfg.welch_win, cfg.welch_ov, cfg.welch_nfft, cfg.ecg_qrs_band);


% Bandpower ratio helps separate "main pulse band" vs higher-frequency content
[Pp,Fp] = pwelch(pulsew, cfg.welch_win, cfg.welch_ov, cfg.welch_nfft, fs);
p_hi = bandpower(Pp, Fp, cfg.pulse_hi_band, "psd");
p_ratio = fp.bandpower / max(p_hi, eps);

f_resp_spec  = [fr.domfreq, fr.centroid, fr.bandwidth, fr.bandpower];
f_pulse_spec = [fp.domfreq, fp.centroid, fp.bandwidth, fp.bandpower, p_ratio];
f_ecg_spec   = [fe.bandpower, fe.centroid, fe.bandwidth];

f_hrv = [NaN NaN NaN NaN];
if nargin >= 4 && ~isempty(rr_info) && isfield(rr_info,'RR')
    h = compute_hrv_features(rr_info.RR, cfg.min_rr_count_for_hrv);
    f_hrv = [h.meanRR, h.SDNN, h.RMSSD, h.pNN50];
end

feat = [f_resp_td, f_resp_spec, f_pulse_td, f_pulse_spec, f_ecg_td, f_ecg_spec, f_hrv];
end
