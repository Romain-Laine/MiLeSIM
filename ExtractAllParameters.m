function [ learners_value, learners_name ] = ExtractAllParameters( image, labelled_image, NetParam, bag )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

% disp('------------------------------');
% disp('Extracting basic parameters...');
% disp('Extracting basic learners...');
% tic
[BasicLearners, BasicLearner_names] = ExtractBasicParameters( image, labelled_image );
% tic

%% Hu's invariant moments
% disp('------------------------------');
% disp('Extracting Hu''s invariants parameters...');
% tic
[ Hu_IM_all, Hu_learners_names ] = Hu_invariant_moments( image, labelled_image );
% toc

% CNN AlexNet features
% disp('Extracting AlexNet features...');
% tic
[ AN_learners, AN_learners_names ] = AlexNetParameters( image, labelled_image, NetParam );
% toc

[ BoF_learners, BoF_learners_names ] = BoFParameters( image, labelled_image, bag );

%% Save learners in excel
% learners_value = cat(2,BasicLearners, Hu_IM_all);
% learners_name = cat(2,BasicLearner_names, Hu_learners_names);

learners_value = cat(2,BasicLearners, Hu_IM_all, AN_learners, BoF_learners );
learners_name = cat(2,BasicLearner_names, Hu_learners_names, AN_learners_names, BoF_learners_names);


end

