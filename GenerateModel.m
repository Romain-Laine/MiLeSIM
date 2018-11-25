function [ SVMModel, Accuracy ] = GenerateModel( Learners_values, Labels, Model_parameters, partition_for_CV, Class_list )
%UNTITLED9 Summary of this function goes here
%   Detailed explanation goes here

Kernel_function = Model_parameters{1};
KernelScale = Model_parameters{2};
BoxConstraint = Model_parameters{3};
Coding = Model_parameters{4};
FitPosterior = Model_parameters{5};

% Fit model
template_model = templateSVM(...
    'KernelFunction', Kernel_function, ...
    'PolynomialOrder', [], ...
    'KernelScale', KernelScale, ...
    'BoxConstraint', BoxConstraint, ...
    'Standardize', true);

SVMModel = fitcecoc( Learners_values, Labels, ...
    'Learners', template_model, ...
    'Coding', Coding, ...
    'ClassNames', Class_list, ...
    'FitPosterior', FitPosterior,...
    'Verbose', 0);

%% Perform cross-validation
% options = statset('UseParallel' , true,'UseSubstreams',false, 'Streams', RandStream('mlfg6331_64')); % for parallel computing
% partitionedModel = crossval(SVMModel, 'CVpartition', partition_for_CV, 'options', options);
partitionedModel = crossval(SVMModel, 'CVpartition', partition_for_CV);

% Compute validation accuracy
Accuracy = 1 - kfoldLoss(partitionedModel, 'LossFun', 'ClassifError');
disp(['Accuracy: ',num2str(100*Accuracy,'%.1f'),' %']);


end

