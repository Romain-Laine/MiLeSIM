function [tab, imvirus, fregions, imvirusname] = ReadinImageVirusesfunc
%Function that reads in image, determine shape and plot onto image

% Get the image; user selected
use_input_dialog = true;
if use_input_dialog == true
    %% Input dialog
    % input SIM data
    [imvirusname,path] = uigetfile({'*.tif';'*.*'},'File Selector');
    % exception handling
    if imvirusname == 0
        return
    end
end

% Read the image
imvirus = imread(fullfile(path, imvirusname));

figure;
imagesc(imvirus);
colorbar

% button = questdlg('Gaussian Smoothing for STORM?','Smoothing?','Yes','No','No');
% switch button
%     case 'Yes'
%         imvirus = imgaussfilt(imvirus,2,'FilterDomain','spatial');
%         figure
%         imagesc(imvirus);
%     case 'No'
%         
%     otherwise
%         return
% end

% Creates a binary image

BW = blackwhitevirus(imvirus);

figure;
imagesc(BW);
colorbar;

%Regions are found within the virus image
[~,fregions] = regionsfindvirus(BW, imvirus,imvirusname); %, diameterofvirus, resolution, pixelsize
%saves the regions to a table
tab = regwritetotab(fregions);
imvirusname = imvirusname(1:4);
name = [imvirusname 'regions'];  %save this table
xlswrite(name,tab);

end
