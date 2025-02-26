% Trigger information can be found in:
% "Box\CoganLab\ECoG_Task_Data\Timestamps (MASTER).xlsx"
% DC1: 257
addpath(genpath('D:\bsliang_Coganlabcode\response_coding\retrocue\make_Trials_mat'));

%% 

% first create a subject folder, e.g. D29/lexical_dr_2x_within_nodelay/part1/ and place task .edf file there
% create a subject case below and fill in variables
clear;
subj_task = 'D123_012';
trigger_chan_index = [];
mic_chan_index = [];

%TASKS	
% 012   Retro Cue

switch subj_task

    case 'D117_012' % Retro Cue
        cd '.\data'
        taskstim = 'Retro_Cue';
        subj = 'D117';
        edf_filename = 'D117 241208 COGAN_RETROCUE.EDF'; %needed
        ptb_trialInfo = 'D117_Block_1_TrialData.mat';
        taskdate = '241208'; 
        ieeg_prefix = [subj, '_', taskstim, '_']; % (auto-fills)
        rec = '001'; %session number
        %%%%%%%%
        trigger_chan_index = 257; % DC1
        mic_chan_index = 258; % DC1+1

    case 'D120_012' % Retro Cue
        taskstim = 'Retro_Cue';
        subj = 'D120';
        edf_filename = 'D120 250114 COGAN_RETROCUE.EDF'; %needed
        ptb_trialInfo = 'D120_Block_1_TrialData.mat';
        taskdate = '241208'; 
        ieeg_prefix = [subj, '_', taskstim, '_']; % (auto-fills)
        rec = '001'; %session number
        %%%%%%%%
        trigger_chan_index = 257; % DC1
        mic_chan_index = 258; % DC1+1

    case 'D121_012' % Retro Cue
        taskstim = 'Retro_Cue';
        subj = 'D121';
        edf_filename = 'D121 250126 COGAN_RETROCUE.EDF'; %needed
        ptb_trialInfo = 'D121_Block_1_TrialData.mat';
        taskdate = '250126'; 
        ieeg_prefix = [subj, '_', taskstim, '_']; % (auto-fills)
        rec = '001'; %session number
        %%%%%%%%
        trigger_chan_index = 258; % DC2
        mic_chan_index = 259; % DC2+1

    case 'D123_012' % Retro Cue
        taskstim = 'Retro_Cue';
        subj = 'D123';
        edf_filename = 'D123 250214 COGAN_RETROCUE.EDF'; %needed
        ptb_trialInfo = 'D123_Block_1_TrialData.mat';
        taskdate = '250214'; 
        ieeg_prefix = [subj, '_', taskstim, '_']; % (auto-fills)
        rec = '001'; %session number
        %%%%%%%%
        trigger_chan_index = 257; % DC1
        mic_chan_index = 258; % DC1+1
     
end

% Direct to the patient path
homeDir = getenv('USERPROFILE');
D_data_path = fullfile(homeDir,'Box', 'CoganLab', 'D_Data', 'Retro_Cue');
out_path = fullfile(homeDir,'Box', 'CoganLab', 'D_Data', 'Retro_Cue',subj);
if ~exist(out_path, 'dir')
    mkdir(out_path);
end
copyfile('maketrigtimes.m', out_path);
cd(out_path)

% Copy and load the TrialInfo.mat
ptb_trialInfo_path = fullfile(homeDir,'Box', 'CoganLab', 'ECoG_Task_Data', 'Cogan_Task_Data', subj, 'Retro Cue', 'All Blocks');
load(fullfile(ptb_trialInfo_path,ptb_trialInfo));
trialInfoAll = []; 
trialInfoAll = [trialInfoAll trialInfo];
trialInfo = trialInfoAll;
save('trialInfo', 'trialInfo');

