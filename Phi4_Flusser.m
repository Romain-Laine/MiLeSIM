function [ Phi4 ] = Phi4_Flusser( image, mask )
% From the paper:
% J. Flusser: "On the Independence of Rotation Moment Invariants", Pattern Recognition, vol. 33, pp. 1405–1410, 2000.

u11 = Centr_Moment(image,mask,1,1);
u30 = Centr_Moment(image,mask,3,0);
u12 = Centr_Moment(image,mask,1,2);
u03 = Centr_Moment(image,mask,0,3);
u21 = Centr_Moment(image,mask,2,1);
u20 = Centr_Moment(image,mask,2,0);
u02 = Centr_Moment(image,mask,0,2);

Phi4 = u11*((u30+u12)^2-(u03+u21)^2) - (u20-u02)*(u30+u12)*(u03+u21);


end

