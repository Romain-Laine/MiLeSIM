%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This file automatically performs classification on dataset in a folder, using the RF model selected.
% The particles classified with low confidence (low posterior probability) are classified as "unknown".
% Results are saved in a separate folder in the data folder: individual uberimages and annotated image.
% 2017-09-06 Romain Laine rfl30@cam.ac.uk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Initialization
clear all;
close all;
clc

% User-set parameters -----------------------------------------------------
Border_pixel = 25;      % pixels
min_probability = 0.35; % any label with posterior probability lower than this will be labelled as "Unknown"
Save_results = 1;
Display_on = 0;
FileToken = 'recon.mrc'; % to recognize the files to analyse

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
n_classes = length(Class_list);

%% --------------------------------------------------------------------------------------------------------------------------------------

% Read in image file which you would like to predict classes
Default_path = 'C:\Users\rfl30\DATA raw\SIM data\';
folder_name = uigetdir(Default_path, 'Please select a folder...');

listing = GetListDataset( folder_name, FileToken );
[Filepath,~,~] = fileparts(listing{1});
disp('File path selected:');
disp(Filepath);

% Create the folder to save the results in if results are saved
if Save_results == 1
    [~,ModelName_wo_extension,~] = fileparts(Filename_model);
    Prediction_folder_name = ['Prediction results using ', ModelName_wo_extension];
    mkdir(Filepath,Prediction_folder_name);
end


%% START THE BATCH LOOP ---------------------------------------------------


n_virus_inclass = zeros(length(listing), n_classes);
All_filenames_for_save = cell(length(listing),1);
All_labels = {};
AllPosterior_probability = [];
n_position_in_sheet = 2;



t0 = tic;
%%
for f = 1:length(listing)
    tic
    disp('------------------------------------------------------------------------------------------');
    disp(['Opening file (',num2str(f),'/',num2str(length(listing)),')']);
    FullFileName = listing{f};
    disp(FullFileName);
    imvirus = UseBF_openSIMage( FullFileName );
    
    if Display_on == 1
        figure('name','Initial image');
        imshow(imvirus,[]);
    end
    
    
    disp('------------------------------');
    % Get the filename without the extension
    % [Filepath,Filename_wo_extension,~] = fileparts(FullFileName);
    [~,Filename_wo_extension,~] = fileparts(FullFileName);
    All_filenames_for_save{f} = Filename_wo_extension;
    
    
    disp('Loading the learners from spreadsheet...');
    [Learners_values, annotation, ~] = xlsread(fullfile(Filepath, [Filename_wo_extension,'_learners.xlsx']),1);
    % Extract information from the xls file
    Learners_name = annotation(1,2:end);
    Learners_values = Learners_values(:,2:end);
    
    if f == 1
        if Save_results == 1
            xls_filename_all = fullfile(Filepath, Prediction_folder_name, 'All_predicted classes.xlsx');
            xlswrite(xls_filename_all, cat(2, Learners_name, 'Class'),1,'A1');
        end
    end
    
    
    if ~isempty(Learners_values) % catch cases where no particles were detected
        
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
        
        AllPosterior_probability = cat(1, AllPosterior_probability, Posterior_probability);
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
            Annotated_filename = fullfile(Filepath, Prediction_folder_name, [Filename_wo_extension, '_annotated.png']);
            saveas(h_labelled_image, Annotated_filename, 'png');
            % Save the predicted labels
            xls_filename = fullfile(Filepath, Prediction_folder_name, [Filename_wo_extension, '_predicted classes.xlsx']);
            xlswrite(xls_filename, cellstr(labels),1,'A1');
            All_labels = cat(1,All_labels, labels);
            
            xlswrite(xls_filename_all, Learners_values,1, ['A', num2str(n_position_in_sheet)]);
            xlswrite(xls_filename_all, cellstr(labels), 1 , nn2an(n_position_in_sheet, length(Learners_name)+1));
            n_position_in_sheet = n_position_in_sheet + size(Learners_values,1);
        end
        
        % Close the image if not wanted
        if Display_on == 0
            close(h_labelled_image);
        end
        
        % Get the number of elements in each class from that particular image
        nElement_in_class = zeros(1, n_classes);
        for i = 1:n_classes
            nElement_in_class(i) = sum(labels == Class_list(i));
        end
        n_virus_inclass(f,:) = nElement_in_class;
        
        % Show and save Uber_images
        [Uber_image, ~] = GetUberImage( imvirus, labelled_image , Border_pixel, 1);
        for i = 1:n_classes
            if nElement_in_class(i)>0
                SelectedLabelled_matrix = CreateSelectedLabelled_matrix( labelled_image, labels, Class_list(i));
                BW_in = imbinarize(double(SelectedLabelled_matrix),0.5);
                [Uber_image, ~] = GetUberImage( imvirus, BW_in, Border_pixel, 0 );
                
                if Display_on == 1
                    figure('name',['Uber image: ', char(Class_list(i))]);
                    imshow(Uber_image);
                    title(char(Class_list(i)));
                end
                
                if Save_results == 1
                    Class_filename = fullfile(Filepath, Prediction_folder_name, [ char(Class_list(i)),'_', Filename_wo_extension, '_uberimage.tif']);
                    imwrite(Uber_image, Class_filename,'WriteMode','overwrite');
                end
                
            end
            
            % Display results
            disp('------------------------------');
            disp([Class_list(i), ':']);
            disp(['Number of objects: ', num2str(nElement_in_class(i)), ' (', num2str(100*nElement_in_class(i)/length(labels), '%.2f'),'%)']);
            
        end
    end % end of (if ~isempty(Learners_values))
    toc
end


%% Display results from the complete dataset

disp('-------------------------------------------------------------------------------');
disp('-------------------------------------------------------------------------------');

n_virus_tot = sum(n_virus_inclass); % vector with virus numbers in each class
disp(['Total number of viruses analysed: ',num2str(sum(n_virus_tot))]);
disp(['Number of FOV analysed: ',num2str(length(listing))]);

for i = 1:n_classes
    % Display results
    disp('----------------------------------------------------------');
    disp([Class_list(i), ':']);
    disp(['Number of objects: ', num2str(n_virus_tot(i)), ' (', num2str(100*n_virus_tot(i)/sum(n_virus_tot), '%.2f'),'%)']);
    
end

if Save_results == 1
    AllResults_xls_filename = fullfile(Filepath, Prediction_folder_name, ['All results using ', ModelName_wo_extension, '.xlsx']);
    xlswrite(AllResults_xls_filename, cat(2,'File name', cellstr(Class_list')),1,'A1');
    xlswrite(AllResults_xls_filename, All_filenames_for_save,1,'A2');
    xlswrite(AllResults_xls_filename, n_virus_inclass,1,'B2');
    
    xlswrite(AllResults_xls_filename, cellstr(Class_list'),2,'B1');
    xlswrite(AllResults_xls_filename, cellstr(All_labels),2,'A2');
    xlswrite(AllResults_xls_filename, AllPosterior_probability,2,'B2');
end


disp('---------------');
disp('All done.');
toc(t0);


