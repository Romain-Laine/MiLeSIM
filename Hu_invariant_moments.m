function [ Hu_IM_all, Hu_learners_names ] = Hu_invariant_moments( image, labelled_image )
% See this paper:
% J. Flusser: "On the Independence of Rotation Moment Invariants", Pattern Recognition, vol. 33, pp. 1405–1410, 2000.

% labelled_image = bwlabel(BW);
n_objects = max(labelled_image(:));

% disp(['Number of objects: ',num2str(n_objects)]);
Hu_IM_all = zeros(n_objects, 8);  % there are 7 invariant moments from Hu et al. + the Phi4 from Flusser
%     h_wait = waitbar(0,'Please wait while Hu''s invariant moments are calculated...','name','Wait bar');

for i = 1:n_objects
    %         waitbar(i/n_objects);
    mask = ismember(labelled_image, i);
    [Boxed_image, Boxed_mask ] = GetBoxedObject( image, mask, 0);
    eta_mat = SI_Moment(Boxed_image, Boxed_mask);
    Hu_IM_temp = Hu_Moments(eta_mat);
    %         Hu_IM_all(i,:) = -sign(Hu_IM_temp).*log10(abs(Hu_IM_temp));   % take the log here
    Hu_IM_all(i,1:7) = abs(log10(abs(Hu_IM_temp)));   % take the log here, the sign seems to make no sense
    Hu_IM_all(i,8) = abs(log10(Phi4_Flusser( Boxed_image, Boxed_mask )));
    
end
%     close(h_wait);

Hu_IM_all(:,7) = [];  % getting rid of Hu7 (not skew invariant)
Hu_IM_all(:,3) = [];  % getting rid of Hu3 (not independent)
Hu_IM_all(:,2) = [];  % getting rid of Hu2 (not independent)

Hu_learners_names = {'Hu_IM1','Hu_IM4','Hu_IM5','Hu_IM6','Phi_4'};

end

