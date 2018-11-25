%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 2017-08-17 Romain Laine rfl30@cam.ac.uk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Initialization
clear all;
close all;
clc

% User defined parameters -------------------------------------------------
SaveBestLearners = 1;
N_components = 6;

% LearnersType = 'AN';
LearnersType = 'BoF';

Default_path = 'C:\Users\rfl30\DATA raw\SIM data\';


%% ------------------------------------------------------------------------
% Read in virus data with learners and classifiers

[Filename, Filepath] = uigetfile('*.xlsx','Choose an annotated descriptor file...',Default_path);

tic
disp('------------------------------');
disp('Reading data from spreadsheet...');
disp(fullfile(Filepath, Filename));
[Learners_values, annotation, ~] = xlsread(fullfile(Filepath, Filename),1);
toc

% Rename variables with the data and information
Learners_names = annotation(1,1:end-1);
annotation = annotation(2:end,end);
Learners_values = Learners_values(:,1:end);
n_learners = size(Learners_values,2);
disp(['Number of learners: ', num2str(n_learners)]);

% Get the list of classes
Class_list = unique(annotation);
n_classes = length(Class_list);
disp(['Number of classes: ',num2str(n_classes)]);
disp('Class list:');
disp(Class_list);

n_examples = size(annotation,1);
disp(['Number of examples: ', num2str(n_examples)]);

CurrentLearnerName = char(0);
k = 0;
while ~contains(CurrentLearnerName,LearnersType,'IgnoreCase',false)
    k = k+1;
    CurrentLearnerName = Learners_names(k);
end

%% STD analysis for PCA selection

ANlearners = Learners_values(:,k:end);
MeanLearners = zeros(n_classes, size(ANlearners ,2));
STDLearners = zeros(n_classes, size(ANlearners ,2));

for c = 1:n_classes
    IndexC = strfind(annotation, Class_list{c});
    Index = find(not(cellfun('isempty', IndexC)));
    Temp_learners = ANlearners(Index,:);
    MeanLearners(c,:) = mean(Temp_learners);
    STDLearners(c,:) = std(Temp_learners);
end

Scores = zeros(1,size(ANlearners ,2));
for i = 1:(n_classes-1)
    Scores = Scores + sum(abs(MeanLearners - circshift(MeanLearners,i))./(STDLearners + circshift(STDLearners,i)));
end

figure('Color','white','name','Scores');
subplot(1,2,1)
plot(Scores);
axis tight
xlabel 'Learners #'
[SortedScores, idx ] = sort(Scores, 'descend');
subplot(1,2,2)
plot(SortedScores);
axis tight
xlabel 'Learners #'

%%

Best_learner_names = cell(1,N_components);
for i = 1:N_components
    Best_learner_names{i} = [LearnersType, num2str(idx(i))];
end

figure('Color','white','name','Feature histograms');
for i = 1:N_components
    subplot(ceil(sqrt(N_components)), ceil(sqrt(N_components)),i);
    for c = 1:n_classes
        IndexC = strfind(annotation, Class_list{c});
        Index = find(not(cellfun('isempty', IndexC)));
        Temp_learners = ANlearners(Index,:);
        histogram(Temp_learners(:,idx(i)),50);
        hold on
    end
%     legend(Class_list);
    hold off
    title(Best_learner_names{i});
end

subplot(ceil(sqrt(N_components)), ceil(sqrt(N_components)),N_components);
legend(Class_list);
%%


if SaveBestLearners
    
    disp('Writing to excel sheet...');
    BestANlearners = ANlearners(:,idx(1:N_components));
    NewLearners = cat(2, Learners_values(:,1:(k-1)), BestANlearners);
    
    [~, Filename_wo_extension] = fileparts(Filename);
    xls_filename_with_PCA = fullfile(Filepath, [Filename_wo_extension,'_Best ',LearnersType,' components.xlsx']);
    xlswrite(xls_filename_with_PCA, cat(2, Learners_names(1:(k-1)), Best_learner_names, 'Class'),1,'A1');
    xlswrite(xls_filename_with_PCA, NewLearners, 1 ,'A2');
    xlswrite(xls_filename_with_PCA, annotation, 1 , nn2an(2,k+N_components));
end


disp('----------------------');
disp('All done. Now go back to work.');
