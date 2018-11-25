close all
clear all
clc

SaveLearners = 1;

Default_path = 'C:\Users\rfl30\DATA raw\SIM data\';
folder_name = uigetdir(Default_path, 'Please select a folder for creating the visual words...');
ImageData = imageDatastore(folder_name, ...
    'IncludeSubfolders',true,'LabelSource','foldernames');

tbl = countEachLabel(ImageData);
disp(tbl);

minSetCount = min(tbl{:,2});
n_words = 500;

bag = bagOfFeatures(ImageData, 'VocabularySize', n_words, 'StrongestFeatures', 1, 'Upright', false );

%%
disp('Saving trained bag in folder...');
save([folder_name,'\BagOfFeatures_trained'], 'bag');

%%
folder_name = uigetdir(Default_path, 'Please select a folder to encode the words features...');
ImageData = imageDatastore(folder_name, ...
    'IncludeSubfolders',true,'LabelSource','foldernames');

AllfeatureVector = encode(bag, ImageData);

BoF_learner_names = cell(1,n_words);
for i = 1:n_words
    BoF_learner_names{i} = ['BoF', num2str(i)];
end

%%

if SaveLearners
    disp('Writing to excel...');
    tic
    xls_filename = fullfile(folder_name, '\BoF_SURF components.xlsx');
    xlswrite(xls_filename, cellstr(ImageData.Files),1,'A2');
    xlswrite(xls_filename, cat(2, BoF_learner_names, 'Class'),1,'B1');
    xlswrite(xls_filename, AllfeatureVector, 1 ,'B2');
    xlswrite(xls_filename, cellstr(ImageData.Labels), 1 , nn2an(2,n_words+2));
    toc
end

%
disp('------------------------');
disp('All done.')
