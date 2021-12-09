function [pts_in_bigBin, bin_indices] = bdl_binning(filter_X, resolution, gain, nsides, display)
% Function bdl_binning
% Input: n-dimensional embedding of data, resolution and gain parameters
% Output: a cell array of bigBins along with indices of the data points 
% in each bin. The bigBins constitute the first binning step of mapper.

% @Samir Chowdhury
% Adapted from mapper2d_bdl_nonmetric. The "levels" in that function
% correspond to "bigBins" in this function. Note that "smallBins" is what
% we will obtain after applying partial clustering to bigBins

% @braindynamicslab [07.25.2019]
% Adapted from bdl_binning_2d_v0. 
% CHANGES:
% - allow an arbitrary number of dimensions in the filter
% TODO:
% - generalize to handle future extentions (i.e. disks based on 
%    the notion of "centers")
% - update comments from 2d case to Nd case

% @daniel hasegan [11/02/2021]
% Adapted from bdl_binning_v0 and from Manish's mapper2d_bdl_hex_binning.m
% Changes:
% - allow for non-square 2d bins

if nargin < 4
    nsides = 4;
end
if nargin < 5
    display = 0;
end

num_intervals   = resolution; % Number of intervals in each of 2 dimensions
percent_overlap = gain; % Amount of overlap between intervals 
verbose         = 1; % TODO: make this an option
 
% This function assumes that each observation in X corresponds to a 2d
% filter value. 
filter_values   = filter_X; 

% Obtain the number of points and number of filters
% (i.e. number of rows, columns in filter_values)
num_filters = size(filter_values, 2);

if nsides ~= 4
    assert(num_filters == 2, 'Can only specify nsides for dims=2');
end

% Obtain bounds (i.e. min, max) along all filters 
filter_min = min(filter_values);
filter_max = max(filter_values);

% Check that num_intervals has same shape as num_filters
if size(num_intervals,2) < num_filters
    num_intervals = repmat(num_intervals,1,num_filters);
    if verbose > 2
        disp(['num_intervals = ',num2str(num_intervals)]);
    end
end

% Check that percent_overlap has same shape as num_filters
if size(percent_overlap,2) < num_filters
    percent_overlap = repmat(percent_overlap,1,num_filters);
    if verbose > 2
        disp(['percent_overlap = ',num2str(percent_overlap)]);
    end
end

if nsides ~= 4
    percent_overlap = find_perc_overlap(percent_overlap, nsides, display) * 100;
end


% Initialize empty matrix of effective interval lengths, step_sizes
filter_length = diff([filter_min; filter_max]);
num_effective = num_intervals - (num_intervals - 1) .* percent_overlap/100;
interval_length = filter_length ./ num_effective;
  
% This part says how far you move from the left endpoint of one interval
% towards the right before hitting the left endpoint of the overlapping
% interval
step_size = interval_length .* (1 - percent_overlap/100);
   


% Initialize a variable to hold n-dimensional bin indices
dim_bin_indices = cell(size(num_intervals)); 

% Loop over each dim, tile the bin inds to match all other dimensions
for dim = 1:num_filters
    mask_dims = eye(num_filters);
    mask_dim = mask_dims(dim, :);
    new_size = mask_dim - (mask_dim - 1) .* num_intervals; 
    dim_indices = repmat(1:num_intervals(dim), new_size);
    dim_bin_indices{dim} = dim_indices;
end

% now convert to matrix, then sort rows => [1 1; 1 2] => [1 1; 2 1]
dim_bin_indices = cellfun(@(x) x(:), dim_bin_indices, 'UniformOutput', false);
bin_dim_indices = cell2mat(dim_bin_indices);


% Initialize some variables to hold num bins, bin points, etc. 
num_bigBins = prod(num_intervals);
pts_in_bigBin = cell(num_bigBins,1);
bin_indices = zeros(num_bigBins, num_filters);

if display
    figure
end

% Loop over the bigBins to get the points in each bigBin 
for bin = 1:num_bigBins 
    
    % select a particular bigBin, i.e., 2 => [1 1 2]
    bin_ind = bin_dim_indices(bin,:);
    
    % get bounding coordinates of bigBin    
    min_val_bin = filter_min + (bin_ind - 1) .* step_size;
    max_val_bin = min_val_bin + interval_length;
    
    if num_filters ~= 2
        % find the indices of the points in this bigBin
        % 1. compare values to [min; max] across dimensions
        % 2. mask points where this is true for every dimension
        pts_bin = (filter_values >= min_val_bin) & ...
                  (filter_values <= max_val_bin);
                   
        % find points where no value falls outside the bin in any dimension
        pts_bin = all(pts_bin, 2);
    else
        % Create a polygon 
        center_point = (min_val_bin+max_val_bin)./2;
        poly = nsidedpoly(nsides, 'Center', [0, 0], 'SideLength',  1);
        poly.Vertices = poly.Vertices .* interval_length + center_point;
        if display
            plot(poly)
            hold on
        end

        % Find all the points that lie inside the polygon
        pts_bin = isinterior(poly, filter_values);
    end
         
    % display progress
    if verbose > 2
        fprintf('   > Found %2d points in bin |%s|\n', sum(pts_bin), num2str(bin_ind));
    end    
    
     % continue if no points found
    if sum(pts_bin) < 1     
        continue;
    end
        
    % num_pts_bin = sum(pts_bin);
    pts_in_bigBin{bin} = find(pts_bin);
    bin_indices(bin,:) = bin_ind;
    
end

end

% Iteratively find the percentage overlap for a polygon of sides.
function sides_perc_overlap = find_perc_overlap(target_percent_overlap, sides, display)
    EPS = 1e-10;
    iter_steps = 100;

    if nargin < 3
        display = 0;
    end
    
    % binary search to find the step size
    poly1 = nsidedpoly(sides, 'Center', [0, 0], 'SideLength',  1);

    I = eye(2);
    res = zeros(1,2);
    for d=1:2
        smin = 0;
        smax = ceil(1  / sin(pi / sides));
        smid = 0;
        for i = 1:iter_steps
            smid = (smin + smax) / 2;
            C2 = I(d, :) * smid;
            poly2 = nsidedpoly(sides, 'Center', C2, 'SideLength', 1);
            pinter = intersect(poly1, poly2);
            percent = area(pinter) / area(poly1);
            if abs(percent - target_percent_overlap(d) / 100) < EPS
                if display
                    disp(['Found at iter ', num2str(i)])
                end
                break
            end
            if percent > target_percent_overlap(d) / 100
                smin = smid;
            else
                smax = smid;
            end
        end
        res(d) = smid;
    end
    sides_perc_overlap = 1 - res;
end


