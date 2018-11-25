function [ Boxed_image, Boxed_mask ] = GetBoxedObject( image, mask, disk_size )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

% Method = 'Use BoundingBox';
Method = 'Use Centroid+Mask'; % this is better as it provides images that are always the same size

if strcmp(Method, 'Use BoundingBox')
    
    Edges = 10;
    BoundingBox_parameters = regionprops(mask, 'BoundingBox');
    BoundingBox_parameters = BoundingBox_parameters.BoundingBox;
    
    y0 = max(floor(BoundingBox_parameters(1))-Edges,1);
    y1 = min(y0 + BoundingBox_parameters(3) + 2*Edges, size(image, 2));
    x0 = max(floor(BoundingBox_parameters(2))-Edges,1);
    x1 = min(x0 + BoundingBox_parameters(4) + 2*Edges, size(image, 1));
    Boxed_image = image(x0:x1, y0:y1);
    Boxed_mask = mask(x0:x1, y0:y1);
    
elseif strcmp(Method, 'Use Centroid+Mask')
    
    Border_pixel = 35;
    stats_object = regionprops(mask, 'Centroid');
    Boxed_image = CropOutROI_fromCentroid( image, [stats_object(1).Centroid(1) stats_object(1).Centroid(2)], Border_pixel );
    Boxed_mask = CropOutROI_fromCentroid( mask, [stats_object(1).Centroid(1) stats_object(1).Centroid(2)], Border_pixel );
    
    %     SE = strel('disk',5);
    if disk_size > 0
        SE = strel('disk', disk_size);
        Boxed_mask = imdilate(Boxed_mask, SE);
    end
    Boxed_image = double(Boxed_mask).*Boxed_image;
    
    %     figure;
    %     subplot(1,2,1)
    %     imshow(Boxed_image,[]);
    %     subplot(1,2,2)
    %     imshow(Boxed_mask,[]);
    
end


end

