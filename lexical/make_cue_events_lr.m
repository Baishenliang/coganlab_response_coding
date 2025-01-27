% load block_wav_onsets.mat
clear all

%task_type='LexicalDecRepDelay\';
task_type='LexicalDecRepNoDelay\';
box_local='C:\Users\bl314\Box\';
subj='D29';
subj_path=fullfile(box_local,'CoganLab\ECoG_Task_Data\response_coding\response_coding_results\',task_type,subj);
Trial_loc_root=fullfile(box_local,'CoganLab\D_Data\',task_type,subj);
load(fullfile(subj_path,'trialInfo.mat'));
trial_files = dir(fullfile(Trial_loc_root, '**', 'mat', 'Trials.mat'));
if numel(trial_files) > 1
    error([subj ' Found more than one Trial.mat']);
elseif isscalar(trial_files)
    disp([subj ' Trial.mat found at: ', fullfile(trial_files.folder, trial_files.name)]);
    Trial_loc=trial_files.folder;
else
    error([subject_Tag 'No Trial.mat file found.']);
end
load(fullfile(Trial_loc,"Trials.mat"));

% offset = 0.0234; % seconds
% is_picture_naming = 0;

if iscell(trialInfo)
    trialInfo = cellfun(@(a) a, trialInfo);
end

rc = scantext(fullfile(subj_path,'first_stims.txt'), '\t', 0, '%f %f %s');
first_stims_onset = rc{1};

file_path = fullfile(subj_path, 'cue_events_from_Trials.mat.txt');
if exist(file_path, 'file') == 2
    error('File "%s" already exists. Program terminated.', file_path);
end
fid2 = fopen(file_path, 'w');
if fid2 == -1
    error('Failed to open file for writing: %s', file_path);
end

b = 0;
edf_first_stim_on=0;
for t = 1:numel(Trials)

    if trialInfo(t).block ~= b
        b = b + 1;
        edf_first_stim_on=Trials(t).Auditory;
    end

    on = (Trials(t).Auditory-edf_first_stim_on)/3e4;
    on = first_stims_onset(b)+on;

    if isfield(trialInfo,'sound')
        stimstr = 'sound';
    elseif isfield(trialInfo,'stim')
        stimstr = 'stim';
    else
        error("trialInfo fieldnames do not include 'stim or 'sound' fields")
    end
    fwrite(fid2, sprintf('%f\t%f\t%d_%s\n', on, on+1, t, trialInfo(t).(stimstr)));


end