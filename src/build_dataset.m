function [X, y, groups_file, groups_subject, metaWin] = build_dataset(T, cfg)
%BUILD_DATASET Build a window-level feature dataset from multiple recordings.
%
% Inputs:
%   T   - table returned by list_data_files(), must contain:
%         T.filepaths (full path to each .txt) and T.subject_id (class label)
%   cfg - configuration struct (sampling rate, filter bands, windowing, Welch, etc.)
%
% Outputs:
%   X             - feature matrix [Nwindows x Nfeatures]
%   y             - categorical label vector [Nwindows x 1]
%   groups_file   - grouping ID per window (file-level ID) for LOFO splitting
%   groups_subject- grouping ID per window (subject/person ID) for LOSO splitting
%   metaWin       - table with metadata for each window (source file, indices)

% Initialize outputs
X = [];
y = categorical();
groups_file = strings(0,1);
groups_subject = strings(0,1);
metaWin = table();

% Precompute Welch window/overlap once
welch_win = hann(round(cfg.welch_sec * cfg.fs));
welch_ov  = round(cfg.welch_ov * numel(welch_win));

% Loop over all files
for i = 1:height(T)
    rec = load_record(T.filepaths(i), cfg.fs);

    xp = preprocess_signals(rec.x, cfg.fs, cfg);

    [W, wmeta] = segment_windows(xp, cfg.fs, cfg.win_sec, cfg.overlap);

    qrs = detect_qrs_pantompkins(xp(:,3), cfg.fs, cfg);

    for k = 1:numel(W)
        w = W{k};

        s = wmeta.start_idx(k);
        e = wmeta.end_idx(k);
        rr_info = rr_in_window(qrs, cfg.fs, s, e);

        feat_cfg = cfg;
        feat_cfg.welch_win  = welch_win;
        feat_cfg.welch_ov   = welch_ov;
        feat_cfg.welch_nfft = cfg.welch_nfft;

        feat = extract_features(w, cfg.fs, feat_cfg, rr_info);

        X = [X; feat]; %#ok<AGROW>
        y = [y; categorical(string(T.subject_id(i)))]; %#ok<AGROW>

        groups_file(end+1,1) = string(rec.meta.file_id); %#ok<AGROW>
        groups_subject(end+1,1) = string(T.subject_id(i)); %#ok<AGROW>

        metaWin = [metaWin; table(string(rec.meta.filename), string(rec.meta.file_id), string(T.subject_id(i)), k, s, e)]; %#ok<AGROW>
    end
end

% Set column names for metadata table
metaWin.Properties.VariableNames = ["filename","file_id","subject_id","win_idx","start_idx","end_idx"];
end


function rr_info = rr_in_window(qrs, fs, s, e)
%RR_IN_WINDOW Collect RR intervals (seconds) whose R-peaks fall within a window.
%
% Inputs:
%   qrs - struct returned by detect_qrs_pantompkins(), containing qrs.r_locs
%   fs  - sampling rate [Hz]
%   s,e - window start/end indices (samples)
%
% Output:
%   rr_info.RR - RR intervals in seconds (empty if insufficient R-peaks)

rr_info = struct();
rr_info.RR = [];

% Require at least two detected R-peaks to compute at least one RR interval
if isempty(qrs) || ~isfield(qrs,'r_locs') || numel(qrs.r_locs) < 2
    return;
end

% R-peak sample locations for the whole file
r = qrs.r_locs(:);

% Keep only R-peaks that lie inside this window
mask = (r >= s) & (r <= e);
rwin = r(mask);

% Convert to RR intervals (seconds) if we have >=2 peaks in the window
if numel(rwin) >= 2
    rr_info.RR = diff(rwin) / fs;
end
end
