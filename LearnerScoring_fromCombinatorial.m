close all
clear all
clc

Default_path = 'C:\Users\rfl30\DATA raw\SIM data\';
[Filename, Filepath] = uigetfile('*.xlsx','File Selector',Default_path);

tic
disp('------------------------------');
disp('Reading data from spreadsheet...');
disp(fullfile(Filepath, Filename));
[Scores, LearnersSet, ~] = xlsread(fullfile(Filepath, Filename),1);

n_combinations = length(Scores);
disp(['Number of combinations tested: ', num2str(n_combinations)]);

%%

Learners_list = unique(LearnersSet);
Learners_list(1) = [];

LearnerAverageScore = zeros(1, length(Learners_list));
NumOccurenceLearner = zeros(1, length(Learners_list));


for i = 1:n_combinations
    ThisLearnerSet = LearnersSet(i, :);
    N_learners = sum(~cellfun(@isempty, ThisLearnerSet));
    for j = 1:length(Learners_list)
        NumOccurenceLearner(j) = NumOccurenceLearner(j) + ismember(Learners_list{j}, ThisLearnerSet);
        LearnerAverageScore(j) = LearnerAverageScore(j) + Scores(i)/N_learners*ismember(Learners_list{j}, ThisLearnerSet);
    end
end


LearnerAverageScore = 100*LearnerAverageScore./NumOccurenceLearner;

%%

[SortedScores, ind ] = sort(LearnerAverageScore,'ascend');

Learners_list_for_display = Learners_list;
Learners_list_for_display{8} = 'L_1/L_2';
Learners_list_for_display{16} = 'Hu''s IM 1';
Learners_list_for_display{17} = 'Hu''s IM 4';
Learners_list_for_display{18} = 'Hu''s IM 5';
Learners_list_for_display{19} = 'Hu''s IM 6';
Learners_list_for_display{20} = '<I>';
Learners_list_for_display{21} = 'P/A';
Learners_list_for_display{22} = 'Hu''s IM \phi_4';
Learners_list_for_display{24} = '\sigma_I';


SortedLearnerNames = Learners_list_for_display(ind);



figure('color', 'white', 'name', 'Average scores');
barh(SortedScores);
set(gca,'YTick',1:24,'YTickLabel',SortedLearnerNames);
axis tight

xlim([min(SortedScores)-0.5*std(SortedScores) ...
    max(SortedScores)+0.5*std(SortedScores)]);


ylabel 'Descriptors'' name'
xlabel 'Average % score'
grid on



