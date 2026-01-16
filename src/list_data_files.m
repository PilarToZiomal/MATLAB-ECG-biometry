function T = list_data_files(data_dir)
%LIST_DATA_FILES Recursively list dataset files and assign subject labels.
if nargin < 1 || strlength(data_dir)==0
    error("Provide data_dir");
end

% Recursive search
d = dir(fullfile(data_dir, "**", "*.txt"));
if isempty(d)
    error("No .txt files found in: %s", data_dir);
end

filepaths = strings(numel(d),1);
filenames = strings(numel(d),1);
subject_id = strings(numel(d),1);
trial_id   = strings(numel(d),1);
folder_subject = strings(numel(d),1);

for i = 1:numel(d)
    filepaths(i) = string(fullfile(d(i).folder, d(i).name));
    filenames(i) = string(d(i).name);

    % Use the parent folder name as the subject label (e.g., Data/AS/file.txt -> "AS")
    [~, parentFolder] = fileparts(d(i).folder);
    folder_subject(i) = string(parentFolder);
    subject_id(i) = folder_subject(i);

    % Parse file name only to extract trial_id (last token), not the subject label
    meta = parse_filename(d(i).name);
    trial_id(i) = meta.trial_id;
end

T = table(filepaths, filenames, subject_id, trial_id, folder_subject);
end
