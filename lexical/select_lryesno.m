% This script is made to automatically detect patient's yes/no response
% in lexical repetition tasks from mfa-generated tiers. Then, two tiers are
% combined to one.
% Note that manual adjustment should be done later, as sometimes the
% patient may response things other than yes and no.
clear all;
clc;

%% Basic parameters
loc='C:\Users\bl314\';
dir='Box\CoganLab\ECoG_Task_Data\response_coding\response_coding_results\LexicalDecRepDelay\';
subjs={'D115','D117'};

for i=1:length(subjs)
    
    subj=subjs{i};
    disp(subj)
    path=[loc, dir, subj];
    cd(path)
    
    %% Load mfa tiers
    Y_words=readtable("mfa/mfa_yes_words.txt", 'ReadVariableNames', false);
    Y_words.Properties.VariableNames = {'start', 'end','cue'}; 
    N_words=readtable("mfa/mfa_no_words.txt", 'ReadVariableNames', false);
    N_words.Properties.VariableNames = {'start', 'end','cue'}; 
    R_words=readtable("mfa/mfa_resp_words.txt", 'ReadVariableNames', false);
    R_words.Properties.VariableNames = {'start', 'end','cue'}; 
    Y_phones=readtable("mfa/mfa_yes_phones.txt", 'ReadVariableNames', false);
    Y_phones.Properties.VariableNames = {'start', 'end','cue'}; 
    N_phones=readtable("mfa/mfa_no_phones.txt", 'ReadVariableNames', false);
    N_phones.Properties.VariableNames = {'start', 'end','cue'}; 
    R_phones=readtable("mfa/mfa_resp_phones.txt", 'ReadVariableNames', false);
    R_phones.Properties.VariableNames = {'start', 'end','cue'}; 
    whisper_rscodes=readtable("mfa/mfa_whisper_rscode.txt", 'ReadVariableNames', false);
    whisper_rscodes.Properties.VariableNames = {'start', 'end','cue'}; 
    
    %% Make a new cell
    YN_words=cell(size(Y_words,1),3);
    YN_errs=YN_words;
    YN_phones={};
    for i=1:size(Y_words,1)
        
        Y_word_start=Y_words.start(i);
        Y_word_end=Y_words.end(i);
        N_word_start=N_words.start(i);
        N_word_end=N_words.end(i);
        Y_win=Y_word_end-Y_word_start;
        N_win=N_word_end-N_word_start;
       
        
        Y_phone_AE_start=Y_phones.start((i-1)*3+1+1);
        Y_phone_AE_end=Y_phones.end((i-1)*3+1+1);
        Y_phone_S_start=Y_phones.start((i-1)*3+1+1+1);
        Y_phone_S_end=Y_phones.end((i-1)*3+1+1+1);
        Y_phone_AE_win=Y_phone_AE_end-Y_phone_AE_start;
        Y_phone_S_win=Y_phone_S_end-Y_phone_S_start;
        
        Y_start=Y_words.start(i);
        Y_end=Y_words.end(i);
        j=1;
        whisper_rscode=[];
        while 1
            if round(Y_start,2)>=round(whisper_rscodes.start(j),2) && round(Y_end,2)<=round(whisper_rscodes.end(j),2)
                whisper_rscode=whisper_rscodes.cue(j);
                break;
            else
                j=j+1;
            end
        end
        
        if contains(whisper_rscode, 'yes', 'IgnoreCase', true)
            % Select "Yes"
            
            YN_words{i,1}=Y_word_start;
            YN_words{i,2}=Y_word_end;
            YN_errs{i,1}=Y_word_start;
            YN_errs{i,2}=Y_word_end;
            YN_words{i,3}='yes';
            
            Y_phone_starts=Y_phones.start((i-1)*3+1:i*3);
            Y_phone_ends=Y_phones.end((i-1)*3+1:i*3);
            Y_phone_cues=Y_phones.cue((i-1)*3+1:i*3);
            
            Y_phone={Y_phone_starts(1),Y_phone_ends(1),Y_phone_cues{1};
                            Y_phone_starts(2),Y_phone_ends(2),Y_phone_cues{2};
                            Y_phone_starts(3),Y_phone_ends(3),Y_phone_cues{3}};
                        
            YN_phones=[YN_phones;Y_phone];
                        
        else
            % Select "No"
            
            YN_words{i,1}=N_word_start;
            YN_words{i,2}=N_word_end;
            YN_errs{i,1}=Y_word_start;
            YN_errs{i,2}=Y_word_end;
            if contains(whisper_rscode, 'no', 'IgnoreCase', true)
                YN_words{i,3}='no';
            else
                YN_words{i,3}='ERR';
                YN_errs{i,3}='ERR';
            end
            
            N_phone_starts=N_phones.start((i-1)*2+1:i*2);
            N_phone_ends=N_phones.end((i-1)*2+1:i*2);
            N_phone_cues=N_phones.cue((i-1)*2+1:i*2);
            
            N_phone={N_phone_starts(1),N_phone_ends(1),N_phone_cues{1};
                    N_phone_starts(2),N_phone_ends(2),N_phone_cues{2}};
                
            YN_phones=[YN_phones;N_phone];
        end
        
    end
    
    %% save files
    words=sortrows([YN_words;table2cell(R_words)],1);
    
    R_words_cell=table2cell(R_words);
    R_words_time = [R_words_cell(:,1),...
                                R_words_cell(:,2),...
                                cell(size(R_words_cell,1),1)];
    
    errs=sortrows([YN_errs;R_words_time],1);
    
    phones=sortrows([YN_phones;table2cell(R_phones)],1);
    
    fileword = fopen('mfa\mfa_words.txt', 'w');
    for i = 1:size(words,1)
	    fprintf(fileword, '%d\t%d\t%s\n', words{i,:});
    end
    fclose(fileword);
    
    filere = fopen('mfa\mfa_manual_errcode.txt', 'w');
    for i = 1:size(errs,1)
	    fprintf(filere, '%d\t%d\t%s\n', errs{i,:});
    end
    fclose(filere);
    
    filephone = fopen('mfa\mfa_phones.txt', 'w');
    for i = 1:size(phones,1)
	    fprintf(filephone, '%d\t%d\t%s\n', phones{i,:});
    end
    fclose(filephone);
end