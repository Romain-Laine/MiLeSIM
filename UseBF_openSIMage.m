function [ image ] = UseBF_openSIMage( FullFileName )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

% Unwrap bformat
bfdata = bfopen(FullFileName);
data_images = bfdata{1,1};
n_images = size(data_images,1);

% Average repeats
image = zeros(size(data_images{1,1}));
for i = 1:n_images
    image = image + double(data_images{i,1});
end
image = image/n_images;

% Removing background and ringing artefacts
Thresh_level = mean(image(:)) + std(image(:));
disp(['Mean: ', num2str(mean(image(:))), ' & STD: ', num2str(std(image(:)))]);
image = image - Thresh_level;
image(image < 0) = 0;

end

