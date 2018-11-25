function [Learners, Learner_names] = SelectAndSaveParameters(stats_objects, Save_in_excel, FullFileName)
%writes the following values from fregions to a table that can be
%interpreted by the model

% Learner_names = fieldnames(stats_objects);

N_objects = length(stats_objects);
Object_num = (1:N_objects)';
Area = vertcat(stats_objects.Area);
% Centroid = vertcat(fregions.Centroid);
% CentroidX = Centroid(:,1);
% CentroidY = Centroid(:,2);
% BoundingBox = vertcat(fregions.BoundingBox);
% BoundingBoxx1=BoundingBox(:,1);
% BoundingBoxx2=BoundingBox(:,2);
% BoundingBoxy1=BoundingBox(:,3);
% BoundingBoxy2=BoundingBox(:,4);
MajorAxisLength = vertcat(stats_objects.MajorAxisLength);
MinorAxisLength = vertcat(stats_objects.MinorAxisLength);
Eccentricity = vertcat(stats_objects.Eccentricity);
% Orientation = vertcat(fregions.Orientation);
ConvexArea = vertcat(stats_objects.ConvexArea);
FilledArea = vertcat(stats_objects.FilledArea);
EulerNumber = vertcat(stats_objects.EulerNumber);
EquivDiameter = vertcat(stats_objects.EquivDiameter);
Solidity = vertcat(stats_objects.Solidity);
Extent = vertcat(stats_objects.Extent);
Perimeter = vertcat(stats_objects.Perimeter);
% PerimeterOld = vertcat(fregions.PerimeterOld);

MeanIntensity = vertcat(stats_objects.MeanIntensity);
MinIntensity = vertcat(stats_objects.MinIntensity);
MaxIntensity = vertcat(stats_objects.MaxIntensity);

% tab = horzcat(Area, CentroidX, CentroidY,BoundingBoxx1, BoundingBoxx2, BoundingBoxy1, BoundingBoxy2,MajorAxisLength, MinorAxisLength, Eccentricity,Orientation, ConvexArea,FilledArea,EulerNumber,EquivDiameter, Solidity,Extent, Perimeter,PerimeterOld);
Learners = horzcat(Object_num, Area, MajorAxisLength, MinorAxisLength, Eccentricity, ConvexArea, FilledArea, EulerNumber, EquivDiameter, Solidity, Extent, Perimeter, ...
    MeanIntensity, MinIntensity, MaxIntensity);

Learner_names = {'Object_num','Area','MajorAxisLength', 'MinorAxisLength', 'Eccentricity', 'ConvexArea', 'FilledArea', 'EulerNumber', 'EquivDiameter', 'Solidity', 'Extent', 'Perimeter', ...
    'MeanIntensity', 'MinIntensity', 'MaxIntensity'};

if Save_in_excel == 1
    
    [pathstr,Filename,~] = fileparts(FullFileName);
    xls_filename = fullfile(pathstr, [Filename,'_learners']);
    
    xlswrite(xls_filename,Learner_names,1,'A1');
    xlswrite(xls_filename,Learners,1,'A2');
end


end