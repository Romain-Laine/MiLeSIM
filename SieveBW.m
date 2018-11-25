function [ BW_bigIntenseobjects ] = SieveBW( BW, image, Min_size, Min_MeanInt, Display_Histo )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

% Sorting by size
all_stats = regionprops(BW,'Area');
disp(['Number of structures found: ', num2str(length(all_stats))]);
idx = find([all_stats.Area] >= Min_size);  % finds regions with an area greater than Min_size
BW_bigobjects = ismember(labelmatrix(bwconncomp(BW)), idx);

% Count objects left
cc_bigobjects = bwconncomp(BW_bigobjects);
disp(['Number of objects after size sieving: ', num2str(cc_bigobjects.NumObjects)]);

% Sorting by intensity
all_stats = regionprops(BW_bigobjects, image, 'MeanIntensity');
MeanInt = cat(1,all_stats.MeanIntensity);
MInt_thresh = max(Min_MeanInt, mean(MeanInt) - 2*std(MeanInt));
disp(['Mean intensity threshold: ', num2str(MInt_thresh),' ADC']);

if Display_Histo == 1
    edges = 0:200:20000;
    figure('name','Mean intensity histogram');
    histogram(MeanInt, edges);
    xlabel('Mean intensity (ADC)');
    ylabel('Occurences')
end

idx = find([all_stats.MeanIntensity] >= MInt_thresh); % maybe sensible....
BW_bigIntenseobjects = ismember(labelmatrix(bwconncomp(BW_bigobjects)), idx);

% Count objects left
cc_bigIntenseobjects = bwconncomp(BW_bigIntenseobjects);
disp(['Number of objects after intensity sieving: ', num2str(cc_bigIntenseobjects .NumObjects)]);

end

