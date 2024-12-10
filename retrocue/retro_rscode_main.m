% First few steps for esponse coding for Retrocue task:
% Combining waves, and make the event_cues.txt (and other txt grids for
% further response coding
% Should be ready for mfa
clear all; clc;

%% define subject and path
subject = 117;
homeDir = getenv('USERPROFILE');
in_path = fullfile(homeDir,'Box', 'CoganLab', 'ECoG_Task_Data', 'Cogan_Task_Data', ['D', num2str(subject)], 'Retro Cue', 'All Blocks');
out_path = fullfile(homeDir,'Box', 'CoganLab', 'ECoG_Task_Data', 'response_coding', 'response_coding_results', 'Retrocue',['D', num2str(subject)]);
if ~exist(out_path, 'dir')
    mkdir(out_path);
    fprintf('Directory created: %s\n', out_path);
else
    fprintf('Directory already exists: %s\n', out_path);
end

%% copy and rename trialInfo.mat
begin_block=1;
copyfile(fullfile(in_path,sprintf('D%d_Block_%d_TrialData.mat', subject, begin_block)), fullfile(out_path,'trialInfo.mat'));

%% combine waves
% Original script: Box\CoganLab\ECoG_Task_Data\response_coding\response_coding_dep\combine_wavs.m
block_gap=10; % gap between blocks in second
big_wav = [];
for d = 1:10
    filename = fullfile(in_path,sprintf('D%d_Block_%d_AllTrials.wav', subject, d));
    %filename = sprintf('block%d.wav', d);
    if exist(filename, 'file')
        [aud,Fs] = audioread(filename);
        if d == 1
            lastFs = Fs;
        else
            assert(lastFs==Fs);
        end
        block_wav_onsets(d,1) = length(big_wav) + 1;
        block_wav_onsets(d,2) = Fs;
        big_wav = cat(1, big_wav, aud, zeros(block_gap*Fs,1));
    end
end

audiowrite(fullfile(out_path,'allblocks.wav'), big_wav, Fs);
save(fullfile(out_path,'block_wav_onsets'), 'block_wav_onsets');

%% create event text grids
data_tsv = readtable(fullfile(in_path,sprintf('D%d_Block_%d.csv', subject, begin_block)));
record_onsets_tsv=data_tsv(strcmp(data_tsv{:, 3}, 'Record_onset'), :) ;
record_onsets = record_onsets_tsv.onset;
data_tsv(strcmp(data_tsv{:, 3}, 'Record_onset'), :) = [];
load(fullfile(out_path,'trialInfo.mat'));

%% replace the onsets of the data_tsv by trialInfo.
% Dont have to do it in the true experiment data (as the Retrocue task scrips have been updated)
indices_sound1 = 1:8:height(data_tsv);
indices_sound2 = 2:8:height(data_tsv);
indices_retro = 4:8:height(data_tsv);
indices_go = 6:8:height(data_tsv);

f_stims = fopen(fullfile(out_path,'cue_events.txt'), 'w');
f_stims_mfa = fopen(fullfile(out_path,'cue_events_mfa.txt'), 'w');
f_cues = fopen(fullfile(out_path,'condition_events.txt'),'w');
f_gos = fopen(fullfile(out_path,'gos.txt'),'w');

% loop for all the trials
for k = 1:length(indices_sound1)

    trial_tmp=trialInfo{1,k};
    record_onset=record_onsets(trial_tmp.block);
    
    sound1_Tags=strsplit(data_tsv.trial_type{indices_sound1(k)},'/');
    sound1_Tag=sound1_Tags{end};

    sound2_Tags=strsplit(data_tsv.trial_type{indices_sound2(k)},'/');
    sound2_Tag=sound2_Tags{end};
    
    retro_Tags=strsplit(data_tsv.trial_type{indices_retro(k)},'/');
    retro_Tag=retro_Tags{end};
    
    audio1Start_trialInfo=trial_tmp.audio1Start-record_onset+block_wav_onsets(trial_tmp.block,1)/Fs;
    fprintf(f_stims, '%.17f\t%.17f\t%s\n', audio1Start_trialInfo, ...
        audio1Start_trialInfo+data_tsv.duration(indices_sound1(k)), ...
        sound1_Tag);
    
    audio2Start_trialInfo=trial_tmp.audio2Start-record_onset+block_wav_onsets(trial_tmp.block,1)/Fs;
    fprintf(f_stims, '%.17f\t%.17f\t%s\n', audio2Start_trialInfo, ...
        audio2Start_trialInfo+data_tsv.duration(indices_sound2(k)), ...
        sound2_Tag);
    
    retoStart=trial_tmp.del1End-record_onset+block_wav_onsets(trial_tmp.block,1)/Fs;
    fprintf(f_cues, '%.17f\t%.17f\t%s\n', retoStart, ...
        retoStart+data_tsv.duration(indices_retro(k)), ...
        retro_Tag);
    
    switch retro_Tag
        case 'REP_BTH'
            try
                mfa_Tag=strjoin([sound1_Tag, sound2_Tag],'');
            catch
                mfa_Tag=[sound1_Tag, sound2_Tag];
            end
        case 'REP_1ST'
            mfa_Tag=sound1_Tag;
        case 'REP_2ND'
            mfa_Tag=sound2_Tag;
        case 'REV_BTH'
            try
                mfa_Tag=strjoin([sound2_Tag, sound1_Tag],'');
            catch
                mfa_Tag=[sound2_Tag, sound1_Tag];
            end
        case 'DRP_BTH'
            mfa_Tag=[];
    end
    
    fprintf(f_stims_mfa, '%.17f\t%.17f\t%s\n', audio1Start_trialInfo, ...
         retoStart, ...
        mfa_Tag);
    
    goStart=trial_tmp.del2End-record_onset+block_wav_onsets(trial_tmp.block,1)/Fs;
    fprintf(f_gos, '%.17f\t%.17f\t%s\n', goStart, ...
        goStart+data_tsv.duration(indices_go(k)), ...
        data_tsv.trial_type{indices_go(k)});
end

fclose(f_stims);
fclose(f_stims_mfa);
fclose(f_cues);
fclose(f_gos);
