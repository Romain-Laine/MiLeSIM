function [ Im_composite ] = GenerateCompositefromMask( Image, Mask )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

% Method = 'using_imfuse';
Method = 'manual';

if strcmp(Method , 'using_imfuse')
    ImOutline = bwmorph(Mask,'remove');
    Im_composite = imfuse(Image,ImOutline, 'ColorChannels',[0 1 2]);
elseif strcmp(Method , 'manual')
    n = 8;
    ImOutline = uint8((2^n-1)*bwmorph(Mask,'remove'));
    Im_unint = uint8((2^n-1)*(Image/max(Image(:))));
    Im_composite = cat(3,Im_unint,Im_unint,Im_unint);
    Im_composite(:,:,3) = Im_composite(:,:,3) + ImOutline;
    
end


end

