function [ Im_ROI ] = CropOutROI_fromCentroid( Image, Centroid, Border_pixel )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

x0 = max((round(Centroid(2)) - Border_pixel), 1);
y0 = max((round(Centroid(1)) - Border_pixel), 1);
x1 = min((round(Centroid(2)) + Border_pixel), size(Image,1));
y1 = min((round(Centroid(1)) + Border_pixel), size(Image,2));

if x0 == 1
    x1 = 2*Border_pixel+1;
end

if y0 == 1
    y1 = 2*Border_pixel+1;
end

if x1 == size(Image,1)
    x0 = size(Image,1)-2*Border_pixel;
end

if y1 == size(Image,2)
    y0 = size(Image,2)-2*Border_pixel;
end

if length(size(Image)) == 2
    Im_ROI = Image(x0:x1, y0:y1);
elseif length(size(Image)) == 3
    Im_ROI = Image(x0:x1, y0:y1,:);
end

if size(Im_ROI,1)*size(Im_ROI,2) ~= (2*Border_pixel+1)^2
    disp('---------- CropOutROI_fromCentroid: Image size issue ------------');
end


end

