function [ h_CorrGraph ] = CorrelationGraph_AreaMeanInt( BW, image )
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here

% Sorting by size
all_stats = regionprops(BW, image,'Area','MeanIntensity');
Areas = cat(1,all_stats.Area);
MeanInts = cat(1,all_stats.MeanIntensity);

h_CorrGraph = figure('name','Area/MeanInt Correlation graph','Color','white');
plot(Areas,MeanInts,'r+');
xlabel('Areas (pixels)');
ylabel('Mean intensity (ADC)');
grid on

end

