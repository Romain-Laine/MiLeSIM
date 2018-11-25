function [ Min_size ] = DialogGetMinSize( BW, Min_size_default )
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

all_stats = regionprops(BW, 'Area');
disp(['Number of structures found: ', num2str(length(all_stats))]);
Areas = cat(1,all_stats.Area);

edges = 0:5:100;
figure('Color','white','name','Area histogram');
histogram(Areas, edges);
xlabel 'Area (pixels)'
ylabel 'Occurences'

num_lines = 1;
defaultans = {num2str(Min_size_default)};
dialog_answer = inputdlg('Enter the min size in pixels','Mininum size selection', num_lines, defaultans);
Min_size = str2double(dialog_answer{1});

end

