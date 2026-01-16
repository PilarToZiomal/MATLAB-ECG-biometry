function rec = load_record(filepath, fs)
%LOAD_RECORD Load one recording file with a text header and numeric data block.
% The loader extracts numeric lines with 4 columns: [time, ch1, ch2, ch3].
% Inputs:
%   filepath - full path to the .txt file
%   fs       - sampling rate [Hz]; if empty, estimated from the time column
% Output:
%   rec      - struct with fields: x (Nx3), t (Nx1), fs, meta

if nargin < 2
    fs = [];
end

txt = fileread(filepath);
lines = splitlines(string(txt));

nums = [];  % numeric block: [time, ch1, ch2, ch3]
for i = 1:numel(lines)
    s = strtrim(lines(i));
    if s == "" || startsWith(s, "#")
        continue;
    end

    v = sscanf(s, '%f%f%f%f');
    if numel(v) == 4
        nums(end+1, :) = v(:)'; %#ok<AGROW>
    end
end

if isempty(nums)
    error("No numeric data detected in file: %s", filepath);
end

t = nums(:,1);
x = nums(:,2:4);

x = make_finite(x);

if isempty(fs) || ~isfinite(fs) || fs <= 0
    dt = diff(t);
    dt = dt(isfinite(dt) & dt > 0);
    if isempty(dt)
        fs = 100;
    else
        fs = 1 / median(dt);
    end
end

% If the time column is not reliable, rebuild it from fs
if any(~isfinite(t)) || numel(t) ~= size(x,1) || any(diff(t) <= 0)
    N = size(x,1);
    t = (0:N-1)'/fs;
end

[~, fname, ext] = fileparts(filepath);
m = parse_filename(fname + ext);
m.filepath = string(filepath);

rec = struct();
rec.x = x;
rec.t = t;
rec.fs = fs;
rec.meta = m;
end

function X = make_finite(X)
%MAKE_FINITE Replace NaN/Inf by per-channel linear interpolation (nearest at edges).

for c = 1:size(X,2)
    xc = X(:,c);
    bad = ~isfinite(xc);
    if any(bad)
        xc(bad) = NaN;
        xc = fillmissing(xc, "linear", "EndValues", "nearest");
        if any(~isfinite(xc))
            xc(~isfinite(xc)) = 0;
        end
        X(:,c) = xc;
    end
end
end
