%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Warning: Usually I did not regenerate the condition_event after
%   correcting the cue_event, whichi make causes some jitters for the
%   condition_event
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear all
clc

box_local='C:\Users\bl314\Box\';
subj='D80';
if strcmp(subj,'D63') 
    subj_path=[box_local,'CoganLab\ECoG_Task_Data\Cogan_Task_Data\D63\Lexical Delay\Block 1 2 3 4'];
else
    subj_path=fullfile(box_local,'CoganLab\ECoG_Task_Data\response_coding\response_coding_results\LexicalDecRepDelay\',subj);
end

load(fullfile(subj_path,'trialInfo.mat'));
% load block_wav_onsets.mat

if iscell(trialInfo)
trialInfo = cellfun(@(a) a, trialInfo);
end

rc = scantext(fullfile(subj_path,'cue_events.txt'), '\t', 0, '%f %f %s');
first_stims_onset = rc{1};
% fid = fopen('go_events.txt', 'w');
file_path = fullfile(subj_path, 'condition_events.txt');
if exist(file_path, 'file') == 2
    error('File "%s" already exists. Program terminated.', file_path);
end
fid2 = fopen(file_path, 'w');
if fid2 == -1
    error('Failed to open file for writing: %s', file_path);
end


b = 0;
for t = 1:numel(trialInfo)
    if trialInfo(t).block ~= b
        b = b + 1;
        if isfield(trialInfo,'audiostart')
            on1 = trialInfo(t).audiostart; %Start;
        elseif isfield(trialInfo,'audioStart')
            on1 = trialInfo(t).audioStart; %Start;
        elseif isfield(trialInfo,'stimulusAudioStart')
            on1 = trialInfo(t).stimulusAudioStart; %Start;
        elseif isfield(trialInfo,'stimuliAlignedTrigger')
            on1 = trialInfo(t).stimuliAlignedTrigger;
        else
            on1 = trialInfo(t).cueStart;
        end
        anchor = on1;
        onset = first_stims_onset(t);
    end
%     on = trialInfo(t).goStart - anchor + first_stims_onset(b);
%     off = on + trialInfo(t).goEnd - trialInfo(t).goStart;
% %     off = on + 2;
%     fwrite(fid, sprintf('%f\t%f\t%d_%s\n', on, off, t, trialInfo(t).sound));
    
    on = trialInfo(t).cueStart - anchor + onset;
    off = on + .5;
    if isfield(trialInfo(t), 'cue')
        cue = trialInfo(t).cue;
    elseif isfield(trialInfo(t),'condition')
        cue = trialInfo(t).condition;
    end
    fwrite(fid2, sprintf('%f\t%f\t%d_%s\n', on, off, t, cue));
end
% fclose(fid);
fclose(fid2);