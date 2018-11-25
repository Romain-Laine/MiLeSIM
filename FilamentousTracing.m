function [FilaLength] = FilamentousTracing(Image, Mask)


close all

%%% 01/05/2015 Script originally  written by Pierre Mahou in the LAG lab - Cambridge University
%%% This script trace micelles from the original and segmented images
%%% The micelles are traced one by one using a steping algorithm originally
%%% written for STORM data. For more details see DOI: 10.1126/science.1250945
%%% The tracing can be done for N_Img different images with an arbitrary
%%% number of micelles. At the end a txt script witt the arclength is saved

%% Adapted for filamentous viruses by Romain F. Laine rfl30@cam.ac.uk

Pix_Size         = 32;              %%% Pixel size in nm
Border           = 20;              %%% Number of pixels surrounding a selected Micelle
N_Edge           = 2;               %%% Micelles within a N_Edge pixel area near the broder are not analyzed

%% Parameters for Backbone fitting/tracing --- Adjust if necessary
Radius           = 10;              %%% Radius of the area over which Micelles direction is evaluated
Step             = 1;               %%% Number of pixels between two jumps
Sig              = 0.7;             %%% Width of the gaussian function that filter the histogram of direction
%%% High value is good for high bend but changes of direction might occur during the tracing


%% Parameters for Backbone fitting/tracing --- No need to adjust
N_Hist           = 61;              %%% Number of bin for the histogram of direction, varies from -pi to pi
N_Poly           = 10;              %%% Order of the polynomial function used to fit the histogram of direction
N                = 201;             %%% Number of points used to fit the histogram of direction
Eps              = 5;               %%% Size of the box used to estimate local enter micelles end
% Res              = 1;              %%% Parameters for undersampling used to find the starting point for tracing


%     %%% Paths for the images
%     Path_Img            = [Main_Folder 'a' num2str(t,'% .1d') '_GC' Extension];
%     Path_Img_Seg_Sort   = [Main_Folder 'a' num2str(t,'% .1d') '_' Img_Name  Extension];
%     %%% Open the original and segmented image
%     Img_Or              = double(imread(Path_Img));             %%% Original image
%     Img                 = double(imread(Path_Img_Seg_Sort));    %%% Segmented image
%%% Variables related to the micelles tracing
%     N_Mic               = max(max(Img));                        %%% Number of micelles

[ny,nx]             = size(Mask);                            %%% Number of ligns & colomn in the image
Img_Tracing         = zeros(ny,nx);                         %%% Final image where all the traced micelles are represented

%%% Display the segmented/sorted image of the micelles
hFig = figure;
%imshow(Img_Or,[min(min(Img_Or)) max(max(Img_Or))])
imshow(Mask);
xlabel('pixel number along X'), ylabel('pixel number along Y');
axis on, axis normal,
colormap('jet')


%%% Initialisation of the vectors containing the pixel coordinates of the pth micelle
%%% Later on the matrices are defined as XY_P = [col;row]
XY_P             = [];                                      %%% pixel coordinates of the pth micelle
% XY_P_BB          = [];                                      %%% pixel coordinates of the pth micelle undersampled
%%% Find the indices of the pth fibril
Ind_Fib_P      = find(Mask == 1);                             %%% pixel indices of the micelle


if ~isempty(Ind_Fib_P)                                      %%% Fibrils removed during the sorting are not analyzed

    %% Here one can apply some saturation to the image
