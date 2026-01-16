function qrs = detect_qrs_pantompkins(ecg, fs, cfg)
%DETECT_QRS_PANTOMPKINS Pan-Tompkins-like QRS detector with simple tuning.

ecg = ecg(:);

% Bandpass for QRS energy and compute squared derivative.
y = bandpass_filt(ecg, fs, cfg.qrs_band, cfg.qrs_filt_order);
d = [0; diff(y)];
s = d.^2;

% Moving-window integration to smooth peak energy.
mwi_len = max(1, round(cfg.qrs_mwi_ms/1000 * fs));
mwi = movmean(s, mwi_len);

minDist = max(1, round(cfg.qrs_min_rr_s * fs));

ignoreN = 0;
if isfield(cfg, "qrs_ignore_s") && isfinite(cfg.qrs_ignore_s) && cfg.qrs_ignore_s > 0
    ignoreN = min(numel(mwi)-1, round(cfg.qrs_ignore_s * fs));
end

idx = (ignoreN+1):numel(mwi);
m = mwi(idx);
thr = median(m) + cfg.qrs_thr_k * mad(m,1);

[~, locs] = findpeaks(mwi, "MinPeakDistance", minDist, "MinPeakHeight", thr);
locs = locs(locs > ignoreN);

searchN = max(1, round(cfg.qrs_refine_ms/1000 * fs));
r_locs = zeros(size(locs));

for i = 1:numel(locs)
    c = locs(i);
    a = max(1, c-searchN);
    b = min(numel(y), c+searchN);
    [~,im] = max(y(a:b));
    r_locs(i) = a + im - 1;
end

r_locs = unique(r_locs(:));
r_locs = sort(r_locs);

if numel(r_locs) >= 2
    keep = [true; diff(r_locs) >= minDist];
    r_locs = r_locs(keep);
end

qrs = struct();
qrs.r_locs  = r_locs;
qrs.r_times = r_locs / fs;

if numel(r_locs) >= 2
    qrs.RR = diff(r_locs)/fs;
else
    qrs.RR = [];
end
end
