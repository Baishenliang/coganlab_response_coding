% Write response coding to Trials.mat for BIDs formating
clear all

%% Locs
subject_Tag='D55';

switch subject_Tag
    case 'D53'
        % D53
        Trial_loc='C:\Users\bl314\Box\CoganLab\D_Data\LexicalDecRepDelay\D53\201212\mat';
        RPcode_loc='C:\Users\bl314\Box\CoganLab\ECoG_Task_Data\response_coding\response_coding_results\LexicalDecRepDelay\D53';

    case 'D54'
        % D54
        Trial_loc='C:\Users\bl314\Box\CoganLab\D_Data\LexicalDecRepDelay\D54\210127\mat';
        RPcode_loc='C:\Users\bl314\Box\CoganLab\ECoG_Task_Data\response_coding\response_coding_results\LexicalDecRepDelay\D54';
 
    case 'D55'
        % D55
        Trial_loc='C:\Users\bl314\Box\CoganLab\D_Data\LexicalDecRepDelay\D55\210301\mat';
        RPcode_loc='C:\Users\bl314\Box\CoganLab\ECoG_Task_Data\response_coding\response_coding_results\LexicalDecRepDelay\D55';

    case 'D70'
        % D70
        Trial_loc='C:\Users\bl314\Box\CoganLab\D_Data\LexicalDecRepDelay\D70\220322\mat';
        RPcode_loc='C:\Users\bl314\Box\CoganLab\ECoG_Task_Data\response_coding\response_coding_results\LexicalDecRepDelay\D70';

    case 'D94'
        Trial_loc='C:\Users\bl314\Box\CoganLab\D_Data\LexicalDecRepDelay\D94\230808\mat';
        RPcode_loc='C:\Users\bl314\Box\CoganLab\ECoG_Task_Data\response_coding\response_coding_results\LexicalDecRepDelay\D94';
    case 'D96-A'
        % D96-A
        % Data collection of D96 were separated into two days
        Trial_loc='C:\Users\bl314\Box\CoganLab\D_Data\LexicalDecRepDelay\D96\230819\mat';
        RPcode_loc='C:\Users\bl314\Box\CoganLab\ECoG_Task_Data\response_coding\response_coding_results\LexicalDecRepDelay\D96';

    case 'D96-B'
        % D96-B
        % Data collection of D96 were separated into two days
        Trial_loc='C:\Users\bl314\Box\CoganLab\D_Data\LexicalDecRepDelay\D96\230821\mat';
        RPcode_loc='C:\Users\bl314\Box\CoganLab\ECoG_Task_Data\response_coding\response_coding_results\LexicalDecRepDelay\D96';

    case 'D101'
        % D101
        Trial_loc='C:\Users\bl314\Box\CoganLab\D_Data\LexicalDecRepDelay\D101\231022\mat';
        RPcode_loc='C:\Users\bl314\Box\CoganLab\ECoG_Task_Data\response_coding\response_coding_results\LexicalDecRepDelay\D101';

    case 'D102'
        % D102
        Trial_loc='C:\Users\bl314\Box\CoganLab\D_Data\LexicalDecRepDelay\D102\240106\mat';
        RPcode_loc='C:\Users\bl314\Box\CoganLab\ECoG_Task_Data\response_coding\response_coding_results\LexicalDecRepDelay\D102';

    case 'D103'
        % D103
        Trial_loc='C:\Users\bl314\Box\CoganLab\D_Data\LexicalDecRepDelay\D103\240106\mat';
        RPcode_loc='C:\Users\bl314\Box\CoganLab\ECoG_Task_Data\response_coding\response_coding_results\LexicalDecRepDelay\D103';

    case 'D107'
        % D107
        Trial_loc='C:\Users\bl314\Box\CoganLab\D_Data\LexicalDecRepDelay\D107B\240308\mat';
        RPcode_loc='C:\Users\bl314\Box\CoganLab\ECoG_Task_Data\response_coding\response_coding_results\LexicalDecRepDelay\D107';

