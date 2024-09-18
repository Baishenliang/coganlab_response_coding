% make word and nonword matrix for response error (type 3 and type 4)
% coding.

clear all; clc;

%% locations
loc_nonword='C:\Users\bl314\Box\CoganLab\ECoG_Task_Data\Stim\Lexical\nonwords';
loc_word='C:\Users\bl314\Box\CoganLab\ECoG_Task_Data\Stim\Lexical\words';

%% make the matrices

% nonword
wavFiles_nonwords = dir(fullfile(loc_nonword, '*.wav'));
nonwords = cell(length(wavFiles_nonwords), 1);

for i = 1:length(wavFiles_nonwords)
    nonwords{i} = wavFiles_nonwords(i).name;
end

% word
wavFiles_words = dir(fullfile(loc_word, '*.wav'));
words = cell(length(wavFiles_words), 1);

for i = 1:length(wavFiles_words)
    words{i} = wavFiles_words(i).name;
end

save nonword_lst nonwords
save word_lst words