% for first subject task, determine neural_chan_index, trigger_chan_index, and mic_chan_index
% once these are determined for a subject, they are the same across tasks
D_data_path_EDF = fullfile(D_data_path,'EDFs');
h = edfread_fast(fullfile(D_data_path_EDF,edf_filename));
labels = h.label;
% examine labels variable and determine the indices of neural channels
% (Exclude ones that start with C, EKG, Event, TRIG, OSAT, PR, Pleth, etc.
    % DO NOT INCLUDE EEG CHANNELS! - write EEG down in separate text file note copied to all task folders for same subject
% fill in the above case information for neural_chan()
    % see case D29_002_1 for an example on how to skip channels

% extract trigger channel and mic channel from edf and save as trigger.mat and mic.mat
if strcmp(h.label(end),'EDFAnnotations')
[~,d] = edfread_fast(fullfile(D_data_path_EDF,edf_filename),1:length(h.label)-1);
else
    [~,d] = edfread_fast(fullfile(D_data_path_EDF,edf_filename));
end
%[~,d] = edfread(edf_filename, 'machinefmt', 'ieee-le'); % use if you get a
%memory error for edfread_fast;
if ~isempty(trigger_chan_index)
    trigger = d(trigger_chan_index,:);
    save('trigger', 'trigger');
    %save('trigger2', 'trigger');
    %if there are multiple files, also save as trigger1, trigger2, etc.

end

if ~isempty(trigger_chan_index)
    mic = d(mic_chan_index,:);
    save('mic', 'mic');
    %save('mic2', 'mic');
    %if there are multiple files, also save as mic1, mic2, etc.

end


%%
% Determine the ieeg channels by visual inspection (exclude the eeg channels, blank channels, and others)
% Use **labels**
switch subj_task
    case 'D117_012' % Retro Cue
        neural_chan_index = [1:60, 65:122, 129:233];
    case 'D120_012' % Retro Cue
        neural_chan_index = [1:55, 65:126, 129:219];
    case 'D121_012' % Retro Cue
        neural_chan_index = [1:53, 65:127, 129:226];
    case 'D123_012' % Retro Cue
        neural_chan_index = [1:60, 65:121, 129:185, 193:219];
end
% make *.ieeg.dat file
filename=[ieeg_prefix taskdate '.ieeg.dat'];
fid=fopen(filename,'w');
fwrite(fid,d(neural_chan_index,:),'float');
fclose(fid);
write_experiment_file;

% move .ieeg.dat into [taskdate]/[rec]/
source_files = dir('*.ieeg.dat');
destination_folder = fullfile(taskdate, rec);
if ~exist(destination_folder, 'dir')
    mkdir(destination_folder);
end
for i = 1:length(source_files)
    source_file = source_files(i).name;
    destination_file = fullfile(destination_folder, source_file);
    movefile(source_file, destination_file);
end

% move experiment.mat into mat
source_mat = 'experiment.mat';
destination_mat_folder = 'mat';
if ~exist(destination_mat_folder, 'dir')
    mkdir(destination_mat_folder);
end
destination_mat_file = fullfile(destination_mat_folder, source_mat);
if exist(source_mat, 'file')
    movefile(source_mat, destination_mat_file);
end

% Edit / run maketrigtimes.m to generate trigTimes.mat
% see trigger_walker.m if you have a noisy trigger channel and need to
% estimate / interpolate / extrapolate an auditory Onset
open('maketrigtimes.m')

%% create a generic Trials.mat (for Retro Cue)

load trialInfo.mat;
load trigTimes.mat;

if iscell(trialInfo)
    trialInfo = cell2mat(trialInfo);
end

h = edfread_fast(fullfile(D_data_path_EDF,edf_filename));
Trials = struct();
Rec_onsets = [];
trigT_idx = 0;
for A=1:numel(trialInfo) % change to number of trials
    if A==1
        % block 1 starting: get the block 1 record onsets
        trigT_idx=trigT_idx+1;
        Rec_onsets=floor(trigTimes(trigT_idx) * 30000 / h.frequency(1));
    else
        block_current=trialInfo(A).block;
        block_last=trialInfo(A-1).block;
        if block_last~=block_current
            % block N starting: get the block N record onsets
            trigT_idx=trigT_idx+1;
            Rec_onsets=[Rec_onsets,...
                floor(trigTimes(trigT_idx) * 30000 / h.frequency(1))];
        end
    end

    % Info
    Trials(A).Subject=subj;
    Trials(A).Trial=A;
    Trials(A).Rec=rec;
    Trials(A).Day=taskdate;
    Trials(A).FilenamePrefix=[ieeg_prefix taskdate];

    % Get Auditory1 Start
    trigT_idx=trigT_idx+1;
    Trials(A).audio1Start = floor(trigTimes(trigT_idx) * 30000 / h.frequency(1));

    % Get Auditory2 Start
    trigT_idx=trigT_idx+1;
    Trials(A).audio2Start = floor(trigTimes(trigT_idx) * 30000 / h.frequency(1));

    % Test trigger times for Auditory 1 2 starts
    Aud_onset_diff_from_trialInfo = trialInfo(A).audio2Start - trialInfo(A).audio1Start;
    Aud_onset_diff_from_Trials = (Trials(A).audio2Start - Trials(A).audio1Start)/3e4;
    if abs(Aud_onset_diff_from_trialInfo-Aud_onset_diff_from_Trials)>=0.01
        % Report a misalignment if it is more than 10ms gap
        error('Auditory gap not matched with trialInfo')
    else
        disp(['Auditory gap matched with trialInfo with ', ...
            num2str((Aud_onset_diff_from_trialInfo-Aud_onset_diff_from_Trials)*1e3), ' gap in ms']);
    end

    % Get Retrocue Start
    trigT_idx=trigT_idx+1;
    Trials(A).RetroStart = floor(trigTimes(trigT_idx) * 30000 / h.frequency(1));

    if ~strcmp(trialInfo(A).cue,'0')

        % If not a DROP BOTH trial, get Go Start
        trigT_idx=trigT_idx+1;
        Trials(A).GoStart = floor(trigTimes(trigT_idx) * 30000 / h.frequency(1));
    else
        Trials(A).GoStart=Trials(A).RetroStart;
    end

end

save('Trials.mat', 'Trials');
%save('Rec_onsets.mat','Rec_onsets');
%if there are multiple files, also save as Trials1, Trials2, etc.

% Move Trials.mat and TrialInfo.mat
destination_folder = fullfile(taskdate, 'mat');
source_files_Trialsmat = 'Trials.mat';
destination_file_Trialsmat = fullfile(destination_folder, source_files_Trialsmat);
movefile(source_files_Trialsmat, destination_file_Trialsmat);
source_files_trialInfo = 'trialInfo.mat';
destination_file_trialInfo = fullfile(destination_folder, source_files_trialInfo);
movefile(source_files_trialInfo, destination_file_trialInfo);