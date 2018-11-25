function [ SelectedLabelled_matrix ] = CreateSelectedLabelled_matrix( Labelled_matrix, All_labels, Selected_label )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

SelectedLabelled_matrix = Labelled_matrix;
n_objects = length(All_labels);

for i = 1:n_objects
    if ~(All_labels(i) == Selected_label)
        SelectedLabelled_matrix(SelectedLabelled_matrix == i) = 0;
    end
end



end

