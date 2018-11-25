function [ fitted_radius ] = ELM_spherical_analysis(image_data, hough_low, hough_high, segmentation, border, seed, hough_sensitivity, hFig)

% Parameters for shell finding
radius_lower = hough_low;
radius_upper = hough_high;
segment_half_size = segmentation;
edge_border = border;

rng(seed);

% Set the following flag to 1 to see each segment as it is fitted
% SHOW_ALL_FITS = 0;


% Find and display shells
% set(0, 'CurrentFigure', hFig);
[centres, ~, ~] = find_circular_shells(image_data, radius_lower, radius_upper, segment_half_size, edge_border, hough_sensitivity, false);
% 	title(image_basename, 'interpreter', 'none')
% title('Image', 'interpreter', 'none')

% Tile segmented shells in figure
shell_segments = segment_shells(image_data, centres, segment_half_size);
tiled_segments = tile_segments(shell_segments);

% figure(2);
% imshow(tiled_segments, []);
% title(['Segmented shells for ', 'Image'], 'interpreter', 'none');

try
    shell_segment_mat = cell2mat(shell_segments);
    Mxss = max(shell_segment_mat(:));
    Mnss = min(shell_segment_mat(:));
    caxis([Mnss, Mxss])
    %     tiled_segments = imsubtract(tiled_segments,double(Mnss));
catch
    warning('Problem reshaping segments to set caxis');
end

% Save segmented shell tiles % Change mat2gray to uint16 to save full dat
% imwrite(uint16(tiled_segments), fullfile(output_dir, [image_basename, '_raw.tif']));

% Fit all segmented shells. Display to the user one by one, if flag set
fits = cell(length(shell_segments) + 1, 1);
fitData = -ones(length(shell_segments), 11);
% Write headers in first row, and  copy as a string for file output
fits{1} = {'x segment pos,   y segment pos,   x shift,   y shift,   orientation,   semiminor axis,   PSF variance,   brightness,   aspectRatioMinusOne,   equatoriality,   residual'};
% fitsHdr = 'x segment pos,   y segment pos,   x shift,   y shift,   orientation,   semiminor axis,   PSF variance,   brightness,   aspectRatioMinusOne,   equatoriality,   residual';

%  fitsHdr = ['x segment pos,   y segment pos,   x shift,   y shift,   radius,   PSF sigma,   brightness,   residual'];
for i = 1:length(shell_segments)
    actual_image = shell_segments{i};
    background = median(actual_image(actual_image < mean(actual_image(:))));
    actual_image = double(actual_image - background);
    
    % 		bw_image = actual_image;
    % 		threshold = 35 - background;
    % 		bw_image(actual_image > threshold) = 1;
    % 		bw_image(actual_image <= threshold) = 0;
    
    % 		stats = regionprops(bw_image, 'Centroid', 'MajorAxisLength', 'MinorAxisLength', 'Orientation');
    
    x_shift = 0;
    y_shift = 0;
    radius = 6;
    psf_sigma = 2;
    height = max(actual_image(:));
    
    % Fit shell to spore segment
    [x_centre_fit, y_centre_fit, radius_fit, psf_sigma_fit, height_fit, residual] = fit_sphere_thin(x_shift, y_shift, radius, psf_sigma, height, actual_image);
    
    x_pos = centres(i,1);
    y_pos = centres(i,2);
    fits{i+1} = [x_pos, y_pos, x_centre_fit, y_centre_fit, 0, ...
        radius_fit, psf_sigma_fit.^2, height_fit, 0, 0, residual];
    fitData(i, :) = [x_pos, y_pos, x_centre_fit, y_centre_fit, 0, ...
        radius_fit, psf_sigma_fit.^2, height_fit, ...
        0, 0, residual];
end

if ~isempty(fitData)
    fitted_radius = fitData(1,6);
else
    fitted_radius = NaN;
end



% Fitted segments
fit_segments = cell(length(shell_segments));
for i = 1:length(fit_segments)
    fit = fits{i+1};
    % image_sphere_thin((x_centre, y_centre, radius, psf_sigma, height, imagemat)
    fit_image = image_sphere_thin(fit(3), fit(4), fit(6), sqrt(fit(7)), fit(8), shell_segments{i});
    fit_segments{i} = fit_image;
end

fit_tiles = tile_segments(fit_segments);

% figure(3);
% imshow(fit_tiles, [])
% title(['Fitted shells for ', 'Image'], 'interpreter', 'none')

% Save fitted shell tiles
% imwrite(mat2gray(fit_tiles), fullfile(output_dir, [image_basename, '_fits.tif']));

% Super-resolved segments
sr_segments = cell(length(shell_segments));
for i=1:length(sr_segments)
    fit = fits{i+1};
    % image_sphere_thin((x_centre, y_centre, radius, psf_sigma, height, imagemat)
    sr_image = image_sphere_thin(fit(3), fit(4), fit(6), 1, fit(8), shell_segments{i});
    sr_segments{i} = sr_image;
end

sr_tiles = tile_segments(sr_segments);
sr_recon = tile_reconstruction(sr_segments, size(image_data),centres, segment_half_size, 1); %

% figure(4);
% imshow(sr_tiles, [])
% title(['SR shells for ', 'Image'], 'interpreter', 'none')

% Display reconstruction as (non-scaled) image
% figure(5);

set(0, 'CurrentFigure', hFig);
imshow(imresize(imfuse(image_data, sr_recon),2,'nearest'), 'Border', 'tight');
% title(['Reconstructed image for', 'Image']);

% % Save fitted shell tiles
% imwrite(mat2gray(sr_tiles), fullfile(output_dir, [image_basename, '_sr.tif']));
% imwrite(mat2gray(sr_recon), fullfile(output_dir, [image_basename, '_recon.tif']));
%
% % Save fit parameters
% save(fullfile(output_dir, [image_basename, '_params.mat']), 'fits', 'fitsHdr', 'fitData', 'shell_segments');

% fid = fopen(fullfile(output_dir, [image_basename, '_params.csv']),'wt');
% fprintf(fid, [fitsHdr '\n']); % Write headers into what will be a csv
% fclose(fid);
% dlmwrite(fullfile(output_dir, [image_basename, '_params.csv']), cell2mat(fits(2:end)), '-append' )

% fits{1} = [];
% csvwrite(fullfile(output_dir, [image_basename, '_params.csv']), fits)

% Update waitbar
% waitbar(image_num / length(input_files));
% close(progress);

end
