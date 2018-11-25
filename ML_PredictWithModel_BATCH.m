%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This file automatically performs classification on dataset in a folder, using the SVM model selected.
% The particles classified with low confidence (low posterior probability) are classified as "unknown".
% Results are saved in a separate folder in the data folder: individual uberimages and annotated image.
% 2016-07-07 Romain Laine rfl30@cam.ac.uk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Initialization
clear all;
close all;
clc

% User-set parameters -----------------------------------------------------
Border_pixel = 25;      % pixels
min_probability = 0.55; % any label with lower posterior probability lower than this will be labelled as "Unknown"
Save_results = 1;
Display_on = 0;
FileToken = 'recon.mrc'; % to recognize the files to analyse

% -------------------------------------------------------------------------

% Load the SVM model
disp('------------------------------');
Default_path = 'C:\Users\rfl30\DATA raw\SIM data\';
[Filename_model, Filepath_model] = uigetfile('*.mat','Load SVM model...',Default_path);
disp('Reading model in...');
loadedSVMModel = load(fullfile(Filepath_model, Filename_model)); % load a presaved model
loadedSVMModel = loadedSVMModel.SVMModel;

% Add unknown to the class list
Class_list = cat(1, loadedSVMModel.ClassNames, {'Unknown'});
n_classes = length(Class_list);

% Get the list of learners used in the particular model loaded here
Selected_learners_in_model = loadedSVMModel.PredictorNames;

%% --------------------------------------------------------------------------------------------------------------------------------------

% Choose folder to analyse
Default_path = 'C:\Users\rfl30\DATA raw\SIM data\';
listing = GetListDataset( Default_path, FileToken );
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

t0 = tic;
for f = 1:length(listing)
    
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
    [~,Filename_wo_extension,~] = fileparts(FullFileName);
    All_filenames_for_save{f} = Filename_wo_extension;
    
    disp('Loading the learners from spreadsheet...');
    [Learners_values, annotation, ~] = xlsread(fullfile(Filepath, [Filename_wo_extension,'_learners.xls']),1);
    % Extract information from the xls file
    Learners_name = annotation(1,2:end);
    Learners_values = Learners_values(:,2:end);
    % Select the learners that were used in the model
    
    if ~isempty(Learners_values) % catch cases where no particles were detected
        Learners_values_selected = Learners_values(:,ismember(Learners_name, Selected_learners_in_model));
        
        % Handle problems with learners list
        if length(Selected_learners_in_model) ~= size(Learners_values_selected,2)
            disp('Incompatibility between list of learners in the model and list of learners extracted from the file (in .xls file).');
            return;
        end
        
        % Load the labelled mask
        disp('Loading the labelled mask...');
        labelled_image = imread( fullfile(Filepath, [Filename_wo_extension,'_labelled image.tif']));
        object_props = regionprops(labelled_image,'Centroid');
        
        tic
        disp('------------------------------');
        disp('Running prediction...');
        [labels, ~, ~, Posterior_probability] = predict(loadedSVMModel, Learners_values_selected);
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
            text(object_props(i).Centroid(1), object_props(i).Centroid(2), [' ', labels(i)], 'Color', 'r');
        end
        hold off
        % ------------------------------------------------------------------
        
        % Save the labelled image ------------------------------------------
        if Save_results == 1
            % Save annotated image
            Annotated_filename = fullfile(Filepath, Prediction_folder_name, [Filename_wo_extension, '_annotated.png']);
            saveas(h_labelled_image, Annotated_filename, 'png');
            % Save the predicted labels
            xls_filename = fullfile(Filepath, Prediction_folder_name, [Filename_wo_extension, '_predicted classes.xls']);
            xlswrite(xls_filename, labels,1,'A1');
        end
        
        % Close the image if not wanted
        if Display_on == 0
            close(h_labelled_image);
        end
        
        % Get the number of elements in each class from that particular image
        nElement_in_class = zeros(1, n_classes);
        for i = 1:n_classes
            nElement_in_class(i) = sum(strcmp(labels, Class_list(i)));
        end
        n_virus_inclass(f,:) = nElement_in_class;
        
        % Show and save Uber_images
        [Uber_image, ~] = GetUberImage( imvirus, labelled_image , Border_pixel, 0);
        for i = 1:n_classes
            if nElement_in_class(i)>0
                SelectedLabelled_matrix = CreateSelectedLabelled_matrix( labelled_image, labels, Class_list(i));
                BW_in = imbinarize(double(SelectedLabelled_matrix),0.5);
                [Uber_image, ~] = GetUberImage( imvirus, BW_in, Border_pixel, 0 );
                
                if Display_on == 1
                    figure('name',['Uber image: ', Class_list{i}]);
                    imshow(Uber_image);
                    title(Class_list{i});
                end
                
                if Save_results == 1
                    Class_filename = fullfile(Filepath, Prediction_folder_name, [ Class_list{i},'_', Filename_wo_extension, '_uberimage.tif']);
                    imwrite(Uber_image, Class_filename,'WriteMode','overwrite');
                end
            end
            
            % Display results
            disp('------------------------------');
            disp([Class_list{i}, ':']);
            disp(['Number of objects: ', num2str(nElement_in_class(i)), ' (', num2str(100*nElement_in_class(i)/length(labels), '%.2f'),'%)']);
        end
    end % end of (if ~isempty(Learners_values))
    
end


%% Display results from the complete dataset

disp('-------------------------------------------------------------------------------');
n_virus_tot = sum(n_virus_inclass); % vector with virus numbers in each class
disp(['Total number of viruses analysed: ',num2str(sum(n_virus_tot))]);
disp(['Number of FOV analysed: ',num2str(length(listing))]);

for i = 1:n_classes
    % Display results
    disp('----------------------------------------------------------');
    disp([Class_list{i}, ':']);
    disp(['Number of objects: ', num2str(n_virus_tot(i)), ' (', num2str(100*n_virus_tot(i)/sum(n_virus_tot), '%.2f'),'%)']);
    
end

if Save_results == 1
    AllResults_xls_filename = fullfile(Filepath, Prediction_folder_name, ['All results using ', ModelName_wo_extension, '.xls']);
    xlswrite(AllResults_xls_filename, cat(2,'File name', Class_list'),1,'A1');
    xlswrite(AllResults_xls_filename, All_filenames_for_save,1,'A2');
    xlswrite(AllResults_xls_filename, n_virus_inclass,1,'B2');
end


disp('---------------');
disp('All done.');
toc(t0);





