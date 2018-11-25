function [trainedClassifier, validationAccuracy] = GenerateModel_TreeBagger(Learners_values, Labels, Model_parameters, partition_for_CV)

NumTrees = Model_parameters{1};
NumPredictorsToSample = Model_parameters{2};

trainedClassifier = TreeBagger(NumTrees,Learners_values,Labels, 'NumPredictorsToSample', NumPredictorsToSample);

% Perform cross-validation
partitionedModel = crossval(trainedClassifier, 'CVpartition', partition_for_CV);

% Compute validation accuracy
validationAccuracy = 1 - kfoldLoss(partitionedModel, 'LossFun', 'ClassifError');
disp(['Accuracy: ',num2str(100*validationAccuracy,'%.1f'),' %']);

end


