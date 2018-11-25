%%% Matlab file that uses Support Vector Multi-class Machines to classify
%%% virus data using regions determined from images and supervised
%%% classifiers

clear all;
close all;
clc

% Cross-validation
Fold_for_CV = 5; % number of fold for cross-validation
Save_data = 1;

% Model parameters
MaxNumSplits_list = 500:500:8000;
NumLearningCycles_list = 10:5:60;

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
All_accuracies = zeros(length(MaxNumSplits_list), length(NumLearningCycles_list));

if Save_data == 1
    [Filepath, Filename_wo_extension,~] = fileparts(fullfile(Filepath, Filename));
    xls_filename = fullfile(Filepath, [Filename_wo_extension,'_optimisation results.xlsx']);
    xlswrite(xls_filename, NumLearningCycles_list, 1,'B1');
    xlswrite(xls_filename, MaxNumSplits_list', 1,'A2');
end

% profile on
t0 = tic;
h_wait = waitbar(0,'Please wait while the accuracies are calculated...','name','Wait bar');

for i = 1:length(MaxNumSplits_list)
    waitbar(i/length(MaxNumSplits_list));
    for j = 1:length(NumLearningCycles_list )
        tic
        disp('----------------------------------------');
        Model_parameters = cell(2,1);
        Model_parameters{1} = MaxNumSplits_list(i);
        Model_parameters{2} = NumLearningCycles_list(j);
        
        disp(['MaxNumSplits: ', num2str(Model_parameters{1})]);
        disp(['NumLearningCycles: ', num2str(Model_parameters{2})]);
        
        disp('Generating model...');
        [ ~, Accuracy ] = GenerateModel_RandomForest( Learners_values, annotation, Model_parameters, This_partition, Class_list );
        All_accuracies(i,j) = Accuracy;
        toc
    end
    
    if Save_data == 1
        disp('------------------------------');
        disp('Write into Excel file...');
        tic
        xlswrite(xls_filename, All_accuracies, 1,'B2');
        toc
    end
    
    
end



close(h_wait);
disp('----------------------------------------');
disp('All done.');
toc(t0);

