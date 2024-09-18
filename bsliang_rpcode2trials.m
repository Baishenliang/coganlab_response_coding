% Write response coding to Trials.mat for BIDs formating

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
f = fullfile(RPcode_loc,'bsliang_errors.txt'); 
error_code = readtable(f, 'Delimiter', '\t', 'Format', '%f%f%s', 'ReadVariableNames', false);

%% response codes
% input variables
ResponseStart = response_code.Var1;
ResponseEnd = response_code.Var2;

% add variables
if length(ResponseStart)==length(Trials)
    for t=1:length(ResponseStart)
        Trials(t).ResponseStart = 30000*ResponseStart(t);
        Trials(t).ResponseEnd = 30000*ResponseEnd(t);
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

load nonword_lst
load word_lst

for t=1:length(ResponseStart)
    Err_Tag = error_code.Var3(t);
    if ~isempty(Err_Tag)
        if contains(Err_Tag, 'ERR_TASK_YN_REP')
            Trials(t).Resp_err=1;
        elseif contains(Err_Tag, 'ERR_TASK_REP_YN')
            Trials(t).Resp_err=2;
        elseif contains(Err_Tag, 'ERR_RESP_REP_WRO')
            Trials(t).Resp_err=5;
        elseif contains(Err_Tag, 'ERR_RESP_REP_MIS')
            Trials(t).Resp_err=6;
        elseif contains(Err_Tag, 'NOISE')
            Trials(t).Resp_err=7;
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
                Trials(t).Resp_err=3;
            end

            % 4 ERR_RESP_YN_NY Response error: yes/no task, should say no, but say yes
            if lexical_tag==1 && strcmpi(resp_YN,'yes')
                Trials(t).Resp_err=4;
            end

        end
            
    end
end

save(fullfile(Trial_loc,"Trials.mat"),'Trials');