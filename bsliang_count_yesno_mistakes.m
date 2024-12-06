% count the number of trials with YN_YN and YN_NY mistakes
clear all

subject_Tags={'D53','D54','D55','D57','D59','D63','D65','D66','D68','D69','D70','D71','D77','D79','D81','D94','D96','D101','D102','D103','D107B'};

YN_YN_counts=[];
YN_NY_counts=[];

for i_Tag=1:length(subject_Tags)
    Trials=[];

    subject_Tag=subject_Tags{i_Tag};
    % Load trials
    Trial_loc_root=fullfile('C:\Users\bl314\Box\CoganLab\D_Data\LexicalDecRepDelay\',subject_Tag);
    RPcode_loc=fullfile('C:\Users\bl314\Box\CoganLab\ECoG_Task_Data\response_coding\response_coding_results\LexicalDecRepDelay',subject_Tag);
    trial_files = dir(fullfile(Trial_loc_root, '**', 'mat', 'Trials.mat'));
    Trial_loc=trial_files.folder;
    load(fullfile(Trial_loc,"Trials.mat"));
    
    % Initialize count variables
    YN_YN_count = 0;
    YN_NY_count = 0;
    
    % Get the number of elements in the struct array
    numTrials = length(Trials);
    
    % Loop through each element in the struct array
    for i = 1:numTrials
        % Access the Cue_Tag field for the current trial
        cueTag = Trials(i).Cue_Tag; 
        
        % Check if the Cue_Tag contains "YN_YN"
        if contains(cueTag, "YN_YN")
            YN_YN_count = YN_YN_count + 1;
        end
        
        % Check if the Cue_Tag contains "YN_NY"
        if contains(cueTag, "YN_NY")
            YN_NY_count = YN_NY_count + 1;
        end
    end

    YN_YN_counts(i_Tag)=YN_YN_count;
    YN_NY_counts(i_Tag)=YN_NY_count;

end