function [ Radius ] = RadiusFromArea( Mask )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

Radius = sqrt(sum(double(Mask(:)))/pi);

end

