%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%.
% 2017-09-06 Romain Laine rfl30@cam.ac.uk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Initialization
clear all;
close all;
clc

warning('off','all');

% User-set parameters -----------------------------------------------------

Save_results = 1;
FileToken = 'recon.mrc'; % to recognize the files to analyse
PixelSize = 32; % nm

% ELM parameters
hough_low = 1;
hough_high = 10;
segmentation = 10;
border = 5;
seed = 7;
hough_sensitivity = 0.85;

% Rod analysis
Resolution = 90; % nm

% -------------------------------------------------------------------------

disp('------------------------------');
Default_path = 'C:\Users\rfl30\DATA raw\SIM data\';

% Read in image file which you would like to predict classes
folder_name = uigetdir(Default_path, 'Please select a folder...');

listing = GetListDataset( folder_name, FileToken );
[Filepath,~,~] = fileparts(listing{1});
disp('File path selected:');
disp(Filepath);

[Filename, Filepath] = uigetfile('*.xlsx','Select a .xlsx file with labels (annotated or predicted)', folder_name);

tic
disp('------------------------------');
disp('Reading data from spreadsheet...');
disp(fullfile(Filepath, Filename));
[Learners_values, annotation, ~] = xlsread(fullfile(Filepath, Filename),1);
Learners_names = annotation(1,1:end-1);
annotation = annotation(2:end,end);
Learners_values = Learners_values(:,1:end);
toc

Class_list = unique(annotation);
n_classes = length(Class_list);


%% START THE BATCH LOOP ---------------------------------------------------

n_virus_inclass = zeros(length(listing), n_classes);

AllFilaLength = [];
AllFilaPL = [];
AllSmallFilaLength = [];
AllLargeSphRadius = [];
AllLargeSphEquiRadius = [];

AllSmallSphRadius = [];
AllUnknownRadius = [];
AllRodWidth = [];
AllRodLength = [];

hFigBoxes = figure('name','Boxed image and mask');
hFigFilamentous = figure('name', 'Filamentous', 'units', 'normalized','outerposition', [0.1 0.1 0.4 0.4]);
hFigSmallFill = figure('name', 'Small filamentous', 'units', 'normalized','outerposition', [0.3 0.1 0.4 0.4]);
hFigLargeSph = figure('name', 'Large spherical', 'units', 'normalized','outerposition', [0.5 0.1 0.4 0.4]);
hFigRod = figure('name', 'Rod', 'units', 'normalized','outerposition', [0.7 0.1 0.4 0.4]);

if Save_results == 1
    mkdir(folder_name,'Post-classification analysis');
    for i = 1:n_classes
        mkdir([folder_name,'\Post-classification analysis'], Class_list{i});
    end
end


t0 = tic;
current_label_position = 0;

