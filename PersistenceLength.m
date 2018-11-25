function [ PL ] = PersistenceLength( SkellImage )
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here

EndPoints = bwmorph(SkellImage, 'endpoints');
[y_end,x_end] = find(EndPoints);
if isempty(x_end) || isempty(y_end)
    [x_end, y_end] = find(SkellImage,1);
end

D = bwdistgeodesic(SkellImage,x_end(1),y_end(1), 'quasi-euclidean');
s = double(D(:));
s(isnan(s)) = [];


if max(s) >= 12
    
    [y,x] = find(SkellImage);
    
    % Centre and normalize data before first spline
    m_x = mean(x);
    s_x = std(x);
    
    if s_x == 0
        s_x = 1;
    end
    x_norm = (x - m_x)/s_x;
    
    m_y = mean(y);
    s_y = std(y);
    
    if s_y == 0
        s_y = 1;
    end
    y_norm = (y - m_y)/s_y;
    
    ppx = csape(s,x_norm,'variational');
    ppy = csape(s,y_norm,'variational');
    
    % Interpolation along geodesic line
    s_int = 0:1:max(s);
    x_int = s_x*ppval(ppx, s_int) + m_x;
    y_int = s_y*ppval(ppy, s_int) + m_y;
    
    m_x = mean(x_int);
    s_x = std(x_int);
    
    if s_x == 0
        s_x = 1;
    end
    x_int_norm = (x_int - m_x)/s_x;
    
    m_y = mean(y_int);
    s_y = std(y_int);
    
    if s_y == 0
        s_y = 1;
    end
    y_int_norm = (y_int - m_y)/s_y;
    
    ppx = csape(s_int,x_int_norm,'variational');
    ppy = csape(s_int,y_int_norm,'variational');
    
    x_deriv = ppval(fnder(ppx),s_int);
    y_deriv = ppval(fnder(ppy),s_int);
    
    theta = atand(y_deriv./x_deriv);
    
    Dtheta = theta' - circshift(theta',1);
    Dtheta(1) = 0;
    for i = 1:numel(s_int)
        if Dtheta(i) > 120
            theta(i:end) = theta(i:end)-180;
        end
        
        if Dtheta(i) < -120
            theta(i:end) = theta(i:end)+180;
        end
    end
    
    % figure;
    % plot(s_int, theta);
    
    L = 1:ceil(max(s_int)/3);
    cosTheta_all = zeros(1,ceil(max(s_int)/3));
    
    for pos = 1:ceil(max(s_int)/3)
        theta_temp = circshift(theta, pos);
        cosTheta_all(pos) = mean(cosd(theta_temp((pos+1):end) - theta((pos+1):end)));
    end
    
    % figure;
    % plot(L,log(cosTheta_all));
    
    assignin('base','L',L);
    assignin('base','cosTheta_all',cosTheta_all);
    assignin('base','LogCosTheta_all',log(cosTheta_all));
    
    L(cosTheta_all <= 0) = [];
    cosTheta_all(cosTheta_all <= 0) = [];
    
    LinearFitParam = [ones(length(L),1) L'] \ log(cosTheta_all');
    PL = abs(1/(2*LinearFitParam(2)));
    
else % if there are less than 13 points along the geodesic line
    PL = NaN;
end

disp(['Persistence length: ', num2str(PL)]);

end

