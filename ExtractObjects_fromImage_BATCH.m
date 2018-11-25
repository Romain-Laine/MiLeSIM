%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This code performs image segmentation from the loaded images.
% First Otsu segmenation to get the objects, then the outline of the objects are refined by active contour.
% For each image, the code saves a labelled image (where particle masks are
% identified from 1 to N) and and 'uber-image' showing all the particles
% identified as a multipanel frame (with their masks)
% Romain Laine 2016-05-25
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear all
close all
clc

% save learners in excel --------------------------------------------------
Save_ON = 1;
Border_pixel = 25; % pixels
FileToken = 'recon.mrc';

% Folder_analysis = 'Single folder';
Folder_analysis = 'Multiple folders';  % ---> prepare the list of folders below

% User set parameters for segmentation -----------------------------------------------------
Min_size_Otsu = 25;  % pixels
Min_size_AC = 25;
Min_MeanInt_Otsu = 1000; % ADC
Min_MeanInt_AC = 500; % ADC

% For active contour ------------------------------------------------------
AC_mask_method = 'Otsu-thresholding';
% AC_mask_method = 'Bounding-box';

n_iter = 100; % number of maximum iterations
Smooth_factor = 1;

Display_MultiPanel = 0;
Display_uberimages = 1;

% -------------------------------------------------------------------------
if strcmp(Folder_analysis, 'Single folder')
    % Open data and display
    Default_path = 'C:\Users\rfl30\DATA raw\SIM data\';
    folder_name = uigetdir(Default_path, 'Please select a folder...');
    n_folders = 1;
    folder_names = {};
    folder_names{1} = folder_name;
    
elseif strcmp(Folder_analysis, 'Multiple folders')
    % Populate the folders to analyse

    folder_names{1} = 'C:\Users\rfl30\DATA raw\SIM data\2016_09_07 Influenza viruses_Romain\p1wA B Victoria';
    folder_names{2} = 'C:\Users\rfl30\DATA raw\SIM data\2016_09_07 Influenza viruses_Romain\p1wC B Yamagata';
    folder_names{3} = 'C:\Users\rfl30\DATA raw\SIM data\2016_09_07 Influenza viruses_Romain\p2wA A South Dakota';
    folder_names{4} = 'C:\Users\rfl30\DATA raw\SIM data\2016_09_07 Influenza viruses_Romain\p2wC A Bolivia';
    
    n_folders = length(folder_names);
end


for d = 1:n_folders
    listing = GetListDataset( folder_names{d}, FileToken );
    
    %% START THE BATCH LOOP ---------------------------------------------------
    
    t0 = tic;
    for f = 1:length(listing)
        
        disp('------------------------------------------------------------------------------------------');
        disp(['Opening file (',num2str(f),'/',num2str(length(listing)),')']);
        FullFileName = listing{f};
        disp(FullFileName )
        imvirus = UseBF_openSIMage( FullFileName );
        
        %     figure('name','Initial image');
        %     imshow(imvirus, []);
        
        %% Otsu-thresholding and get rid of small objects
        disp('------------------------------');
        disp('Otsu segementation...');
        level = graythresh(imvirus);
        BW = imbinarize(imvirus,level);
        BW = imclearborder(BW);
        BW_bigobjects = SieveBW( BW, imvirus, Min_size_Otsu, Min_MeanInt_Otsu, Display_MultiPanel);
        
        % Display the uber image
        [Uber_image_Otsu, ~] = GetUberImage( imvirus, BW_bigobjects, Border_pixel, Display_MultiPanel);
        
        if Display_uberimages == 1
            figure('name','Uber image with Otsu mask');
            imshow(Uber_image_Otsu, []);
        end
        
        %% Refine the objects contour with Active contour
        disp('------------------------------');
        disp('Active contour refinement...');
        BW_ac = GetLabelMatrix_usingAC(BW_bigobjects, imvirus, n_iter, Smooth_factor, AC_mask_method);
        
        %     CorrelationGraph_AreaMeanInt( BW_ac, imvirus );
        
        % Sieve by size again
        BW_ac_bigobjects = SieveBW( BW_ac, imvirus, Min_size_AC, Min_MeanInt_AC, 0 );
        [Uber_image_AC, Uber_image_mask] = GetUberImage( imvirus, BW_ac_bigobjects, Border_pixel, Display_MultiPanel);
        
        if Display_uberimages == 1
            figure('name','Uber image with AC mask');
            imshow(Uber_image_AC);
        end
        
        %% Write the mask and Uber images
        
        if Save_ON == 1
            disp('------------------------------');
            disp('Saving labelled image...');
            [Filepath,Filename_wo_extension,~] = fileparts(FullFileName);
            imwrite(uint16(bwlabel(BW_ac_bigobjects)), fullfile(Filepath, [Filename_wo_extension,'_labelled image.tif']),'WriteMode','overwrite');
            
            disp('------------------------------');
            disp('Saving Uber image...');
            imwrite(Uber_image_AC, fullfile(Filepath, [Filename_wo_extension,'_uber image.tif']),'WriteMode','overwrite');
            
        end
        
    end
end

disp('------------------------------------------------------------------------------------------');
disp('All done.');
toc(t0);

