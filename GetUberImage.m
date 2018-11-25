function [ Uber_image, Uber_image_mask ] = GetUberImage( Image, BW_in , Border_pixel, Display_MP )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

% BW_in = im2bw(double(LabelImage),0.5);
stats_objects = regionprops(BW_in, 'Centroid'); % finds all the information about the big regions
Im_composite = GenerateCompositefromMask( Image, BW_in );

% if Display_MP == 1
%     figure('name','Composite image with AC mask');
%     imshow(Im_composite);
% end

n = 8;   % 8-bits
Panel_size = ceil(sqrt(length(stats_objects)));
Uber_image = uint8((2^n-1)*ones(1+(2*Border_pixel+2)*Panel_size,1+(2*Border_pixel+2)*Panel_size,3));
Uber_image_mask = uint8((2^n-1)*ones(1+(2*Border_pixel+2)*Panel_size,1+(2*Border_pixel+2)*Panel_size));
% Uber_image_initial_mask = uint8((2^n-1)*ones(1+(2*Border_pixel+2)*Panel_size,1+(2*Border_pixel+2)*Panel_size));


if Display_MP == 1
    h_MP = figure('name','Multi-panel image - active contour');
end

for i = 1:length(stats_objects)
    
    img = CropOutROI_fromCentroid( Im_composite, [stats_objects(i).Centroid(1) stats_objects(i).Centroid(2)], Border_pixel );
    img_mask = CropOutROI_fromCentroid( BW_in, [stats_objects(i).Centroid(1) stats_objects(i).Centroid(2)], Border_pixel );
    %     img_initial_mask = CropOutROI_fromCentroid( Mask, [stats_bigobjects(i).Centroid(1) stats_bigobjects(i).Centroid(2)], Border_pixel );
    
    w = 2*Border_pixel;
    x0_uber = 2 + floor((i-1)/Panel_size)*(w+2);
    y0_uber = 2 + rem(i-1,Panel_size)*(w+2);
    
    Uber_image(x0_uber:x0_uber+size(img,1)-1, y0_uber:y0_uber+size(img,2)-1, :) = img;
    Uber_image_mask(x0_uber:x0_uber+size(img,1)-1, y0_uber:y0_uber+size(img,2)-1) = (2^n-1)*img_mask;
    %     Uber_image_initial_mask(x0_uber:x0_uber+size(img,1)-1, y0_uber:y0_uber+size(img,2)-1) = (2^n-1)*img_initial_mask;
    
    if Display_MP == 1
        set(0, 'currentfigure', h_MP);
        subplot(Panel_size, Panel_size, i);
        imshow(img);
        title(i);
    end
end


% figure('name','Uber image','Color','white');
% subplot(1,2,1)
% imshow(Uber_image);
%
% % figure('name','Uber image mask using active contour');
% subplot(1,2,2)
% imshow(Uber_image_mask_ac);

% figure('name',['Uber image mask using ',AC_mask_method]);
% imshow(Uber_image_initial_mask);
% figure('name','Label matrix after active contour');
% imagesc(LabelMatrix_out);


end

