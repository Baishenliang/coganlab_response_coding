clc; clear; close all;

%% 1. Configuration / Path Setup

% -------------------------------------------------------------------------
% [USER OPTION] Select which tasks to process:
% 1 = Lexical Delay ONLY
% 2 = Lexical No Delay ONLY
% 3 = BOTH (Lexical Delay AND Lexical No Delay)
taskMode = 1; 
% -------------------------------------------------------------------------

% Main directory for Source Data
sourceDataRoot = 'C:\Users\bl314\Box\CoganLab\ECoG_Task_Data\Cogan_Task_Data';

% Path to dependency scripts (combine_wavs)
depPath = 'C:\Users\bl314\Box\CoganLab\ECoG_Task_Data\response_coding\response_coding_dep';

% Main directory for Results
resultsRoot = 'C:\Users\bl314\Box\CoganLab\ECoG_Task_Data\response_coding\response_coding_results';

% Add dependency path
if exist(depPath, 'dir')
    addpath(genpath(depPath));
    fprintf('Path added: %s\n', depPath);
else
    error('Dependency folder not found: %s', depPath);
end

%% 2. Search for subject folders (D121 and above)
items = dir(sourceDataRoot);
dirFlags = [items.isdir];
subFolders = items(dirFlags);

for i = 1:length(subFolders)
    subName = subFolders(i).name;
    
    % Regex to match D + Number (e.g., D121)
    tokens = regexp(subName, '^D(\d+)$', 'tokens');
    
    if ~isempty(tokens)
        subNum = str2double(tokens{1}{1});
        
        % Filter for subjects D121 and larger
        if subNum > 121
            fprintf('\n----------------------------------------\n');
            fprintf('Found Subject: %s\n', subName);
            processSubject(sourceDataRoot, subName, resultsRoot, taskMode);
        end
    end
end

fprintf('\nAll Done!\n');

%% ---------------------------------------------------------
%  Main Processing Function
%  ---------------------------------------------------------
function processSubject(sourceRoot, subName, resultsRoot, mode)
    subSourcePath = fullfile(sourceRoot, subName);
    
    % Determine which folders to look for based on user selection
    switch mode
        case 1
            taskFolders = {'Lexical Delay'};
        case 2
            taskFolders = {'Lexical No Delay'};
        case 3
            taskFolders = {'Lexical Delay', 'Lexical No Delay'};
        otherwise
            error('Invalid taskMode selected.');
    end
    
    for t = 1:length(taskFolders)
        taskName = taskFolders{t};
        % Path to the Task Folder (e.g., .../D121/Lexical Delay)
        taskBasePath = fullfile(subSourcePath, taskName);
        
        % --- UPDATE 2: Check destination FIRST to decide whether to skip ---
        if strcmp(taskName, 'Lexical Delay')
            targetDirName = 'LexicalDecRepDelay';
        else
            targetDirName = 'LexicalDecRepNoDelay';
        end
        
        workingDir = fullfile(resultsRoot, targetDirName, subName);
        
        % If trialInfo.mat already exists in the target folder, SKIP this task
        if exist(fullfile(workingDir, 'trialInfo.mat'), 'file')
            fprintf('  > Skipping Task: %s (trialInfo.mat already exists in target)\n', taskName);
            continue; 
        end
        
        % Check if the Task Folder exists in source
        if exist(taskBasePath, 'dir')
            
            % --- UPDATE 1: Handle subfolders in 'All Blocks' ---
            baseAllBlocks = fullfile(taskBasePath, 'All Blocks');
            realSourceDir = findSourceDirectory(baseAllBlocks);
            
            if ~isempty(realSourceDir)
                fprintf('  > Processing Task: %s\n', taskName);
                fprintf('    Source: %s\n', realSourceDir);
                
                % Create destination folder if it doesn't exist
                if ~exist(workingDir, 'dir')
                    mkdir(workingDir);
                    fprintf('    Created destination folder: %s\n', workingDir);
                end
                
                try
                    % --- Step B: Copy Files (From found Source -> Destination) ---
                    
                    % 1. Identify and Copy the correct .mat file
                    copyBestMatFile(realSourceDir, workingDir);
                    
                    % 2. Copy all .wav files
                    wavFiles = dir(fullfile(realSourceDir, '*.wav'));
                    if ~isempty(wavFiles)
                        for w = 1:length(wavFiles)
                            srcWav = fullfile(realSourceDir, wavFiles(w).name);
                            copyfile(srcWav, workingDir);
                        end
                        fprintf('    Copied %d .wav files to destination.\n', length(wavFiles));
                    else
                        warning('    No .wav files found in source!');
                    end
                    
                    % --- Step C: Rename Files inside Destination ---
                    renameWavFiles(workingDir);
                    
                    % --- Step D: Run Processing ---
                    cd(workingDir);
                    
                    fprintf('    Running combine_wavs in destination folder...\n');
                    try
                        combine_wavs; 
                        fprintf('    combine_wavs executed successfully.\n');
                    catch ME
                        warning('    Error running combine_wavs: %s', ME.message);
                    end
                    
                catch ME
                    fprintf('    Error processing subject %s: %s\n', subName, ME.message);
                end
            else
                % Warn if 'All Blocks' or valid files are missing
                 % Only warn if the task folder itself existed but All Blocks was empty/missing
                 warning('    "All Blocks" folder not found or empty in %s', taskBasePath);
            end
        end
    end
