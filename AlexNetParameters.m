function [ AN_learners_all, AN_learners_names ] = AlexNetParameters( image, labelled_image, NetParam )

% net = alexnet;
% layer = 'fc7'; % fully connected layer 

net = NetParam{1};
layer = NetParam{2};

% labelled_image = bwlabel(BW);
n_objects = max(labelled_image(:));

% disp(['Number of objects: ',num2str(n_objects)]);
AN_learners_all = zeros(n_objects, 4096);  % AlexNet returns 4096 features at the fc7 layer

for i = 1:n_objects
    mask = ismember(labelled_image, i);
    [Boxed_image, ~ ] = GetBoxedObject( image, mask, 0);
    Im_size = imresize(Boxed_image,[227 227]); % AlexNet takes only images that are 227x227x3
    Im_size3C = cat(3,Im_size,Im_size,Im_size);

    AN_learners_all(i,:) = activations(net, Im_size3C, layer);
    
end

AN_learners_names = cell(1, 4096);
for i = 1:4096
    AN_learners_names{i} = ['AN', num2str(i)];
end

end

