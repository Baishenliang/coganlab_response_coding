% Write response coding to Trials.mat for BIDs formating
clear all; clc

subjects_Tag = ["D57"];

%task_type='LexicalDecRepDelay\';
task_type='LexicalDecRepNoDelay\';
box_local='C:\Users\bl314\Box\';

for subject_Tag = subjects_Tag

    %% Locs
    RPcode_loc=fullfile(box_local,'CoganLab\ECoG_Task_Data\response_coding\response_coding_results\',task_type,subject_Tag);
    if isequal(subject_Tag,"D107B")
        RPcode_loc=fullfile(box_local,'CoganLab\ECoG_Task_Data\response_coding\response_coding_results\',task_type,subject_Tag);
    end
    Trial_loc_root=fullfile(box_local,'CoganLab\D_Data\',task_type,subject_Tag);

    trial_files = dir(fullfile(Trial_loc_root, '**', 'mat', 'Trials.mat'));
    % if strcmp(subject_Tag,'D25')
    %     trial_files = dir(fullfile('C:\Users\bl314\Box\CoganLab\D_Data\LexicalDecRepDelay\notrigger_D25', 'Trials.mat'));
    % end
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
    
    % Read txt files
    if strcmp(task_type,'LexicalDecRepDelay\')
        f = fullfile(RPcode_loc,'bsliang_resp_words.txt'); 
        response_code = readtable(f, 'Delimiter', '\t', 'Format', '%f%f%s', 'ReadVariableNames', false);
        f = fullfile(RPcode_loc,'mfa\mfa_stim_words.txt'); 
        stim_code = readtable(f, 'Delimiter', '\t', 'Format', '%f%f%s', 'ReadVariableNames', false);
        f = fullfile(RPcode_loc,'bsliang_errors.txt'); 
        error_code = readtable(f, 'Delimiter', '\t', 'Format', '%f%f%s', 'ReadVariableNames', false);
    elseif strcmp(task_type,'LexicalDecRepNoDelay\')
        f = fullfile(RPcode_loc,'bsliang_resp_words_errors.txt'); 
        response_code = readtable(f, 'Delimiter', '\t', 'Format', '%f%f%s', 'ReadVariableNames', false);
        f = fullfile(RPcode_loc,'mfa\mfa_stim_words.txt'); 
        stim_code = readtable(f, 'Delimiter', '\t', 'Format', '%f%f%s', 'ReadVariableNames', false);
    end
    
    %% stimuli and response codes
    % input variables
    StimStart_mfa = stim_code.Var1;
    StimEnd_mfa = stim_code.Var2;
    StimCue = stim_code.Var3;

     % check trial numbers
    if numel(Trials)~=numel(trialInfo)
        error('Trials.mat and TrialInfo.mat not matched in length')
    end

    if strcmp(task_type,'LexicalDecRepDelay\')

        % For lexical delay, everything about responses are stored in the
        % response_code
       
        ResponseStart = response_code.Var1;
        ResponseEnd = response_code.Var2;

        % Trial correction
        if contains(Trial_loc,'D90')
            ResponseStart = ResponseStart(1:296); % Patient D90 only
        elseif contains(Trial_loc,'D28')
            StimStart_mfa = StimStart_mfa([1:299,314:end]); % Patient D28 only
            StimEnd_mfa = StimEnd_mfa([1:299,314:end]);
            StimCue = StimCue([1:299,314:end]);
            ResponseStart = ResponseStart([1:299,314:end]);
            ResponseEnd = ResponseEnd([1:299,314:end]);
        elseif contains(Trial_loc,'D26')
            StimStart_mfa = StimStart_mfa(169:end); % Patient D26 only
            StimEnd_mfa = StimEnd_mfa(169:end);
            StimCue = StimCue(169:end);
            ResponseStart = ResponseStart(169:end);
            ResponseEnd = ResponseEnd(169:end);
        elseif contains(Trial_loc,'D92') % Patient D92 only
            StimStart_mfa = StimStart_mfa(85:end);
            StimEnd_mfa = StimEnd_mfa(85:end);
            StimCue = StimCue(85:end);
            ResponseStart = ResponseStart(85:end);
            ResponseEnd = ResponseEnd(85:end);
        elseif contains(Trial_loc,'D100')
            ResponseStart = ResponseStart(1:252); % Patient D100 only
        elseif contains(Trial_loc,'D102')
            ResponseStart = ResponseStart(1:331); % Patient D102 only
        elseif contains(Trial_loc,'D117')
            StimStart_mfa = StimStart_mfa([1:113,115:end]); % Patient D117 only
            StimEnd_mfa = StimEnd_mfa([1:113,115:end]);
            StimCue = StimCue([1:113,115:end]);
            ResponseStart = ResponseStart([1:113,115:end]);
            ResponseEnd = ResponseEnd([1:113,115:end]);
        end

        % check trial numbers
        if numel(response_code.Var1)~=numel(trialInfo)
            error('response_code and TrialInfo.mat not matched in length')
        end

    elseif strcmp(task_type,'LexicalDecRepNoDelay\')

        % For lexical no delay tasks, check the trial numbers here.
        if 3*numel(response_code.Var1)~=numel(trialInfo)
            error('response_code and TrialInfo.mat not matched in length')
        end

        % Start making the responses and errors
        error_code=zeros(1,numel(Trials));
        ResponseStart=zeros(1,numel(Trials));
        ResponseEnd=zeros(1,numel(Trials));
        rep_idx=0;

        for trial=1:numel(Trials)
            cue=trialInfo{1,trial}.cue;
            resp=trialInfo{1,trial}.Resp;
            if strcmp(cue,':=:')
                % Should expect no response
                ResponseStart(trial)=StimEnd_mfa(trial);
                ResponseEnd(trial)=StimEnd_mfa(trial);
                if strcmp(resp,'No Response')
                    error_code(trial)=1; % correct
                else
                    error_code(trial)=0;
                end
            elseif strcmp(cue,'Yes/No')
                % Reaction time is the time from stim onset
                % https://github.com/coganlab/Tasks/blob/main/Lexical%20No%20Delay/Lex_DecisionRepeat_NoDelay_Mouse_2x.m
                ResponseStart(trial)=StimStart_mfa(trial)+trialInfo{1,trial}.ReactionTime;
                ResponseEnd(trial)=ResponseStart(trial);
                error_code(trial)=trialInfo{1,trial}.RespCorrect; % This can be checked in ther future, but currently I trust the judgement from the trialInfo.
            elseif strcmp(cue,'Repeat')
                rep_idx=rep_idx+1;
                ResponseStart(trial) = response_code.Var1(rep_idx);
                ResponseEnd(trial) = response_code.Var2(rep_idx);
                resp_code = response_code.Var3(rep_idx);
                if  strcmp(resp_code,StimCue(trial))
                    error_code(trial) = 1; % correct
                else
                    error_code(trial) = 0;
                end
            end
        end
        clear trial cue resp rt RespCorrect
    end
    
    load nonword_lst
    load word_lst
    
    % add variables
    for t=1:length(ResponseStart)

        %% testing congruency
        StimCue_t=StimCue(t);
        disp(strjoin(['Trial No ',num2str(t),' ',subject_Tag,' ',trialInfo{1,t}.sound,' in TrialInfo, and ', StimCue_t{1}, ' in MFA event coding.']))

        %% Temporal coding
        % Calculate the time difference between response coding and
        % temporal information from the recording.
        % Response coding time points are aligned to recorded sound files.
        % Markers from Trial.mat are aligned to the recorded ieeg signals.
        % Hence we need the adjustment.
        Diff_RScode_EDFcode=30000*StimStart_mfa(t)-Trials(t).Auditory;
        Trials(t).StimEnd_mfa = 30000*StimEnd_mfa(t)-Diff_RScode_EDFcode;
        Trials(t).StimCue = StimCue(t);
        Trials(t).ResponseStart = 30000*ResponseStart(t)-Diff_RScode_EDFcode;
        Trials(t).ResponseEnd = 30000*ResponseEnd(t)-Diff_RScode_EDFcode;

        %% Condition coding

        % get the yes and no
        if isequal(trialInfo{1,t}.cue,'Yes/No')
            Task_type_Tag='Yes_No';
        elseif isequal(trialInfo{1,t}.cue,'Repeat')
            Task_type_Tag='Repeat';
        elseif isequal(trialInfo{1,t}.cue,':=:')
            Task_type_Tag=':=:';
        end

        % get cue word and lexical property
        cue_word=trialInfo{1,t}.sound;

        if strcmp(task_type,'LexicalDecRepDelay\') && contains(Trial_loc,'D23')
            if strcmp(cue_word,'casif.wav')
                cue_word='casef.wav';
            elseif strcmp(cue_word,'valek.wav')
                cue_word='valuk.wav';
            end
        end

        if any(strcmp(cue_word, words))
            Task_word_Tag='Word';
        elseif any(strcmp(cue_word, nonwords))
            Task_word_Tag='Nonword';
        else
            msgbox([cue_word,'Wrong word cue. Check the response coding.']);
        end

        if strcmp(task_type,'LexicalDecRepDelay\')
  
            %% Error, noise, and late response coding for lexical delay
    
            % 1 ERR_TASK_YN_REP Task error: yes/no task but word repetition
            % 2 ERR_TASK_REP_YN Task error: word repetition but yes/no task	
            % 3 ERR_RESP_YN_YN Response error: yes/no task, should say yes, but say no	
            % 4 ERR_RESP_YN_NY Response error: yes/no task, should say no, but say yes	
            % 5 ERR_RESP_REP_WRO Response error: repetition task, say a totally wrong word/nonword
            % 6 ERR_RESP_REP_MIS Response error: repetition task, say a word/nonword with mistakes at phonemic or syllabic levels
            % 7 NOISY Noisy
    
            % get the error type
            Err_Tag = error_code.Var3(t);
            Resp_Err = [];
    
            if ~isempty(Err_Tag)
                if contains(Err_Tag, 'ERR_TASK_YN_REP')
                    Resp_Err='ERR_TASK/YN_REP';
                elseif contains(Err_Tag, 'ERR_TASK_REP_YN')
                    Resp_Err='ERR_TASK/REP_YN';
                elseif contains(Err_Tag, 'ERR_RESP_REP_WRO')
                    try
                        Resp_Err=['ERR_RESP/REP_WRO','/',Err_Tag{1}(18:end)];
                    catch
                        Resp_Err='ERR_RESP/REP_WRO';
                    end
                elseif contains(Err_Tag, 'ERR_RESP_REP_MIS')
                    try
                        Resp_Err=['ERR_RESP/REP_MIS','/',Err_Tag{1}(18:end)];
                    catch
                        Resp_Err='ERR_RESP/REP_MIS';
                    end
                elseif contains(Err_Tag, 'NOISE')
                    Resp_Err='NOISE';
                end
            else
                if isequal(trialInfo{1,t}.cue,'Yes/No')
                    % lexical task error coding
                    
                    % get response Y/N
                    resp_YN=response_code.Var3(t);
        
                    % 3 ERR_RESP_YN_YN Response error: yes/no task, should say yes, but say no
                    if isequal(Task_word_Tag,'Word') && strcmpi(resp_YN,'no')
                        Resp_Err='ERR_RESP/YN_YN';
                    end
        
                    % 4 ERR_RESP_YN_NY Response error: yes/no task, should say no, but say yes
                    if isequal(Task_word_Tag,'Nonword') && strcmpi(resp_YN,'yes')
                        Resp_Err='ERR_RESP/YN_NY';
                    end
        
                end
            end

        elseif strcmp(task_type,'LexicalDecRepNoDelay\')

            % ERR coding for lexical no delay is more casual now, but can
            % be updated 

            if error_code(t)==1
                Resp_Err = [];
            else
                Resp_Err = 'RESP_ERR';
            end

        end

        % If the patient responses too late (i.e., the response end comes later
        % than the starting point of the next trial). Then mark all the events
        % of the current trials as "LATE_RESP"
        if t<length(ResponseStart) && Trials(t+1).Start-Trials(t).ResponseEnd<0
            if isempty(Resp_Err)
                Resp_Err='LATE_RESP';
            else
                Resp_Err=[Resp_Err,'/LATE_RESP'];
            end
        end

        % For the trial before, if the patient responses too late and affect the baseline.
        % Then mark all the event of the current trials as "NOISY_BSL"
        if t>1 && Trials(t).Start-0.5*30000-Trials(t-1).ResponseEnd<0
            disp('Noisy baseline trial detected')
            if isempty(Resp_Err)
                Resp_Err='NOISY_BSL';
            else
                Resp_Err=[Resp_Err,'/NOISY_BSL'];
            end
        end

        if strcmp(task_type,'LexicalDecRepDelay\')
            % For Lexical Delay
            % Oral response comes before the "GO" cue, the trial is marked
            % as "EARLY_RESP"
            No_earlier_than_T=Trials(t).Go;
        elseif strcmp(task_type,'LexicalDecRepNoDelay\')
            % For Lexical No Delay
            % Any responses comes before the End of the sound, the trial is marked
            % as "EARLY_RESP"
            No_earlier_than_T=Trials(t).StimEnd_mfa-0.1*3e4;
            % Give it a 0.1s tolerance preceeding window
        end
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
    

        %% Add the condition and error codings to Cue, Auditoru stimuli, Delay
        Trials(t).Cue_Tag = ['Cue','/',Task_type_Tag,'/',Task_word_Tag,'/',Trials(t).StimCue{1},'/',Resp_Err];
        Trials(t).Auditory_Tag = ['Auditory_stim','/',Task_type_Tag,'/',Task_word_Tag,'/',Trials(t).StimCue{1},'/',Resp_Err];
        if strcmp(task_type,'LexicalDecRepDelay\')
            Trials(t).Delay_Tag = ['Delay','/',Task_type_Tag,'/',Task_word_Tag,'/',Trials(t).StimCue{1},'/',Resp_Err];
            Trials(t).Go_Tag = ['Go','/',Task_type_Tag,'/',Task_word_Tag,'/',Trials(t).StimCue{1},'/',Resp_Err];
        end
        Trials(t).Response_Tag = ['Resp','/',Task_type_Tag,'/',Task_word_Tag,'/',Trials(t).StimCue{1},'/',Resp_Err];


    end
    
    save(fullfile(Trial_loc,"Trials.mat"),'Trials');
end