end

%% ---------------------------------------------------------
%  Helper: Find Actual Source Directory (Handles Subfolders)
%  ---------------------------------------------------------
function validDir = findSourceDirectory(baseDir)
    validDir = '';
    
    if ~exist(baseDir, 'dir')
        return;
    end
    
    % Check 1: Are files directly in 'All Blocks'?
    wavs = dir(fullfile(baseDir, '*.wav'));
    if ~isempty(wavs)
        validDir = baseDir;
        return;
    end
    
    % Check 2: Are files in a subfolder? (e.g., D134/All Blocks/Session1)
    subItems = dir(baseDir);
    dirFlags = [subItems.isdir];
    subFolders = subItems(dirFlags);
    
    for k = 1:length(subFolders)
        currSub = subFolders(k).name;
        if strcmp(currSub, '.') || strcmp(currSub, '..')
            continue;
        end
        
        testPath = fullfile(baseDir, currSub);
        % Check if this subfolder contains wav files
        wavsInSub = dir(fullfile(testPath, '*.wav'));
        if ~isempty(wavsInSub)
            validDir = testPath;
            return; % Found it, return immediately
        end
    end
end

%% ---------------------------------------------------------
%  Helper: Identify and Copy Best .mat File
%  ---------------------------------------------------------
function copyBestMatFile(sourceDir, destDir)
    matFiles = dir(fullfile(sourceDir, '*TrialData*.mat'));
    if isempty(matFiles)
        matFiles = dir(fullfile(sourceDir, '*.mat'));
    end
    
    bestFile = '';
    
    if length(matFiles) == 1
        bestFile = matFiles(1).name;
    elseif length(matFiles) > 1
        % Multiple files: find highest block number
        maxBlock = -1;
        bestIdx = -1;
        
        for k = 1:length(matFiles)
            bTokens = regexp(matFiles(k).name, '[Bb]lock_?(\d+)', 'tokens');
            if ~isempty(bTokens)
                bNum = str2double(bTokens{1}{1});
                if bNum > maxBlock
                    maxBlock = bNum;
                    bestIdx = k;
                end
            end
        end
        
        if bestIdx ~= -1
            bestFile = matFiles(bestIdx).name;
            fprintf('    Selected MAT (Block %d): %s\n', maxBlock, bestFile);
        else
            warning('    Multiple .mat files found but no block number identified. Skipping MAT copy.');
            return;
        end
    end
    
    if ~isempty(bestFile)
        src = fullfile(sourceDir, bestFile);
        dst = fullfile(destDir, 'trialInfo.mat');
        copyfile(src, dst);
        fprintf('    Copied and Renamed: %s -> trialInfo.mat\n', bestFile);
    else
        warning('    No .mat file found in source.');
    end
end

%% ---------------------------------------------------------
%  Helper: Rename WAV Files (In Destination Only)
%  ---------------------------------------------------------
function renameWavFiles(targetDir)
    % Look for wav files in the target directory
    wavFiles = dir(fullfile(targetDir, '*.wav'));
    
    for k = 1:length(wavFiles)
        currentName = wavFiles(k).name;
        
        % Skip if already processed (or is the result file)
        if strcmp(currentName, 'allblocks.wav')
            continue;
        end
        
        % Extract Block number
        tokens = regexp(currentName, '[Bb]lock_?(\d+)', 'tokens');
        
        if ~isempty(tokens)
            blockNum = tokens{1}{1};
            newName = sprintf('block%s.wav', blockNum);
            
            if ~strcmp(currentName, newName)
                oldPath = fullfile(targetDir, currentName);
                newPath = fullfile(targetDir, newName);
                movefile(oldPath, newPath);
            end
        end
    end
    fprintf('    Wav file renaming complete.\n');
end