%%
for f = 1:length(listing)
    %%
    
    disp('------------------------------------------------------------------------------------------');
    disp(['Opening file (',num2str(f),'/',num2str(length(listing)),')']);
    FullFileName = listing{f};
    disp(FullFileName);
    imvirus = UseBF_openSIMage( FullFileName );
   
    
    disp('------------------------------');
    disp('Loading the labelled image...');
    [Filepath, Filename_wo_extension,~] = fileparts(FullFileName);
    labelled_image = double(imread( fullfile(Filepath, [Filename_wo_extension,'_labelled image.tif'])));
    n_objects = max(labelled_image (:));
    %%
    
    for i = 1:n_objects
        %%
        current_label_position = current_label_position + 1;
        current_label = annotation(current_label_position);
        mask = ismember(labelled_image, i);
        [ Boxed_image, Boxed_mask ] = GetBoxedObject( imvirus, mask, 0);
        
        set(0, 'CurrentFigure', hFigBoxes);
        subplot(1,2,1);
        imshow(Boxed_image, []);
        title(current_label);
        subplot(1,2,2);
        imshow(Boxed_mask, []);
        title(current_label);
        
        disp('---------------------------');
        disp(current_label);
        
        if strcmp(current_label, 'Filamentous')
            AllFilaLength = cat(1, AllFilaLength, GeodesicDistance( Boxed_mask, hFigFilamentous )*PixelSize);
            AllFilaPL = cat(1, AllFilaPL, PersistenceLength(Boxed_mask)*PixelSize);
            
            if Save_results == 1
                filenameSave = [folder_name,'\Post-classification analysis\',current_label{1},'\', Filename_wo_extension,'_Object', num2str(i),'.png' ];
                saveas(hFigFilamentous, filenameSave, 'png');
            end
            
        elseif strcmp(current_label, 'Small filamentous')
            AllSmallFilaLength = cat(1, AllSmallFilaLength, GeodesicDistance(Boxed_mask, hFigSmallFill)*PixelSize);
            
            if Save_results == 1
                filenameSave = [folder_name,'\Post-classification analysis\',current_label{1},'\', Filename_wo_extension,'_Object', num2str(i),'.png' ];
                saveas(hFigSmallFill, filenameSave, 'png');
            end
            
        elseif strcmp(current_label, 'Large spherical')
            AllLargeSphRadius = cat(1, AllLargeSphRadius, ELM_spherical_analysis(Boxed_image, hough_low, hough_high, segmentation, border, seed, hough_sensitivity, hFigLargeSph)*PixelSize);
            
            if Save_results == 1
                filenameSave = [folder_name,'\Post-classification analysis\',current_label{1},'\', Filename_wo_extension,'_Object', num2str(i),'.png' ];
                saveas(hFigLargeSph, filenameSave, 'png');
            end
            
            AllLargeSphEquiRadius = cat(1, AllLargeSphEquiRadius, sqrt((sum(double(Boxed_mask(:)))/pi))*PixelSize);
            
        elseif strcmp(current_label, 'Small spherical')
            AllSmallSphRadius = cat(1, AllSmallSphRadius, sqrt((sum(double(Boxed_mask(:)))/pi))*PixelSize);
            
        elseif strcmp(current_label, 'Unknown')
            AllUnknownRadius = cat(1, AllUnknownRadius, sqrt((sum(double(Boxed_mask(:)))/pi))*PixelSize);
            
        elseif strcmp(current_label, 'Rod')
            
            [ DiameterFit, IntensityFit, LengthFit ] = RodAnalysis( Boxed_image, Boxed_mask, PixelSize, Resolution, hFigRod );
            AllRodWidth = cat(1, AllRodWidth, DiameterFit);
            AllRodLength = cat(1, AllRodLength, LengthFit);
            
            if Save_results == 1
                filenameSave = [folder_name,'\Post-classification analysis\',current_label{1},'\', Filename_wo_extension,'_Object', num2str(i),'.png' ];
                saveas(hFigRod, filenameSave, 'png');
            end
            
        end
        
    end
    
end

warning('on','all');

%%
figure('Color', 'white', 'name', 'Results: Filamentous');
subplot(1,3,1);
histogram(AllFilaLength,50);
xlabel 'Filamentous length (nm)'
title 'Filamentous length'
subplot(1,3,2);
histogram(AllFilaPL,50);
xlabel 'Persistence length (nm)'
title 'Persistence length'
% subplot(1,3,3);
% scatter(AllFilaLength, AllFilaPL)
% xlabel 'Length (nm)'
% ylabel 'Persistence length (nm)'

figure('Color', 'white', 'name', 'Results: Small filamentous');
histogram(AllSmallFilaLength,50);
xlabel 'Filamentous length (nm)'
title 'Small filamentous'

AllLargeSphRadius_hist = AllLargeSphRadius((AllLargeSphRadius > 0) & (AllLargeSphRadius < 500));
figure('Color', 'white', 'name', 'Results: Spherical');
subplot(1,2,1);
histogram(AllLargeSphRadius_hist,50);
xlabel 'Spherical radius (nm)'
xlim([20 250]);

subplot(1,2,2);
% figure('Color', 'white', 'name', 'Small spherical');
histogram(AllSmallSphRadius,50);
xlabel 'Spherical radius (nm)'

figure('Color', 'white', 'name', 'Results: Unknown');
histogram(AllUnknownRadius,50);
xlabel 'Equivalent radius (nm)'

figure('Color', 'white', 'name', 'Results: Rod');
subplot(1,3,1);
histogram(AllRodWidth,50);
xlabel 'Width (nm)'

subplot(1,3,2);
% figure('Color', 'white', 'name', 'Rod length');
histogram(AllRodLength,50);
xlabel 'Length (nm)'

subplot(1,3,3);
% figure('Color', 'white', 'name', 'Rod length');
scatter(AllRodWidth, AllRodLength)
xlabel 'Width (nm)'
ylabel 'Length (nm)'

if Save_results == 1
    ParametersNames = cell(1,8);
    ParametersNames{1} = 'Filamentous length';
    ParametersNames{2} = 'Filamentous persistence length';
    ParametersNames{3} = 'Small filamentous length';
    ParametersNames{4} = 'Large spherical radius';
    ParametersNames{5} = 'Large spherical equivalent radius';    
    ParametersNames{6} = 'Small spherical radius';
    ParametersNames{7} = 'Unknown equivalent radius';
    ParametersNames{8} = 'Rod length';
    ParametersNames{9} = 'Rod diameter';
    
    filenameSave = [folder_name,'\Post-classification analysis\','PostClassificationResults.xlsx' ];
    xlswrite(filenameSave, ParametersNames,1,'A1');
    xlswrite(filenameSave, AllFilaLength,1,'A2');
    xlswrite(filenameSave, AllFilaPL,1,'B2');
    xlswrite(filenameSave, AllSmallFilaLength,1,'C2');
    xlswrite(filenameSave, AllLargeSphRadius,1,'D2');
    xlswrite(filenameSave, AllLargeSphEquiRadius,1,'E2');
    xlswrite(filenameSave, AllSmallSphRadius,1,'F2');
    xlswrite(filenameSave, AllUnknownRadius,1,'G2');
    if ~isempty(AllRodLength) 
        xlswrite(filenameSave, AllRodLength,1,'H2');
    end
    if ~isempty(AllRodWidth) 
        xlswrite(filenameSave, AllRodWidth,1,'I2');
    end
    
end


disp('----------------------------------------------------------------------------');
disp('All done.');
toc(t0);


