function [ full_listing ] = GetListDataset( folder_name, Token )
%UNTITLED5 Summary of this function goes here
%   Detailed explanation goes here

disp('Folder name:');
disp(folder_name);

disp(['Token used: ', Token]);
listing = dir([folder_name,'\*',Token]);
disp(['Number of files: ',num2str(length(listing))]);

full_listing = cell(1,length(listing));
for i = 1:length(listing)
    full_listing{i} = fullfile(folder_name,listing(i).name);    
end


end