end
%% load files
if exist(fullfile(Trial_loc,"Trials_org.mat"), 'file') == 2
    msgbox('Trials_org.mat already exists');
    load(fullfile(Trial_loc,"Trials_org.mat"));
else
    load(fullfile(Trial_loc,"Trials.mat"));
end
save(fullfile(Trial_loc,"Trials_org.mat"),'Trials');
load(fullfile(Trial_loc,"trialinfo.mat"));

% Read txt files
f = fullfile(RPcode_loc,'bsliang_resp_words.txt'); 
response_code = readtable(f, 'Delimiter', '\t', 'Format', '%f%f%s', 'ReadVariableNames', false);
f = fullfile(RPcode_loc,'mfa\mfa_stim_words.txt'); 
stim_code = readtable(f, 'Delimiter', '\t', 'Format', '%f%f%s', 'ReadVariableNames', false);
f = fullfile(RPcode_loc,'bsliang_errors.txt'); 
error_code = readtable(f, 'Delimiter', '\t', 'Format', '%f%f%s', 'ReadVariableNames', false);


%% stimuli and response codes
% input variables
StimStart_mfa = stim_code.Var1;
StimEnd_mfa = stim_code.Var2;
StimCue = stim_code.Var3;
ResponseStart = response_code.Var1;
ResponseEnd = response_code.Var2;

if contains(Trial_loc,'D102')
    ResponseStart = ResponseStart(1:331); % Patient D102 only
end

if isequal(subject_Tag,'D96-A')
    StimStart_mfa = StimStart_mfa(1:168);
    StimEnd_mfa = StimEnd_mfa(1:168);
    StimCue = StimCue(1:168);
    ResponseStart = ResponseStart(1:168);
    ResponseEnd = ResponseEnd(1:168);
elseif isequal(subject_Tag,'D96-B')
    StimStart_mfa = StimStart_mfa(169:end);
    StimEnd_mfa = StimEnd_mfa(169:end);
    StimCue = StimCue(169:end);
    ResponseStart = ResponseStart(169:end);
    ResponseEnd = ResponseEnd(169:end);
end

load nonword_lst
load word_lst

% add variables
if length(ResponseStart)==length(Trials)
    for t=1:length(ResponseStart)

        %% testing congruency
        StimCue_t=StimCue(t);
        disp([trialInfo{1,t}.sound,' in TrialInfo, and ', StimCue_t{1}, ' in MFA event coding.'])
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
        else
            Task_type_Tag='Repeat';
        end

        % get cue word and lexical property
        cue_word=trialInfo{1,t}.sound;
        if any(strcmp(cue_word, words))
            Task_word_Tag='Word';
        elseif any(strcmp(cue_word, nonwords))
            Task_word_Tag='Nonword';
        else
            msgbox('Wrong word cue. Check the response coding.');
        end

        %% Error, noise, and late response coding

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
        if t>1 && Trials(t).Auditory-0.5-Trials(t-1).ResponseEnd<0
            if isempty(Resp_Err)
                Resp_Err='NOISY_BSL';
            else
                Resp_Err=[Resp_Err,'/NOISY_BSL'];
            end
        end

        % If Oral response comes before the "GO" cue, the trial is marked
        % as "EARLY_RESP"
        if Trials(t).ResponseStart-Trials(t).Go<0
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
        Trials(t).Delay_Tag = ['Delay','/',Task_type_Tag,'/',Task_word_Tag,'/',Trials(t).StimCue{1},'/',Resp_Err];
        Trials(t).Go_Tag = ['Go','/',Task_type_Tag,'/',Task_word_Tag,'/',Trials(t).StimCue{1},'/',Resp_Err];
        Trials(t).Response_Tag = ['Resp','/',Task_type_Tag,'/',Task_word_Tag,'/',Trials(t).StimCue{1},'/',Resp_Err];


    end
else
    msgbox('Trial number does not match response coding!')
end

save(fullfile(Trial_loc,"Trials.mat"),'Trials');