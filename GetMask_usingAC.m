function [ BW_out ] = GetMask_usingAC(BW_in, Image, n_iter, Smooth_factor, AC_mask_method)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

Disk_size = 3; % pixels

stats_objects = regionprops(BW_in,'BoundingBox', 'Centroid');

n_objects = length(stats_objects);
disp(['Number of objects before sorting: ', num2str(n_objects)]);
disp('Active contours...');

BW_out = zeros(size(Image));
h_wait = waitbar(0,'Please wait while active contours are calculated...','name','Wait bar');
tic

for i = 1:n_objects
    waitbar(i/n_objects);
    
    if strcmp(AC_mask_method, 'Otsu-thresholding')
        Mask = ismember(labelmatrix(bwconncomp(BW_in)), i);   % using the Otsu-segmentation as a starting mask
        Mask = imfill(Mask,'holes');
        se = strel('disk',Disk_size);
        Mask = imclose(Mask,se);
    elseif strcmp(AC_mask_method, 'Bounding-box')
        Mask = zeros(size(Image));
        Mask(ceil(stats_objects(i).BoundingBox(2)):ceil(stats_objects(i).BoundingBox(2)+stats_objects(i).BoundingBox(4)),...
            ceil(stats_objects(i).BoundingBox(1)):ceil(stats_objects(i).BoundingBox(1)+stats_objects(i).BoundingBox(3))) = 1;
    end
    
    % Calculating the active contours
    bw_ac = activecontour(Image, Mask, n_iter, 'Chan-Vese','SmoothFactor',Smooth_factor);
%     LabelMatrix_out = LabelMatrix_out + i*double(bw_ac);    % this might be a problem when 2 masks overlap...
    BW_out = BW_out + bw_ac; 
end
close(h_wait);

% Convert to logical and label image
BW_out = logical(BW_out);
% LabelMatrix_out = bwlabel(BW_out);


end

