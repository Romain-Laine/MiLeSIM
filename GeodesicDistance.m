function [ Length ] = GeodesicDistance( Mask, hFig )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

SkeletonImage = longestConstrainedPath(Mask);

if sum(SkeletonImage(:)) > 0
    EndPoints = bwmorph(SkeletonImage, 'endpoints');
    [y_end,x_end] = find(EndPoints);
    if isempty(x_end) || isempty(y_end)
        [x_end, y_end] = find(SkeletonImage,1);
        SkeletonImage(x_end, y_end) = 0;
    end
    
    
    EndPoints = bwmorph(SkeletonImage, 'endpoints');
    [y_end,x_end] = find(EndPoints);
    D = bwdistgeodesic(SkeletonImage,x_end(1),y_end(1), 'quasi-euclidean');
    
    % figure;
    % imshow(D,[]);
    
    Length = max(D(:));
    
    set(0, 'CurrentFigure', hFig);
    imshow(imresize(GenerateCompositefromMask( double(SkeletonImage), double(Mask) ), 2, 'nearest'), 'Border','tight');
    
else
    Length = [];
end

% set(gca,'units','pixels'); % set the axes units to pixels
% x = get(gca,'position'); % get the position of the axes
% set(gcf,'units','pixels'); % set the figure units to pixels
% y = get(gcf,'position'); % get the figure position
% set(gcf,'position',[y(1) y(2) x(3) x(4)])% set the position of the figure to the length and width of the axes
% set(gca,'units','normalized','position',[0 0 1 1]) % set the axes units to pixels



end

