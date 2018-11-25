%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This code performs the data augmentation of the training dataset
% Romain Laine 2016-05-25
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear all
close all
clc

Save_ON = 1;
FileToken = 'recon.mrc';

n_iter = 10;
Smooth_factor = 1;

% Number of duplicates
n_duplicates = 0;

% User set parameters -----------------------------------------------------
Border_pixel_for_display = 25; % pixels

% Pre-trained neural network parameters
NetParam = cell(2,1);
NetParam{1} = alexnet;
NetParam{2} = 'fc7'; % fully connected layer

% Open data and display
Default_path = 'C:\Users\rfl30\DATA raw\SIM data\';
folder_name = uigetdir(Default_path, 'Please select a folder...');
listing = GetListDataset( folder_name, FileToken );

% profile on
t0 = tic;
%% START THE BATCH LOOP ---------------------------------------------------

All_Learners_values = [];
All_annotations = [];

disp('------------------------------');
disp('Appending learners and classifiers...');
First_object_pos = zeros(1,length(listing)+1);

for f = 1:length(listing)
    
    disp('------------------------------------------------------------------------------------------');
    disp(['Opening file (',num2str(f),'/',num2str(length(listing)),')']);
    FullFileName = listing{f};
    disp(FullFileName);
    [Filepath,Filename_wo_extension,~] = fileparts(FullFileName);
    
    % Read of the learners and annotations
    [Learners_values_temp, annotations_temp, ~] = xlsread(fullfile(Filepath, [Filename_wo_extension,'_learners_with_classes.xlsx']),1);
    Learners_names = annotations_temp(1,2:(end-1));
    annotations_temp = annotations_temp(2:end,end);
    Learners_values_temp = Learners_values_temp(:, 2:end);
    
    All_Learners_values = cat(1, All_Learners_values, Learners_values_temp );
    All_annotations = cat(1, All_annotations, annotations_temp );
    
    disp(['Number of objects: ',num2str(length(annotations_temp))]);
    First_object_pos(f+1) = First_object_pos(f) + length(annotations_temp);
    
end

disp('------------------------------');
First_object_pos(end) = [];

%% Save the uber excel spreasheet

n_learners = length(Learners_names);

if Save_ON == 1
    disp('------------------------------');
    disp('Saving excel file...');
    xls_filename = fullfile(Filepath, 'All_learners_with classes.xlsx');
    xlswrite(xls_filename, cat(2, Learners_names, 'Class'),1,'A1');
    xlswrite(xls_filename, All_Learners_values, 1 ,'A2');
    xlswrite(xls_filename, All_annotations, 1 , nn2an(2,n_learners+1));
end

% Get the numbers in each class
Class_list = unique(All_annotations);
n_elements_in_classes = zeros(1,length(Class_list));
for i = 1:length(Class_list)
    n_elements_in_classes(i) = n_elements_in_classes(i) + sum(strcmp(All_annotations , Class_list(i)));
end

% Display results from the manual annotation
fractions = 100*n_elements_in_classes/sum(n_elements_in_classes);
for i = 1:length(Class_list)
    disp(['Number of ',Class_list{i},': ',num2str(n_elements_in_classes(i)),' (',num2str(fractions(i)),'%)']);
end


%% Get started on duplicating data -----------------------------------------------------------------------------

