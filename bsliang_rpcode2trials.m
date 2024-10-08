% Write response coding to Trials.mat for BIDs formating
clear all

%% Locs
Trial_loc='C:\Users\bl314\Box\CoganLab\D_Data\LexicalDecRepDelay\D103\240106\mat';
RPcode_loc='C:\Users\bl314\Box\CoganLab\ECoG_Task_Data\response_coding\response_coding_results\LexicalDecRepDelay\D103';

%% load files
load(fullfile(Trial_loc,"Trials.mat"));
load(fullfile(Trial_loc,"trialinfo.mat"));
save(fullfile(Trial_loc,"Trials_org.mat"),'Trials');

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

load nonword_lst
load word_lst

% add variables
if length(ResponseStart)==length(Trials)
    for t=1:length(ResponseStart)
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

        Trials(t).Cue_Tag = ['Cue','/',Task_type_Tag,'/',Task_word_Tag];
        Trials(t).Auditory_Tag = ['Auditory_stim','/',Task_type_Tag,'/',Task_word_Tag,'/',Trials(t).Stimcue];
        Trials(t).Delay_Tag = ['Delay','/',Task_type_Tag,'/',Task_word_Tag];
    end
else
    msgbox('Trial number does not match response coding!')
end

%% error codes
%  also determines whether a yes/no trial is responded correctly
%  (i.e., whether type 3 or type 3 error)

% 1 ERR_TASK_YN_REP Task error: yes/no task but word repetition
% 2 ERR_TASK_REP_YN Task error: word repetition but yes/no task	
% 3 ERR_RESP_YN_YN Response error: yes/no task, should say yes, but say no	
% 4 ERR_RESP_YN_NY Response error: yes/no task, should say no, but say yes	
% 5 ERR_RESP_REP_WRO Response error: repetition task, say a totally wrong word/nonword
% 6 ERR_RESP_REP_MIS Response error: repetition task, say a word/nonword with mistakes at phonemic or syllabic levels
% 7 NOISY Noisy


for t=1:length(ResponseStart)
    Err_Tag = error_code.Var3(t);
    if ~isempty(Err_Tag)
        if contains(Err_Tag, 'ERR_TASK_YN_REP')
            Trials(t).Response_Tag='ERR_TASK/YN_REP';
        elseif contains(Err_Tag, 'ERR_TASK_REP_YN')
            Trials(t).Response_Tag='ERR_TASK/REP_YN';
        elseif contains(Err_Tag, 'ERR_RESP_REP_WRO')
            try
                Trials(t).Response_Tag=['ERR_RESP/REP_WRO',Err_Tag(17:end)];
            catch
                Trials(t).Response_Tag='ERR_RESP/REP_WRO';
            end
        elseif contains(Err_Tag, 'ERR_RESP_REP_MIS')
            try
                Trials(t).Response_Tag=['ERR_RESP/REP_MIS',Err_Tag(17:end)];
            catch
                Trials(t).Response_Tag='ERR_RESP/REP_MIS';
            end
        elseif contains(Err_Tag, 'NOISE')
            Trials(t).Response_Tag='NOISE';
        end
    else
        if isequal(trialInfo{1,t}.cue,'Yes/No')
            % lexical task error coding

            % get cue word and lexical property
            cue_word=trialInfo{1,t}.sound;
            if any(strcmp(cue_word, words))
                lexical_tag=1; % is a word
            elseif any(strcmp(cue_word, nonwords))
                lexical_tag=2; % not a word
            else
                msgbox('Wrong word cue. Check the response coding.');
            end
            
            % get response Y/N
            resp_YN=response_code.Var3(t);

            % 3 ERR_RESP_YN_YN Response error: yes/no task, should say yes, but say no
            if lexical_tag==1 && strcmpi(resp_YN,'no')
                %Trials(t).Response_Tag=3;
                Trials(t).Response_Tag='ERR_RESP/YN_YN';
            end

            % 4 ERR_RESP_YN_NY Response error: yes/no task, should say no, but say yes
            if lexical_tag==1 && strcmpi(resp_YN,'yes')
                %Trials(t).Response_Tag=4;
                Trials(t).Response_Tag='ERR_RESP/YN_NY';
            end

        end
    end

    % If it is still empty, add "CORRECT" in the error code to avoid null.
    if isempty(Trials(t).Response_Tag)
        Trials(t).Response_Tag='CORRECT';
    end

    % If the patient responses too late (i.e., the response end comes later
    % than the starting point of the next trial baseline). Then mark all the events
    % of the current trials as "XXX_NOISY_BSL", and the response in the
    % previous trial as "XXX_LATE_RESP".
    if t>1 && Trials(t).Auditory-0.5-Trials(t-1).ResponseEnd<0
        Trials(t-1).Response_Tag=[Trials(t-1).Response_Tag,'/LATE_RESP'];
        Trials(t).Cue_Tag = [Trials(t).Cue_Tag,'/NOISY_BSL'];
        Trials(t).Auditory_Tag = [Trials(t).Auditory_Tag,'/NOISY_BSL'];
        Trials(t).Delay_Tag = [Trials(t).Delay_Tag,'/NOISY_BSL'];
        Trials(t).Response_Tag=[Trials(t).Response_Tag,'/NOISY_BSL'];
    end
end

save(fullfile(Trial_loc,"Trials.mat"),'Trials');