

% Initialization
clear all;
close all;
clc

% User-set parameters -----------------------------------------------------
Border_pixel = 25;      % pixels
min_probability = 0.55; % any label with posterior probability lower than this will be labelled as "Unknown"
Save_results = 0;

% -------------------------------------------------------------------------

% Load the RF model
disp('------------------------------');
Default_path = 'C:\Users\rfl30\DATA raw\SIM data\';
[Filename_model, Filepath_model] = uigetfile('*.mat','Load RF model...',Default_path);
disp('Reading model in...');
loadedRF_Model = load(fullfile(Filepath_model, Filename_model)); % load a presaved model
loadedRF_Model = loadedRF_Model.trainedClassifier;

% Add unknown to the class list
Class_list = unique(cat(1, loadedRF_Model.ClassificationEnsemble.ClassNames, {'Unknown'}));
% Get the list of learners used in the particular model loaded here
Selected_learners_in_model = loadedRF_Model.ClassificationEnsemble.PredictorNames;

%% --------------------------------------------------------------------------------------------------------------------------------------

% Read in image file which you would like to predict classes
Default_path = 'C:\Users\rfl30\DATA raw\SIM data\';
[Filename, Filepath, FilterIndex] = uigetfile({'*.mrc';'*.tif'},'Choose a SIMage file...',Default_path);
FullFileName = fullfile(Filepath, Filename);

disp('------------------------------');
disp('Reading image virus...');
if FilterIndex == 1
    disp('Opening data using bio-format...');
    imvirus = UseBF_openSIMage( FullFileName );
elseif FilterIndex == 2
    disp('Opening data using imread...');
    imvirus = double(imread( FullFileName ));
end

figure('name','Initial image');
imshow(imvirus,[]);

%%

disp('------------------------------');
% Get the filename without the extension
[Filepath,Filename_wo_extension,~] = fileparts(FullFileName);

disp('Loading the learners from spreadsheet...');
[Learners_values, annotation, ~] = xlsread(fullfile(Filepath, [Filename_wo_extension,'_learners.xlsx']),1);
% Extract information from the xls file 
Learners_name = annotation(1,2:end);
Learners_values = Learners_values(:,2:end);
% Select the learners that were used in the model
Learners_values_selected = Learners_values(:,ismember(Learners_name, Selected_learners_in_model));

% Handle problems with learners list
if length(Selected_learners_in_model) ~= size(Learners_values_selected,2)
    disp('Incompatibility between list of learners in the model and list of learners extracted from the file (in .xls file).');
    return;
end

disp('Loading the labelled mask...');
labelled_image = imread( fullfile(Filepath, [Filename_wo_extension,'_labelled image.tif']));
object_props = regionprops(labelled_image,'Centroid');

tic
disp('------------------------------');
disp('Running prediction...');
[labels, Posterior_probability] = predict(loadedRF_Model.ClassificationEnsemble, Learners_values_selected);
% labels = predict(loadedSVMModel, Learners_values);
toc

% Get the labels that were determined with cnfidence and set others to unknown
labels = GetConfidentPredictions( Posterior_probability, labels, min_probability );

disp(' ');
disp('List of labels:');
disp(labels);

% Produce figure that has image and labels -------------------------
h_labelled_image = figure('name','Image with labelled predicted classes','Color','white');
imshow(imvirus,[]);
axis image
hold on
for i = 1:length(labels)
    plot(object_props(i).Centroid(1), object_props(i).Centroid(2), 'r+')
    text(object_props(i).Centroid(1), object_props(i).Centroid(2), [' ', char(labels(i))], 'color', 'r');
end
hold off
% ------------------------------------------------------------------

%% Create a directory for the results of the prediction -------------
if Save_results == 1
    [~,ModelName_wo_extension,~] = fileparts(Filename_model);
    Prediction_folder_name = ['Prediction results using ', ModelName_wo_extension];
    mkdir(Filepath,Prediction_folder_name);
    Annotated_filename = fullfile(Filepath, Prediction_folder_name, [Filename_wo_extension, '_annotated.png']);
    saveas(h_labelled_image, Annotated_filename, 'png');
end

% Get the number of elements in each class from that particular image
n_viruses = length(labels);
n_classes = length(Class_list);
nElement_in_class = zeros(n_classes, 1);
for i = 1:n_classes
    nElement_in_class(i) = sum(labels == Class_list(i));
end

% Show and save Uber_images
[Uber_image, ~] = GetUberImage( imvirus, labelled_image , Border_pixel, 1);
for i = 1:n_classes
    
    if nElement_in_class(i)>0
        SelectedLabelled_matrix = CreateSelectedLabelled_matrix( labelled_image, labels, Class_list(i));
        BW_in = imbinarize(double(SelectedLabelled_matrix),0.5);
        [Uber_image, ~] = GetUberImage( imvirus, BW_in, Border_pixel, 0 );
        
        figure('name',['Uber image: ', char(Class_list(i))]);
        imshow(Uber_image);
        title(char(Class_list(i)));
        
        if Save_results == 1
            Class_filename = fullfile(Filepath, Prediction_folder_name, [ Class_list(i),'_', Filename_wo_extension, '_uberimage.tif']);
            imwrite(Uber_image, Class_filename,'WriteMode','overwrite');
        end
        
    end
    
    % Display results
    disp('------------------------------');
    disp([Class_list(i), ':']);
    disp(['Number of objects: ', num2str(nElement_in_class(i)), ' (', num2str(100*nElement_in_class(i)/n_viruses, '%.2f'),'%)']);
    
end

