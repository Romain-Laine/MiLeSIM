function [Learners, Learner_names] = ExtractBasicParameters( imvirus, labelled_image )

stats_objects = regionprops(labelled_image, imvirus, 'all');


N_objects = length(stats_objects);
Object_num = (1:N_objects)';                           % 1
Area = vertcat(stats_objects.Area);                    % 2

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
AxisLengthRatio = MajorAxisLength./MinorAxisLength;          % 3

Eccentricity = vertcat(stats_objects.Eccentricity);    % 4

% Orientation = vertcat(fregions.Orientation);
% ConvexArea = vertcat(stats_objects.ConvexArea);  % not robust towards bending of filamentous for instance (only computed for the extent)
% FilledArea = vertcat(stats_objects.FilledArea); % only useful when hollow structure (very rare)

% EulerNumber = vertcat(stats_objects.EulerNumber);  % not very discriminatory
% EquivDiameter = vertcat(stats_objects.EquivDiameter); % redundant with the area

Solidity = vertcat(stats_objects.Solidity);            % 5
% Extent = vertcat(stats_objects.Extent);   % not meaningfull

Perimeter = vertcat(stats_objects.Perimeter);   % not the absolute value
% PerimeterOld = vertcat(fregions.PerimeterOld);
Perim2Area_ratio = Perimeter./Area;                          % 6

MeanIntensity = vertcat(stats_objects.MeanIntensity);  % 7
% MinIntensity = vertcat(stats_objects.MinIntensity);
% MaxIntensity = vertcat(stats_objects.MaxIntensity);

Std_pixel_values = zeros(N_objects,1);                 % 8
for i = 1:N_objects
    Std_pixel_values(i) = std(stats_objects(i).PixelValues)/mean(stats_objects(i).PixelValues);
end

Learners = horzcat(Object_num, Area, AxisLengthRatio , Eccentricity, Solidity, Perim2Area_ratio, MeanIntensity, Std_pixel_values);
Learner_names = {'Object_num','Area','AxisLengthRatio', 'Eccentricity', 'Solidity', 'Perim2Area_ratio', 'MeanIntensity', 'Std_pixel_values'};


end