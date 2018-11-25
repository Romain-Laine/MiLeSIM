%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This code allows for curation of the training dataset for MiLeSIM
% Romain Laine 2016-05-25
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear all
close all
clc

% Info about classes ------------------------------------------------------
Class_list = {'Small spherical', 'Large spherical','Small filamentous', 'Filamentous', 'Rod', 'Unknown'};
% Class_list = {'Spherical', 'Large spherical','Filamentous', 'Rod' ,'Spoon', 'DoubleSpherical','Clump','Unknown'};
Save_manual_classification = 1;
FileToken = 'recon.mrc';

% User set parameters -----------------------------------------------------
Border_pixel_for_display = 25; % pixels

% Open data and display
Default_path = 'C:\Users\rfl30\DATA raw\SIM data\';
folder_name = uigetdir(Default_path, 'Please select a folder...');
listing = GetListDataset( folder_name , FileToken );


%% START THE BATCH LOOP ---------------------------------------------------

Cell_Uber_images = cell(length(listing), length(Class_list));
n_elements_in_classes = zeros(1,length(Class_list));

if Save_manual_classification == 1
    [Filepath, ~, ~] = fileparts(listing{1});
    if ~exist([Filepath,'\Annotation folder'],'dir')
        mkdir(Filepath,'Annotation folder');
    end
    
    for i = 1:length(Class_list)
        if ~exist([Filepath,'\Annotation folder\', Class_list{i}],'dir')
            mkdir([Filepath,'\Annotation folder'], Class_list{i});
        end
    end
end

for f = 1:length(listing)
    disp('------------------------------------------------------------------------------------------');
    disp(['Opening file (',num2str(f),'/',num2str(length(listing)),')']);
    FullFileName = listing{f};
    disp(FullFileName);
    imvirus = UseBF_openSIMage( FullFileName );
    
    disp('Loading the labelled image...');
    [Filepath,Filename_wo_extension,~] = fileparts(FullFileName);
    labelled_image = imread(fullfile(Filepath, [Filename_wo_extension,'_labelled image.tif']));
    n_objects = max(labelled_image (:));
    stats_objects = regionprops(labelled_image, 'Centroid');
    
    % Perform and save manual classification
    Mask = imbinarize(double(labelled_image),0.5);
    Im_composite = GenerateCompositefromMask( imvirus, Mask );
    
    disp('------------------------------');
    disp('Manual labelling...');
    Classifiers = cell(n_objects,1);
    h_Fig_left = figure('units','normalized');
    h_Fig_right = figure('units','normalized');
    
    %% Classify manually
    for i = 1:n_objects
        
        img_composite_ROI = CropOutROI_fromCentroid( Im_composite, [stats_objects(i).Centroid(1) stats_objects(i).Centroid(2)], Border_pixel_for_display );
        img_ROI = CropOutROI_fromCentroid( imvirus, [stats_objects(i).Centroid(1) stats_objects(i).Centroid(2)], Border_pixel_for_display );
        
        set(h_Fig_left, 'name', ['Object #',num2str(i), ' (with mask)']);
        set(0, 'currentfigure', h_Fig_left);
        imshow(img_ROI,[],'InitialMagnification','fit');
        title([num2str(i),'/',num2str(n_objects)]);
        % Reposition the windows
        set(h_Fig_left,'Outerposition',[0.0976 0.2362 0.3399 0.5876]);
        
        set(h_Fig_right, 'name', ['Object #',num2str(i)]);
        set(0, 'currentfigure', h_Fig_right);
        imshow(img_composite_ROI,'InitialMagnification','fit');
        title([num2str(i),'/',num2str(n_objects)]);
        % Reposition the windows
        set(h_Fig_right,'Outerposition',[0.5637 0.2390 0.3405 0.5848]);
        
        [Selection,ok] = listdlg('PromptString','Select a class:','SelectionMode','single','ListString',Class_list, 'name',['Object #',num2str(i)]);
        Classifiers(i) = Class_list(Selection);
        
        if Save_manual_classification == 1
            
            FileName_save = fullfile(Filepath,'Annotation folder',Classifiers{i},[Filename_wo_extension,'_', Classifiers{i}, '_Obj', num2str(i),'.tif']);
            mask = ismember(labelled_image, i);
            [Boxed_image, ~ ] = GetBoxedObject( imvirus, mask );
            imwrite(uint16(Boxed_image), FileName_save, 'WriteMode','overwrite');
            
            FileName_save = fullfile(Filepath,'Annotation folder',Classifiers{i},[Filename_wo_extension,'_Mask_', Classifiers{i}, '_Obj', num2str(i),'.tif']);
            [Boxed_image_mask, ~ ] = GetBoxedObject( mask, mask );
            imwrite(uint16(Boxed_image_mask), FileName_save, 'WriteMode','overwrite'); 
        end
        
    end
    close(h_Fig_left);
    close(h_Fig_right);
    
    %% Save the classification in xls
    if Save_manual_classification == 1
        xls_filename = fullfile(Filepath, [Filename_wo_extension,'_classes.xlsx']);
        xlswrite(xls_filename, Classifiers);       
    end
    
    % Counting the total number of elements in each class
    for i = 1:length(Class_list)
        n_elements_in_classes(i) = n_elements_in_classes(i) + sum(strcmp(Classifiers , Class_list(i)));
        mask_Class = ismember(labelled_image, find(strcmp(Classifiers,Class_list(i))));
        Uber_image_class = GetUberImage( imvirus, mask_Class , Border_pixel_for_display, 0);
        Cell_Uber_images{f,i} = Uber_image_class;
        
        if Save_manual_classification == 1
            disp('------------------------------');
            FileName_save = fullfile(Filepath,'Annotation folder',[Filename_wo_extension,'_', Class_list{i}, '_uber image.tif']);
            disp('Saving Uber image...');
            imwrite(Cell_Uber_images{f,i}, FileName_save,'WriteMode','overwrite');
        end
        
    end
    
    %% If the descriptors have been extracted then save as a separate xls
    Learners_filename = fullfile(Filepath, [Filename_wo_extension,'_learners.xlsx']);
    if exist(Learners_filename,'file') == 2
        [Learners_values, Learners_name, ~] = xlsread(Learners_filename ,1);
        n_learners = size(Learners_values,2);
        
        xls_filename_with_classes = fullfile(Filepath, [Filename_wo_extension,'_learners_with_classes.xlsx']);
        xlswrite(xls_filename_with_classes, cat(2, Learners_name, 'Class'),1,'A1');
        xlswrite(xls_filename_with_classes, Learners_values, 1 ,'A2');
        xlswrite(xls_filename_with_classes, Classifiers, 1 , nn2an(2,n_learners+1));
    end
    
end

%% Display and save results from the manual annotation

fractions = 100*n_elements_in_classes/sum(n_elements_in_classes);
for i = 1:length(Class_list)
    disp(['Number of ',Class_list{i},': ',num2str(n_elements_in_classes(i)),' (',num2str(fractions(i)),'%)']);
    
%     figure('Color','white','name',Class_list{i});
%     for f = 1:length(listing)
%         subplot(1,length(listing),f)
%         imshow(Cell_Uber_images{f,i},[]);
%     end
end

disp('------------------------------------------------------------------------------------------');
disp('All done.');



