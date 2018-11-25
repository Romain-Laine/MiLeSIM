clear all;
close all;
clc

% Cross-validation
Fold_for_CV = 5; % number of fold for cross-validation
Save_data = 1;

% Model parameters
% Kernel_functions = {'linear', 'gaussian'};
% Kernel_function = 'gaussian';
Kernel_functions = {'Random forest'};

% KernelScale = 2;
% KernelScale = 'auto';
% BoxConstraint = 3;
% Coding = 'onevsone';

% Model parameters
MaxNumSplits = 6000;
NumLearningCycles = 60;

% Options
Remove_unknown = 0;


%%
% Read in virus data with learners and classifiers

Default_path = 'C:\Users\rfl30\DATA raw\SIM data\';
[Filename, Filepath] = uigetfile('*.xlsx','File Selector',Default_path);

tic
disp('------------------------------');
disp('Reading data from spreadsheet...');
disp(fullfile(Filepath, Filename));
[Learners_values, annotation, ~] = xlsread(fullfile(Filepath, Filename),1);
Learners_names = annotation(1,1:end-1);
annotation = annotation(2:end,end);
Learners_values = Learners_values(:,1:end);
toc


%% Remove the labelled unknown from the annotations

if Remove_unknown == 1
    % Remove all unknown data points           --> not sure about doing this
    inds = ~strcmp(annotation,'Unknown');
    Learners_values = Learners_values(inds,:);
    annotation = annotation(inds);
end

Class_list = unique(annotation);
n_classes = length(Class_list);
disp(['Number of classes: ',num2str(n_classes)]);
disp('Class list:');
disp(Class_list');

n_learners = size(Learners_values,2);
disp(['Number of learners (all): ', num2str(n_learners)]);
disp('Learners list:');
disp(Learners_names);

n_examples = size(annotation,1);
disp(['Number of examples: ', num2str(n_examples)]);

%% Pick the crossvalidation partition for all of the models considered
This_partition = cvpartition(annotation,'KFold',Fold_for_CV);

% profile on
t0 = tic;
for kf = 1:length(Kernel_functions)
    disp(['-------------------- ',Kernel_functions{kf}, ' -------------------------']);
    %% Get the combinations
    All_accuracies = [];
    All_learners_combos = cell(0,n_learners);
    
    % Model parameters - Gaussian
%     Model_parameters = cell(5,1);
%     Model_parameters{1} = Kernel_functions{kf};   % Kernel function
%     Model_parameters{2} = 'auto';       % KernelScale
%     Model_parameters{3} = 1;            % BoxConstraint
%     Model_parameters{4} = 'onevsone';   % Coding
%     Model_parameters{5} = 0;            % FitPosterior

        Model_parameters{1} = MaxNumSplits;
        Model_parameters{2} = NumLearningCycles;
    
    
    if Save_data == 1
        [Filepath, Filename_wo_extension,~] = fileparts(fullfile(Filepath, Filename));
        xls_filename = fullfile(Filepath, [Filename_wo_extension,'_combinatorial results_',Kernel_functions{kf},'.xlsx']);
        line_num = 1;
        sheet_number = 1;
    end
    
    Low_list = 2:(ceil(n_learners/2)+1);
    High_list = fliplr((floor(n_learners/2)+1):n_learners);
    n_learners_used = unique(reshape(cat(1,Low_list, High_list), 1, n_learners + mod(n_learners,2)),'stable');
    
    %% for n_learners_used = 2:2
    for ni = 1:length(n_learners_used)
        
        LearnersCombinations = combnk(Learners_names, n_learners_used(ni));
%         LearnersCombinations = combnk(Learners_names, n_learners_used);

        N_combinations = size(LearnersCombinations,1);
        disp(['Number of combinations: ', num2str(N_combinations)]);
        disp(['Number of learners: ', num2str(n_learners_used(ni))]);

        Accuracies = zeros(N_combinations,1);
        %
        h_wait = waitbar(0,'Please wait the accuracies are calculated...','name','Wait bar');
        time_spent = zeros(1,N_combinations);
        for i = 1:N_combinations
            waitbar(i/N_combinations);
            tic
            disp(['------------------------------ (',num2str(i),'/',num2str(N_combinations),')']);
            disp(LearnersCombinations(i,:));
            Learners_values_selected = Learners_values(:,ismember(Learners_names, LearnersCombinations(i,:)));
           
            [ ~, Accuracy ] = GenerateModel_RandomForest( Learners_values_selected, annotation, Model_parameters, This_partition, Class_list );
            
%             [ ~, Accuracy ] = GenerateModel( Learners_values_selected, annotation, Model_parameters, This_partition, Class_list );
            Accuracies(i) = Accuracy;      
            
            toc
            time_spent(i) = toc;
        end
        
        if Save_data == 1
            if (line_num+N_combinations)>2^16-1
                sheet_number = sheet_number+1;
                line_num = 1;
            end
            
            disp('------------------------------');
            disp('Write into Excel file...');
            Combo_temp = cell(size(LearnersCombinations,1), n_learners);
            Combo_temp(1:size(LearnersCombinations,1),1:n_learners_used(ni)) = LearnersCombinations;
            xlswrite(xls_filename, cat(2,Combo_temp, num2cell(Accuracies)), sheet_number,['A' num2str(line_num)]);
            line_num = line_num+N_combinations;
        end
        
        
        disp('------------------------------------------------------------------------');
        disp(['Mean time spent per combination: ', num2str(mean(time_spent)), ' s']);
        disp('------------------------------------------------------------------------');

        %         Combo_temp_all = cell(N_combinations, n_learners);
        %         Combo_temp_all(:,1:(2 + n_learners - n_learners_used)) = LearnersCombinations;
        %         All_learners_combos = cat(1, All_learners_combos, Combo_temp_all);
        %         All_accuracies = cat(1,All_accuracies, Accuracies);
        close(h_wait);
        
        
    end
    
    %%
    
    %     All_data = cat(2,All_learners_combos, num2cell(All_accuracies));
    
    disp('----------------------------------------');
    disp('All done.');
    
end

toc(t0);

