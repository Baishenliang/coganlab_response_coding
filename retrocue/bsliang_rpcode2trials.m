% Write response coding to Trials.mat for BIDs formating
clear all; clc

subjects_Tag = ["D117"];

task_type='Retro_cue\';
box_local='C:\Users\bl314\Box\';

for subject_Tag = subjects_Tag

    %% Locs
    RPcode_loc=fullfile(box_local,'CoganLab\ECoG_Task_Data\response_coding\response_coding_results\',task_type,subject_Tag);
    Trial_loc_root=fullfile(box_local,'CoganLab\D_Data\',task_type,subject_Tag);

    trial_files = dir(fullfile(Trial_loc_root, '**', 'mat', 'Trials.mat'));

    if numel(trial_files) > 1
        error([subject_Tag ' Found more than one Trial.mat']);
    elseif isscalar(trial_files)
        disp([subject_Tag ' Trial.mat found at: ', fullfile(trial_files.folder, trial_files.name)]);
        Trial_loc=trial_files.folder;
    else
        error([subject_Tag 'No Trial.mat file found.']);
    end
    
    %% load files
    if exist(fullfile(Trial_loc,"Trials_org.mat"), 'file') == 2
        disp([subject_Tag 'Trials_org.mat already exists']);
        load(fullfile(Trial_loc,"Trials_org.mat"));
    else
        load(fullfile(Trial_loc,"Trials.mat"));
    end
    save(fullfile(Trial_loc,"Trials_org.mat"),'Trials');
    load(fullfile(Trial_loc,"trialinfo.mat"));

    % Read cue events files
    f = fullfile(RPcode_loc,'cue_events.txt'); 
    cue_events = readtable(f, 'Delimiter', '\t', 'Format', '%f%f%s', 'ReadVariableNames', false);
    
    odd_rows = 1:2:height(cue_events);
    even_rows = 2:2:height(cue_events);

    first_events = cue_events(odd_rows, :);
    second_events = cue_events(even_rows, :);

    % Read response coding files
    f = fullfile(RPcode_loc,'bsliang_resp_words_errors.txt'); 
    response_code = readtable(f, 'Delimiter', '\t', 'Format', '%f%f%s', 'ReadVariableNames', false);

    %% stimuli and response codes
    % input variables
    [Stim1Start_mfa, Stim1End_mfa,...
        Stim2Start_mfa, Stim2End_mfa] =deal(zeros(1,numel(Trials))); 

    [Stim1Cue, Stim2Cue]=deal(cell(1,numel(Trials)));

    dict = containers.Map(...
        {'ga', 'mo', 'ree'},...
        {0.5783900226757369, 0.6743537414965987, 0.6221995464852608});

    for trial=1:numel(Trials)
        % Get stim
        Stim1Cue{trial}=first_events.Var3{trial};
        Stim2Cue{trial}=second_events.Var3{trial};
        % Get stim timepoints
        Stim1Start_mfa(trial) = first_events.Var1(trial);
        Stim1End_mfa(trial) = Stim1Start_mfa(trial)+dict(Stim1Cue{trial});
        Stim2Start_mfa(trial) = second_events.Var1(trial);
        Stim2End_mfa(trial) = Stim2Start_mfa(trial)+dict(Stim2Cue{trial});
    end

    % check trial numbers
    if numel(Trials)~=numel(trialInfo)
        error('Trials.mat and TrialInfo.mat not matched in length')
    end

    % Check the trial numbers here.
    if (288/(288-72))*numel(response_code.Var1)~=numel(trialInfo)
        error('response_code and TrialInfo.mat not matched in length')
    end

    % Start making the responses and errors
    [ResponseStart,ResponseEnd]=deal(nan(1,numel(Trials)));
    Resp_Errs=cell(1,numel(Trials));
    rep_idx=0;

    for trial=1:numel(Trials)
        cue=trialInfo{1,trial}.cue;

        % wait for future error coding for DRP_BTH
        if ~strcmp(cue,'0')
            rep_idx=rep_idx+1;
            ResponseStart(trial)=response_code.Var1(rep_idx);
            ResponseEnd(trial)=response_code.Var2(rep_idx);
            resp=response_code.Var3(rep_idx);
            if contains(resp{1}, 'ERR')
                Resp_Errs{trial}=resp{1};
            else
                Resp_Errs{trial}=[];
            end
        end
    end
    clear trial cue resp rt RespCorrect

    % add variables
    for t=1:numel(Trials)

        %% testing congruency
        Stim1Cue_t=Stim1Cue(t);
        Stim2Cue_t=Stim2Cue(t);
        disp(strjoin(['Trial No ',num2str(t),' ',subject_Tag,' ',trialInfo{1,t}.sound1,trialInfo{1,t}.sound2,' in TrialInfo, and ', Stim1Cue_t{1}, Stim2Cue_t{1},' in response coding.']))

        %% Temporal coding
        % Calculate the time difference between response coding and
        % temporal information from the recording.
        % Response coding time points are aligned to recorded sound files.
        % Markers from Trial.mat are aligned to the recorded ieeg signals.
        % Hence we need the adjustment.
        Diff_RScode_EDFcode=30000*Stim1Start_mfa(t)-Trials(t).audio1Start;

        Trials(t).Stim1End_mfa = 30000*Stim1End_mfa(t)-Diff_RScode_EDFcode;
        Trials(t).Stim1Cue = Stim1Cue(t);
        Trials(t).Stim2End_mfa = 30000*Stim2End_mfa(t)-Diff_RScode_EDFcode;
        Trials(t).Stim2Cue = Stim2Cue(t);

        Trials(t).RetroEnd = Trials(t).RetroStart + (trialInfo{1,t}.cueEnd-trialInfo{1,t}.del1End)*3e4;
        Trials(t).GoEnd = Trials(t).GoStart + (trialInfo{1,t}.goEnd-trialInfo{1,t}.del2End)*3e4;
        
        if isnan(ResponseStart(t)) % For DRP_BTH conditions
            Trials(t).ResponseStart = Trials(t).RetroEnd;
            Trials(t).ResponseEnd = Trials(t).RetroEnd;
        else
            Trials(t).ResponseStart = 30000*ResponseStart(t)-Diff_RScode_EDFcode;
            Trials(t).ResponseEnd = 30000*ResponseEnd(t)-Diff_RScode_EDFcode;
        end

        %% ERR coding
        Resp_Err=Resp_Errs{t};

        % If the patient responses too late (i.e., the response end comes later
        % than the starting point of the next trial). Then mark all the events
        % of the current trials as "LATE_RESP"
        if t<length(ResponseStart) && Trials(t+1).audio1Start-Trials(t).ResponseEnd<0
            if isempty(Resp_Err)
                Resp_Err='LATE_RESP';
            else
                Resp_Err=[Resp_Err,'/LATE_RESP'];
            end
        end

        % For the trial before, if the patient responses too late and affect the baseline.
        % Then mark all the event of the current trials as "NOISY_BSL"
        if t>1 && Trials(t).audio1Start-0.5*30000-Trials(t-1).ResponseEnd<0
            disp('Noisy baseline trial detected')
            if isempty(Resp_Err)
                Resp_Err='NOISY_BSL';
            else
                Resp_Err=[Resp_Err,'/NOISY_BSL'];
            end
        end

        % Oral response comes before the "GO" cue, the trial is marked
        % as "EARLY_RESP"
        No_earlier_than_T=Trials(t).GoStart;
         if Trials(t).ResponseStart-No_earlier_than_T<0
            if isempty(Resp_Err)
                Resp_Err='EARLY_RESP';
            else
                Resp_Err=[Resp_Err,'/EARLY_RESP'];
            end
        end

        % If Resp_Err is still empty, make it as "CORRECT".
        if isempty(Resp_Err)
            Resp_Err='CORRECT';
        end
    
        %% Get retrocue type
        retro_code=trialInfo{1,t}.cue;
        if strcmp(retro_code,'0')
            Retro_cue='DRP_BTH';
        elseif strcmp(retro_code,'1')
            Retro_cue='REP_1ST';
        elseif strcmp(retro_code,'2')
            Retro_cue='REP_2ND';
        elseif strcmp(retro_code,'1 2')
            Retro_cue='REP_BTH';
        elseif strcmp(retro_code,'2 1')
            Retro_cue='REV_BTH';
        end

        %% Add the condition and error codings to Cue, Auditoru stimuli, Delay
        Stim_marker=[Trials(t).Stim1Cue{1},'/',Trials(t).Stim2Cue{1},'/','stim1_',Trials(t).Stim1Cue{1},'/','stim2_',Trials(t).Stim2Cue{1},'/',Retro_cue,'/',Resp_Err];
        Trials(t).Audio1_Tag = ['Audio1','/',Stim_marker];
        Trials(t).Audio2_Tag = ['Audio2','/',Stim_marker];
        Trials(t).Retrocue_Tag = ['Retro_Cue','/',Stim_marker,];
        Trials(t).Go_Tag = ['Go','/',Stim_marker,];
        Trials(t).Response_Tag = ['Resp','/',Stim_marker,];


    end
    
    save(fullfile(Trial_loc,"Trials.mat"),'Trials');
end