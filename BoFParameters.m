function [ BoF_learners_all, BoF_learners_names ] = BoFParameters( image, labelled_image, bag )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here


% labelled_image = bwlabel(BW);
n_objects = max(labelled_image(:));
n_features = bag.VocabularySize;

% disp(['Number of objects: ',num2str(n_objects)]);
BoF_learners_all = zeros(n_objects, n_features);

for i = 1:n_objects
    mask = ismember(labelled_image, i);
    [Boxed_image, ~ ] = GetBoxedObject( image, mask, 0 );
    BoF_learners_all(i,:) = encode(bag,Boxed_image);
    
end

BoF_learners_names = cell(1, n_features);
for i = 1:n_features
    BoF_learners_names{i} = ['BoF', num2str(i)];
end


end