%     figure;
%     subplot(1,3,1)
%     imshow(Image, []);
%     
%     Image = Image/prctile(Image(:), 99);
%     subplot(1,3,2)
%     imshow(Image, []);
%     
%     Image = imadjust(Image, [],[],0.7);
%     
%     subplot(1,3,3)
%     imshow(Image, []);
    
    [XY_P(2,:), XY_P(1,:)] = ind2sub(size(Mask),Ind_Fib_P);  %%% pixel coordinates of the pth micelle
    I_P                    = Image(Ind_Fib_P);               %%% pixel intensity of the pth fibrils
    
    %%% Check if a fibril is near the edge of the image -- Wihtin N_Edge pixel
    Row_Cond = (min(XY_P(2,:))>N_Edge && max(XY_P(2,:))<ny-N_Edge+1);
    Col_Cond = (min(XY_P(1,:))>N_Edge && max(XY_P(1,:))<nx-N_Edge+1);
    %%% Fibrils near the edge are not analyzed
    
    if (Row_Cond && Col_Cond)
        
        %%% The micelle is selected -- Matrices comprising the micelle surrounding by a border of N_Border pixels
        Fib_P = Mask.*Image;
        
        Fib_P = Fib_P(max(min(XY_P(2,:)) - Border,1):min(max(XY_P(2,:)) + Border,ny),...
            max(min(XY_P(1,:)) - Border,1):min(max(XY_P(1,:)) + Border,nx));
        
        %%% Initialisation of the pixels along the backbone - Coordinate of the forward and backward tracing
        %XY_P_K         = zeros(2,N_Step+1);
        XY_P_K = [];
        XY_P_B_K = [];
        
        %%% Likelihood to be near the end of the fibril. For each pixel along the backbone a score is calculated.
        %Test_End       = zeros(1,N_Step+1);
        Test_End = [];
        Test_End_B = [];
        
        %%% counter initialisation for the number of step during the forward and backward tracing
        count = 1;
        count_B = 1;
        Test_Back = 1;
        
        %% Forward tracing from a point choosen randomly
        
        %%% Initialisation start with a random point along the micelle and find its nearest local center
        %%% Select a point randomly within the undersampled coordinates
        Init = max(round(rand(1)*(length(squeeze(XY_P(1,:))))-1)+1,1);
        XY_P_I = XY_P(:,Init);
        
        %%% Local fibril orientation
        [Theta_BB,Ind_M,XY_P_I_Center] = Local_Orientation_Init(XY_P,XY_P_I,Radius,I_P,N_Hist,Sig,N_Poly,N);
        %%% Find the nearest local center of the micelle
        XY_P_I = Local_Center_Init(Theta_BB,XY_P_I,XY_P_I_Center,Eps);
        %%% Find the first point along the backbone
        [Theta_P_BB,Ind_M_K,Test_End(1),~] = Local_Orientation(XY_P,XY_P_I,Radius,I_P,N_Hist,Sig,Ind_M,N_Poly,N);
        XY_P_K(:,1) = Step*[cos(Theta_P_BB);sin(Theta_P_BB)]+XY_P_I;
        
        %%% Find the next points along the backbone
        while Test_End(count) > 0.1
            Ind_M = Ind_M_K;
            [Theta_P_BB,Ind_M_K,Test,~] = Local_Orientation(XY_P,XY_P_K(:,end),Radius,I_P,N_Hist,Sig,Ind_M,N_Poly,N);
            Pts = Step*[cos(Theta_P_BB);sin(Theta_P_BB)]+XY_P_K(:,end);
            XY_P_K = [XY_P_K,Pts];
            Test_End = [Test_End,Test];
            count = count+1;
        end
        
        %%% Find the first ending point
        XY_P_End = Local_Center_End(Theta_P_BB,XY_P,XY_P_K,count);
        
        %% Backward tracing from the first ending point
        
        %%% Find the first point along the backbone
        [~,Ind_M,~] = Local_Orientation_Init(XY_P,XY_P_End,Radius,I_P,N_Hist,Sig,N_Poly,N);
        [Theta_P_B_BB,Ind_M_K,Test_End_B(1),~] = Local_Orientation(XY_P,XY_P_End,Radius,I_P,N_Hist,Sig,Ind_M,N_Poly,N);
        XY_P_B_K(:,1) = Step*[cos(Theta_P_B_BB);sin(Theta_P_B_BB)]+XY_P_End;
        
        %%% Find the next points along the backbone
        while Test_Back > 0.1
            Ind_M = Ind_M_K;
            [Theta_P_B_BB,Ind_M_K,Test_Back,~]= Local_Orientation(XY_P,XY_P_B_K(:,end),Radius,I_P,N_Hist,Sig,Ind_M,N_Poly,N);
            Pts_Back = Step*[cos(Theta_P_B_BB);sin(Theta_P_B_BB)]+XY_P_B_K(:,end);
            XY_P_B_K = [XY_P_B_K,Pts_Back];
            Test_End_B = [Test_End_B,Test_Back];
            count_B = count_B+1;
        end
        XY_P_B_End = Local_Center_End(Theta_P_B_BB,XY_P,XY_P_B_K,count_B);
        %%% Backbone of the pth fibril
        XY_P_B_K = [XY_P_End,reshape(XY_P_B_K((XY_P_B_K>0)),[2,count_B]),XY_P_B_End];
        %%% Arc length of the pth fibril
        FilaLength =  count_B*Step+sqrt((XY_P_B_K(1,end)-XY_P_B_K(1,end-1)).^2+(XY_P_B_K(2,end)-XY_P_B_K(2,end-1)).^2);
        FilaLength = Pix_Size*FilaLength; % in nm
        
        %% Display the backbone and the micelle of the pth micelle and overlay it on the corresponding micelle
        %%% Display the pth micelle and overlay it on the corresponding micelle
        figure;
        imshow(Fib_P,[min(min(single(Image))) max(max(single(Image)))],'InitialMagnification','fit');
        xlabel('pixel number along X'), ylabel('pixel number along Y');
        axis on
        colormap('gray')
        hold on
        plot(XY_P_I(1,:)+1-max(min(XY_P(1,:))-Border,1),XY_P_I(2,:)+1-max(min(XY_P(2,:))-Border,1),'go','LineWidth',2,'Color','green');
        plot(XY_P_B_K(1,:)+1-max(min(XY_P(1,:))-Border,1),XY_P_B_K(2,:)+1-max(min(XY_P(2,:))-Border,1),'ko','LineWidth',2,'Color','black');
        plot(XY_P_End(1,:)+1-max(min(XY_P(1,:))-Border,1),XY_P_End(2,:)+1-max(min(XY_P(2,:))-Border,1),'ro','LineWidth',2,'Color','red');
        plot(XY_P_B_End(1,:)+1-max(min(XY_P(1,:))-Border,1),XY_P_B_End(2,:)+1-max(min(XY_P(2,:))-Border,1),'ro','LineWidth',2,'Color','red');
        hold off
        
        %%% Display the pth micelle in the original image
        set(0, 'CurrentFigure', hFig);
        hold on
        plot(XY_P_B_K(1,:),XY_P_B_K(2,:),'k-o','LineWidth',1,'MarkerSize',3,'Color','black');
        hold off
        
        %%% Image with the backbones
        X_pts = round(squeeze(XY_P_B_K(1,:)));
        Y_pts = round(squeeze(XY_P_B_K(2,:)));
        %%% Thickning of the micelle for display purpose
        %     X_pts   = [X_pts,X_pts,X_pts-1,X_pts-1,X_pts-1,X_pts+1,X_pts+1,X_pts+1];
        %     Y_pts   = [Y_pts-1,Y_pts+1,Y_pts-1,Y_pts,Y_pts+1,Y_pts-1,Y_pts,Y_pts+1];
        %     X_pts   = [X_pts,X_pts,X_pts-1,X_pts-1,X_pts-1,X_pts+1,X_pts+1,X_pts+1];
        %     Y_pts   = [Y_pts-1,Y_pts+1,Y_pts-1,Y_pts,Y_pts+1,Y_pts-1,Y_pts,Y_pts+1];
        %%% Draw the backbone on a black image
        line_pts = sub2ind(size(Mask),Y_pts,X_pts);
        Img_Tracing(line_pts) = 500;
        
    end
    
end

%     end
%%% Write the final image
%     imwrite(uint16(Img_Tracing),[Main_Folder num2str(t,'% .2d') '-' Img_Name  '-Tracing-Curved no noise filter' Extension], 'tiff');

% end

% %% Histogram with the micelle arc length
% figure(4);
% hist(Pix_Size*FilaLength,25)
% set(gca,'FontSize',14,'FontName','Calibri')
% xlabel('Length in \mum')
% ylabel('Frequency (a.u)')
% hold off
% box on
% grid on
% legend('Data','Fit')

%% Save a txt file with the estimated length for each micelle

% f = fopen([Main_Folder Img_Name '-Micelles_Lengths_Curved no bits r=25.txt'], 'w');
% fprintf(f, '%s\t%s\r\n', 'N Micelles', 'Length nm');
% for k = 1:length(Length)
%     fprintf(f, '%d\t%d\r\n', k, Pix_Size*Length(k));
% end
% fclose(f);


end
