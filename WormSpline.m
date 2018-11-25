function [ s_int, x_int, y_int, theta_smooth, MaskIm, StartPosition, SmoothSkel ] = WormSpline( Skell, Mask, growth, Sampling_spacingfirst_spline, last_StartPosition, hFig_results )
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

Disaply_ON = 0;
if Disaply_ON == 1
    figure;
    imshow(GenerateCompositefromMask( double(Skell), double(Mask), 2),[]);
end

[y,x] = find(Skell);

% figure;
% imshow(Skell,[]);
% [y,x] = find(Skell);

EndPoints = bwmorph(Skell, 'endpoints');
[y_end,x_end] = find(EndPoints);

Distance2LastStartPosition = zeros(1,length(y_end));
for i = 1: length(y_end)
    Distance2LastStartPosition(i) = sqrt((y_end(i)-last_StartPosition(2))^2 + (x_end(i)-last_StartPosition(1))^2);
end

id_start = find(Distance2LastStartPosition == min(Distance2LastStartPosition),1);
StartPosition = [x_end(id_start) y_end(id_start)];

D = bwdistgeodesic(Skell,x_end(id_start),y_end(id_start), 'quasi-euclidean');
s = double(D(:));
s(isnan(s)) = [];



% Remove first and last few pixels as they tend to bend sharply and remove
% Infinity
chop_length = -1;
id = find( (s <= chop_length) | (s >= (max(s)-chop_length)) );
x(id) = [];
y(id) = [];
s(id) = [];

if isempty(s)
    
    s_int = [];
    x_int = [];
    y_int = [];
    theta_smooth = [];
    SmoothSkel = zeros(size(Mask));
    MaskIm = GenerateCompositefromMask( double(Skell), double(Mask) );
    StartPosition = last_StartPosition;
    
