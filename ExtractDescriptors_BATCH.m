%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This code performs image segmentation and learner extraction from the loaded images.
% First Otsu segmenation to get the objects, then the outline of the objects are refined by active contour.
% The outline of the objects is used to extract learner parameters on the mask and on the intensity image.
% Romain Laine 2016-05-25
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear all
close all
clc

% save learners in excel --------------------------------------------------
Save_ON = 1;
FileToken = 'recon.mrc';

% Open data and display
Default_path = 'C:\Users\rfl30\DATA raw\SIM data\';
folder_name = uigetdir(Default_path, 'Please select a folder...');
listing = GetListDataset( folder_name, FileToken );

NetParam{1} = alexnet;
NetParam{2} = 'fc7';

[BagFileName, BagPathName] = uigetfile([Default_path, '\*.mat'], 'Please choose a bag to use for BoF features...');
bag = load([BagPathName, BagFileName]);
bag = bag.bag;

%% START THE BATCH LOOP ---------------------------------------------------

t0 = tic;
Full_learners_matrix = [];

%%
for f = 1:length(listing)
    
    disp('------------------------------------------------------------------------------------------');
    disp(['Opening file (',num2str(f),'/',num2str(length(listing)),')']);
    FullFileName = listing{f};
    disp(FullFileName);
    imvirus = UseBF_openSIMage( FullFileName );
    
    disp('Loading the labelled image...');
    [Filepath, Filename_wo_extension,~] = fileparts(FullFileName);
    labelled_image = double(imread( fullfile(Filepath, [Filename_wo_extension,'_labelled image.tif'])));
    n_objects = max(labelled_image (:));
    
    Im_composite = GenerateCompositefromMask( imvirus, labelled_image );
    
    % Extract learners
    [ All_learners_values, All_learners_names ] = ExtractAllParameters( imvirus, labelled_image, NetParam, bag );
    n_learners = length(All_learners_names);
    disp(['Number of learners: ',num2str(n_learners)]);
    
    Full_learners_matrix = cat(1, Full_learners_matrix, All_learners_values);
    
    if Save_ON == 1
        
        disp('------------------------------');
        disp('Write into Excel file...');
        xls_filename = fullfile(Filepath, [Filename_wo_extension,'_learners.xlsx']);
        xlswrite(xls_filename,All_learners_names,1,'A1');
        if ~isempty(All_learners_values)
            xlswrite(xls_filename,All_learners_values,1,'A2');
        end
        
        %% If the calsses have been annotated then save as a separate xls
        Class_filename = fullfile(Filepath, [Filename_wo_extension,'_classes.xlsx']);
        if exist(Class_filename,'file') == 2
            [~, Classifiers, ~] = xlsread(Class_filename,1);
            xls_filename_with_classes = fullfile(Filepath, [Filename_wo_extension,'_learners_with_classes.xlsx']);
            xlswrite(xls_filename_with_classes, cat(2, All_learners_names, 'Class'),1,'A1');
            xlswrite(xls_filename_with_classes, All_learners_values, 1 ,'A2');
            xlswrite(xls_filename_with_classes, Classifiers, 1 , nn2an(2,n_learners+1));
        end
        
    end
    
end

%% 
disp('------------------------------------------------------------------------------------------');

PixelSize = 32; % nm
EquivDiam = 2*PixelSize*sqrt(Full_learners_matrix(:,2)/pi);

figure('Color','white');
histogram(EquivDiam);

Min_Hist = 100;
Max_Hist = 600;
Edges = Min_Hist:10:Max_Hist;

figure('Color','white');
histogram(EquivDiam, Edges);
xlabel 'Equivalent diameter (nm)'
ylabel 'Occurences'
grid on
title(['Number of particles analysed: ', num2str(length(EquivDiam(EquivDiam < Max_Hist))), ' from ', num2str(length(listing)), ' FOVs']);

dim = [.5 .8 0.35 .1];
str = ['Equivalent diameter: ', num2str(mean(EquivDiam(EquivDiam < Max_Hist)),'%.1f'), ' nm (+/- ', num2str(std(EquivDiam(EquivDiam < Max_Hist)),'%.1f'), ' nm STD)'];
annotation('textbox',dim,'String',str);

disp('------------------------------------------------------------------------------------------');
disp('All done.');
toc(t0);

