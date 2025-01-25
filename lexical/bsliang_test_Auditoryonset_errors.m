% Test the errors of auditory onsets.

% Unsystematic lags were found in early patients
% (<50 for lexical delay, and < 60 for lexical no delay)
% between the sound onsets read from Trials.mat
% (and trialInfo.mat as well) and the sound onsets 
% recorded by microphone, after temporal alignment 
% (i.e., aligning the edf time and the computer time
% for the first stimuli of each block).  
% The lags tended to gradually be bigger 
% as time grows within a block.

%% Load Trialinfo and Trials.mat
% load block_wav_onsets.mat
clear all

% task_type='LexicalDecRepDelay\';
task_type='LexicalDecRepNoDelay\';
box_local='C:\Users\bl314\Box\';
subj='D53';
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
trialInfo=cell2mat(trialInfo);
%% load cue_events.txt after manual adjust
file_path = fullfile(subj_path, 'cue_events.txt');
cue_events = scantext(file_path, '\t', 0, '%f %f %s');

%% Read the auditory onsets from Trials.mat, trialInfo.mat, and cue_events.txt
[Trials_audonsets,trialInfo_audonsets,cue_events_audonsets]=deal(nan(1,numel(Trials)));
b=0;
for t=1:numel(Trials)
    if trialInfo(t).block ~= b
        b = b + 1;
        edf_first_stim_on=Trials(t).Auditory/3e4;
        trialInfo_stim_on=trialInfo(t).stimulusAudioStart;
        cue_events_stim_on=cue_events{1}(t);
    end
    Trials_audonsets(t)=Trials(t).Auditory/3e4-edf_first_stim_on;
    trialInfo_audonsets(t)=trialInfo(t).stimulusAudioStart-trialInfo_stim_on;
    cue_events_audonsets(t)=cue_events{1}(t)-cue_events_stim_on;
end

%% plot the auditory onsets.
% plot the original values
figure;
plot(1:numel(Trials),cue_events_audonsets,'ro')
hold on
plot(1:numel(Trials),Trials_audonsets,'go')
plot(1:numel(Trials),trialInfo_audonsets,'bo')
xlabel('trial no');
ylabel('time/s')
legend({'Auditory onsets manually adjusted', 'Auditory onsets from Trials.mat','Auditory onsets from trialInfo.mat'})

%% Do contrast to see which has a shrinking trial length
Trials_audonsets_contrast=Trials_audonsets(2:end)-Trials_audonsets(1:end-1);
trialInfo_audonsets_contrast=trialInfo_audonsets(2:end)-trialInfo_audonsets(1:end-1);
cue_events_audonsets_contrast=cue_events_audonsets(2:end)-cue_events_audonsets(1:end-1);
Trials_audonsets_contrast(Trials_audonsets_contrast<0)=[];
trialInfo_audonsets_contrast(trialInfo_audonsets_contrast<0)=[];
cue_events_audonsets_contrast(cue_events_audonsets_contrast<0)=[];
%% plot the trial length
figure;
plot(1:numel(Trials)-b,cue_events_audonsets_contrast,'ro')
hold on
plot(1:numel(Trials)-b,Trials_audonsets_contrast,'go')
plot(1:numel(Trials)-b,trialInfo_audonsets_contrast,'bo')
xlabel('trial no');
ylabel('time/s')
legend({'Auditory onsets manually adjusted', 'Auditory onsets from Trials.mat','Auditory onsets from trialInfo.mat'})