else
    
    % Centre and normalize data before first spline
    m_x = mean(x);
    s_x = std(x);
    x_norm = (x - m_x)/s_x;
    
    m_y = mean(y);
    s_y = std(y);
    y_norm = (y - m_y)/s_y;
    
    assignin('base', 'sss2', s);
    assignin('base', 'xxx', x_norm);
    
    
    ppx = csape(s,x_norm,'variational');
    ppy = csape(s,y_norm,'variational');
    
    s_int = 0:Sampling_spacingfirst_spline:max(s);
    if (rem(max(s),Sampling_spacingfirst_spline)/Sampling_spacingfirst_spline) > 0.5
        s_int = cat(2, s_int, max(s));
    end
    
    % assignin('base','s_Local',s);
    % assignin('base','s_int_Local',s_int);
    
    x_int = s_x*ppval(ppx, s_int) + m_x;
    y_int = s_y*ppval(ppy, s_int) + m_y;
    
    
    % figure;
    % subplot(1,2,1);
    % plot(s,x, s_int, x_int);
    % subplot(1,2,2);
    % plot(s,y, s_int, y_int);
    
    % SmoothSkel = false(size(D));
    % linearInd = sub2ind(size(D), round(y_int), round(x_int));
    % SmoothSkel(linearInd) = true;
    % figure;
    % imshow(SmoothSkel);
    
    %% ------------------------------------------------------
    
    % Centre and normalize data before second spline
    
    m_x = mean(x_int);
    s_x = std(x_int);
    x_int_norm = (x_int - m_x)/s_x;
    
    m_y = mean(y_int);
    s_y = std(y_int);
    y_int_norm = (y_int - m_y)/s_y;
    
    ppx = csape(s_int,x_int_norm,'variational');
    ppy = csape(s_int,y_int_norm,'variational');
    
    % assignin('base', 'ppx1', ppx);
    % assignin('base', 'ppy1', ppy);
    
    % Extrapolate the spline to order 2 outside
    ppx = fnxtr(ppx,2);
    ppy = fnxtr(ppy,2);
    
    % [breaks,coefs] = unmkpp(ppx);
    % coefs = cat(1, mean(coefs(1:5,:)), coefs, mean(coefs((end-4):end,:)));
    % breaks = cat(2, -growth, breaks, growth + max(s_int));
    % ppx = mkpp(breaks,coefs);
    %
    % [breaks,coefs] = unmkpp(ppy);
    % coefs = cat(1, mean(coefs(1:5,:)), coefs, mean(coefs((end-4):end,:)));
    % breaks = cat(2, -growth, breaks, growth + max(s_int));
    % ppy = mkpp(breaks,coefs);
    
    s_int = -growth:1:(growth + max(s_int));
    x_int = s_x*ppval(ppx, s_int) + m_x;
    y_int = s_y*ppval(ppy, s_int) + m_y;
    
    % assignin('base', 'ppx2', ppx);
    % assignin('base', 'ppy2', ppy);
    
    
    if ~isempty(hFig_results)
        % Display
        set(0, 'CurrentFigure', hFig_results);
        subplot(3,4,1);
        plot(s,x, s_int, x_int);
        axis tight
        grid on
        xlabel 's (pixels)'
        ylabel 'x-position'
        
        subplot(3,4,5);
        plot(s,y, s_int, y_int);
        axis tight
        grid on
        xlabel 's (pixels)'
        ylabel 'y-position'
    end
    
    X = round(x_int);
    Y = round(y_int);
    
    Y((X<1)|(X>size(Skell,2))) = [];
    X((X<1)|(X>size(Skell,2))) = [];
    
    X(((Y<1) | (Y>size(Skell,1)))) = [];
    Y((Y<1)|(Y>size(Skell,1))) = [];
    
    SmoothSkel = false(size(D));
    linearInd = sub2ind(size(D), Y, X);
    SmoothSkel(linearInd) = true;
    MaskIm = GenerateCompositefromMask( double(SmoothSkel), double(Mask) );
    
    if ~isempty(hFig_results)
        subplot(3,4,[2 3 4 6 7 8 10 11 12]);
        imshow( MaskIm );
    end
    
    
    %% ------------------------------------------------------------
    ppx = csape(s_int,x_int,'variational');
    ppy = csape(s_int,y_int,'variational');
    
    % assignin('base', 'ppx3', ppx);
    % assignin('base', 'ppy3', ppy);
    
    % coeffs_deriv = zeros(length(s_int)-1,3);   % store the coefficients of the derivative
    % for k = 1:(length(s_int)-1)
    %     c = ppx.coefs(k,:);   % pp is a structure
    %     coeffs_deriv(k,:) = polyder(c);
    % end
    
    % ppx_deriv = mkpp(s_int,coeffs_deriv);
    % x_deriv = ppval(ppx_deriv,s_int);
    
    x_deriv = ppval(fnder(ppx),s_int);
    
    % coeffs_deriv = zeros(length(s_int)-1,3);   % store the coefficients of the derivative
    % for k = 1:(length(s_int)-1)
    %     c = ppy.coefs(k,:);   % pp is a structure
    %     coeffs_deriv(k,:) = polyder(c);
    % end
    % ppy_deriv = mkpp(s_int,coeffs_deriv);
    
    % ppy_deriv = mkpp(s_int,polyder(ppy.coefs));
    % y_deriv = ppval(ppy_deriv,s_int);
    
    y_deriv = ppval(fnder(ppy),s_int);
    
    
    % smooth_span = 3;
    % figure;
    % subplot(1,2,1)
    % plot(s_int, x_deriv, s_int, smooth(x_deriv,smooth_span));
    % subplot(1,2,2)
    % plot(s_int, y_deriv, s_int, smooth(y_deriv,smooth_span));
    
    theta = atand(y_deriv./x_deriv);
    
    Dtheta = theta' - circshift(theta',1);
    Dtheta(1) = 0;
    for i = 1:numel(s_int)
        if Dtheta(i) > 150
            theta(i:end) = theta(i:end)-180;
        end
        
        if Dtheta(i) < -150
            theta(i:end) = theta(i:end)+180;
        end
    end
    
    smooth_span = 1;
    theta_smooth = smooth(theta,smooth_span);
    
    % figure;
    
    if ~isempty(hFig_results)
        subplot(3,4,9);
        plot(s_int, theta, s_int, theta_smooth, s_int, Dtheta);
        xlabel 's (pixels)'
        ylabel 'theta (degrees)'
        axis tight
        grid on
    end
    
end


end