if n_duplicates > 0
    disp('------------------------------');
    disp('Duplicating data...');
    
    if Save_ON == 1
        [Filepath, ~, ~] = fileparts(listing{1});
        if ~exist([Filepath,'\Annotation folder'],'dir')
            mkdir(Filepath,'Annotation folder');
        end
        
        for i = 1:length(Class_list)
            if ~exist([Filepath,'\Annotation folder\', Class_list{i}],'dir')
                mkdir([Filepath,'\Annotation folder'], Class_list{i});
            end
            if ~exist([Filepath,'\Annotation folder\', Class_list{i},'\Duplicates'],'dir')
                mkdir([Filepath,'\Annotation folder\', Class_list{i}],'Duplicates');
            end
        end
    end
    
    
    Duplicated_Learners = [];
    Duplicated_annotations = [];
    Cell_Uber_images = cell(length(listing), length(Class_list));
    
    for f = 1:length(listing)
        
        disp('------------------------------------------------------------------------------------------');
        disp(['Opening file (',num2str(f),'/',num2str(length(listing)),')']);
        FullFileName = listing{f};
        disp(FullFileName);
        imvirus = UseBF_openSIMage( FullFileName );
        
        disp('Loading the labelled image...');
        [Filepath,Filename_wo_extension,~] = fileparts(FullFileName);
        labelled_image = imread( fullfile(Filepath, [Filename_wo_extension,'_labelled image.tif']));
        n_objects = double(max(labelled_image (:)));
        stats_objects = regionprops(labelled_image, 'Centroid');
        disp(['Number of objects: ',num2str(n_objects)]);
        
        Mask = imbinarize(double(labelled_image),0.5);
        Im_composite = GenerateCompositefromMask( imvirus, Mask );
        figure;
        imshow(Im_composite);
        
        %     h_image = figure;
        %     h_mask = figure;
        Panel_size = ceil(sqrt(n_objects));
        
        h_wait = waitbar(0,'Please wait while the duplicates are calculated...','name','Wait bar');
        
        for i = 1:n_objects
            waitbar(i/n_objects);
            Duplicated_Learners = cat(1, Duplicated_Learners, All_Learners_values(First_object_pos(f)+i,:));
            ThisObject_annotation = All_annotations(First_object_pos(f)+i);
            Duplicated_annotations = cat(1, Duplicated_annotations, ThisObject_annotation);
            
            mask_temp = ismember(labelled_image, i);
            [Boxed_image_raw, Boxed_mask_raw ] = GetBoxedObject( imvirus, mask_temp );
            
            if Save_ON == 1
                FileName_save = fullfile(Filepath,'Annotation folder',ThisObject_annotation{1},[Filename_wo_extension,'_', ThisObject_annotation{1}, '_Obj', num2str(i),'.tif']);
                imwrite(uint16(Boxed_image_raw), FileName_save, 'WriteMode','overwrite');
                
                FileName_save = fullfile(Filepath,'Annotation folder',ThisObject_annotation{1},[Filename_wo_extension,'_Mask_', ThisObject_annotation{1}, '_Obj', num2str(i),'.tif']);
                [Boxed_image_mask_to_save, ~ ] = GetBoxedObject( mask_temp, mask_temp );
                imwrite(uint16(Boxed_image_mask_to_save), FileName_save, 'WriteMode','overwrite');
            end
            
            
            for j = 1:n_duplicates
                waitbar((j+(i-1)*n_duplicates)/(n_objects*n_duplicates));
                
                Angle = 360*rand(1);  % in degrees
                Boxed_image = imrotate(Boxed_image_raw, Angle, 'bicubic', 'crop');
                Boxed_mask = imrotate(Boxed_mask_raw, Angle, 'bicubic', 'crop' );
                
                Vector = rand(1,2);  % in fraction of pixels
                Boxed_image = imtranslate(Boxed_image, Vector, 'cubic');
                Boxed_mask = imtranslate(Boxed_mask, Vector, 'cubic');
                
                FlipON = round(rand(2,1));  % random flip
                if FlipON(1)
                    Boxed_image  = flipud(Boxed_image);
                    Boxed_mask  = flipud(Boxed_mask);
                end
                
                if FlipON(2)
                    Boxed_image = fliplr(Boxed_image);
                    Boxed_mask = fliplr(Boxed_mask);
                end
                
                %         tic
                Mask_ac = double(activecontour(Boxed_image, Boxed_mask, n_iter, 'Chan-Vese','SmoothFactor', Smooth_factor));
                %         toc
                
                if Save_ON == 1
                    FileName_save = fullfile(Filepath,'Annotation folder',ThisObject_annotation{1},'Duplicates',[Filename_wo_extension,'_', ThisObject_annotation{1}, '_Obj', num2str(i),'_d',num2str(j),'.tif']);
                    imwrite(uint16(Boxed_image), FileName_save, 'WriteMode','overwrite');
                    
                    FileName_save = fullfile(Filepath,'Annotation folder',ThisObject_annotation{1},'Duplicates',[Filename_wo_extension,'_Mask_', ThisObject_annotation{1}, '_Obj', num2str(i),'_d',num2str(j),'.tif']);
                    imwrite(uint16(Mask_ac), FileName_save, 'WriteMode','overwrite');
                    
                end
                
                [ learners_value, ~ ] = ExtractAllParameters( Boxed_image, Mask_ac, NetParam );
                learners_value(1) = [];
                
                %             set(0, 'currentfigure', h_image);
                %             subplot(Panel_size,Panel_size,i)
                %             imshow(Boxed_image, []);
                %
                %             set(0, 'currentfigure', h_mask);
                %             subplot(Panel_size,Panel_size,i)
                %             imshow(Mask_ac, []);
                
                Duplicated_Learners = cat(1, Duplicated_Learners, learners_value);
                Duplicated_annotations = cat(1, Duplicated_annotations, ThisObject_annotation);
            end
        end
        
        
        
        close(h_wait);
        
    end
    
    %%
    if Save_ON == 1
        xls_filename = fullfile(Filepath, 'All_learners_with classes_with_duplicates.xlsx');
        xlswrite(xls_filename, cat(2, Learners_names, 'Class'),1,'A1');
        xlswrite(xls_filename, Duplicated_Learners, 1 ,'A2');
        xlswrite(xls_filename, Duplicated_annotations, 1 , nn2an(2,n_learners+1));
    end
end


disp('------------------------------------------------------------------------------------------');
disp('All done.');
toc(t0);

% profile viewer


