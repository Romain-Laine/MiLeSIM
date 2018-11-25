function [ DiameterFit, IntensityFit, LengthFit ] = RodAnalysis( Image, Mask, PixelSize, Resolution, hFig )
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

Display_ON = 0;

ModelResolution = 5; % nm
InitialGuessDiameter = 5; % pixels
InitialGuessDiameter = InitialGuessDiameter*PixelSize/ModelResolution;

ScalingFactor = PixelSize/ModelResolution;
MaskResized = imresize(Mask, ScalingFactor, 'bicubic');
% se = strel('Disk', 10, 6);
% MaskResized = imclose(MaskResized,se);

SkeletonImage = longestConstrainedPath(MaskResized);
SkeletonImage = bwmorph(SkeletonImage, 'bridge');

if Display_ON == 1
    figure;
    imshow(GenerateCompositefromMask( double(SkeletonImage), MaskResized ),[]);
end

growth = 60; % pixels
Sampling_spacingfirst_spline = 10;

if Display_ON == 1
    hFig_results  = figure;
else
    hFig_results  = [];
end

[ ~, ~, ~, ~, ~, ~ , SmoothSkel ] = WormSpline( SkeletonImage, MaskResized, growth, Sampling_spacingfirst_spline, [0,0], hFig_results );
SmoothSkel = bwmorph(SmoothSkel , 'bridge');

% assignin('base','SmoothSkel',SmoothSkel);


if sum(SmoothSkel(:))>0
    
    % figure;
    % imshow(GenerateCompositefromMask( double(SkeletonImage), MaskResized ),[]);
    
    % EndPOints_image = false(size(thinnedImg));
    % EndPOints_image(bwmorph(SkeletonImage, 'endpoints')) = true; % endpoints mask
    EP_ind = find(bwmorph(SmoothSkel, 'endpoints')); % endpoints
    bwdg = bwdistgeodesic(SmoothSkel, EP_ind(1,:));
    
    % assignin('base','bwdgTEST',bwdg);
    
    % figure;
    % subplot(1,2,1);
    % imshow(SkeletonImage,[]);
    % subplot(1,2,2);
    % imshow(bwdg,[]);
    
    InitialGuesses = [InitialGuessDiameter, max(Image(:)), growth, growth];
    disp('Initial guesses:');
    disp(InitialGuesses);
    
    if Display_ON == 1
        hFigRod = figure;
        hFigRod2 = figure;
    end
    
    % fitParametersOUT = fminunc(@Chi2fun, InitialGuesses);
    
    % options = optimset('Display','iter','PlotFcns',@optimplotfval, 'MaxIter', 50);
    
    options = optimset('MaxIter', 50);
    fitParametersOUT = fminsearch(@Chi2fun, InitialGuesses, options);
    % fitParametersOUT = fminsearch(@Chi2fun, InitialGuesses);
    
    % lb = [1 max(Image(:)) 0 0];
    % ub = [100 max(Image(:)) 50 50];
    % % options = optimoptions('OptimalityTolerance', 1e-8);
    % % options = optimset('Display','iter','TolX',1e-8);
    % options = optimoptions(@lsqnonlin,'OptimalityTolerance', 1e-10, 'FunctionTolerance', 1e-8, ...
    %     'FiniteDifferenceType','central', 'algorithm','levenberg-marquardt');
    % fitParametersOUT = lsqnonlin(@Chi2fun,InitialGuesses, [],[], options);
    
    % opts = optimoptions(@fmincon);
    % problem = createOptimProblem('fmincon','objective',...
    %  @Chi2fun,'x0',InitialGuesses,'lb',lb,'ub',ub,'options',opts);
    % gs = GlobalSearch;
    % fitParametersOUT = run(gs,problem);
    



disp('Fitted parameters:');
disp(fitParametersOUT);

DiameterFit = ModelResolution*abs(fitParametersOUT(1)); % in nm
IntensityFit = fitParametersOUT(2);
LengthFit = ModelResolution*(nanmax(bwdg(:)) - max(0,fitParametersOUT(3)) - max(0, fitParametersOUT(3)));

set(0, 'CurrentFigure', hFig);
imshow(imresize(imfuse(Image, RodModel_image( fitParametersOUT(1), fitParametersOUT(2),  fitParametersOUT(3), fitParametersOUT(4))),2, 'nearest'), 'Border','tight');

else
    DiameterFit = [];
    IntensityFit = [];
    LengthFit = [];
    
end


    function RodImage = RodModel_image( Diameter, Intensity,  L1, L2)
        
        SkeletonImageCropped = ((bwdg >= abs(L1)) & (bwdg <= (nanmax(bwdg(:)) - abs(L2))));
        SE = strel('disk', round(abs(Diameter)/2), 8);
        GT_image_raw = imdilate(SkeletonImageCropped, SE);
        GT_image = bwmorph(GT_image_raw,'remove');
        
        sigma = Resolution/(ModelResolution*2*sqrt(2*log(2)));
        GT_image = imgaussfilt(double(GT_image), sigma, 'FilterDomain', 'frequency', 'FilterSize',6*ceil(sigma)+1);
        GT_image_resized = imresize(GT_image, size(Image));
        RodImage = Intensity*GT_image_resized/max(GT_image_resized(:));
        
        if Display_ON == 1
            set(0, 'CurrentFigure', hFigRod);
            %         subplot(1,2,1);
            %         imshow(SkeletonImageCropped,[]);
            %         subplot(1,2,1);
            %         imshow(GT_image_resized,[]);
            %         subplot(1,2,2);
            %         imshow(Image,[]);
            %         pause(1);
            % subplot(1,2,2);
            imshow(imresize(imfuse(Image,GT_image_resized),10, 'nearest'));
            
            set(0, 'CurrentFigure', hFigRod2);
            imshow(imresize(Image - GT_image_resized,10,'nearest'),[]);
        end
        
    end


    function Chi2 = Chi2fun(fitParameters)
        
        Diameter = fitParameters(1);
        Intensity = fitParameters(2);
        L1 = fitParameters(3);
        L2 = fitParameters(4);
        
        RodImage = RodModel_image( Diameter, Intensity,  L1, L2);
        %         assignin('base','DiffImage',(Image - RodImage));
        
        ResImage = (Image - RodImage).^2;
        Chi2 = sum(ResImage(:));
        
        %         ResImage = Image - GT_image_resized;
        %         Chi2 = reshape(ResImage, [size(ResImage,1)*size(ResImage,2), 1]);
        
    end


end

