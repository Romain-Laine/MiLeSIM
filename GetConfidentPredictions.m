function [ labels_out ] = GetConfidentPredictions( Posterior_probability, labels, min_probability )
%UNTITLED5 Summary of this function goes here
%   Detailed explanation goes here

labels_out = labels;
max_probability = max(Posterior_probability,[],2);
labels_out(max_probability < min_probability) = {'Unknown'};

end

