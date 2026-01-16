function meta = parse_filename(fname)
%PARSE_FILENAME Extract file identifiers from a dataset filename.
[~, name, ~] = fileparts(string(fname));
parts = split(name, "_");

meta = struct();
meta.filename = string(fname);

% Keep the prefix for optional debugging (subject label comes from folder name in pipeline)
meta.prefix = parts(1);

% Use the last token as trial/run identifier (works for variable-length name patterns)
meta.trial_id = parts(end);

% Unique file identifier (filename without extension)
meta.file_id = name;

% Optional descriptor between prefix and trial_id (e.g., "F_03" or "N_NB")
if numel(parts) > 2
    meta.desc = strjoin(parts(2:end-1), "_");
else
    meta.desc = "";
end
end
