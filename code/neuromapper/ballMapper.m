function [pts_in_bigBin, idx_bigBin] = ballMapper(dX,options)
% Function ballMapper
% Implements (a version of) the ball mapper algorithm on data
% 
% Input: 

% options    -- struct containing resolution and gain
% dfX        -- distance matrix (possibly after some filtering)

% Output:
% pts_in_bigBin -- a collection of bigBins corresponding to a cover of X
% idx_bigBin    -- indices of the chosen landmarks/bigBins in X

% Dependencies:
% -- Laurens van der Maaten's isomap code and related subdependencies.
% -- Vin de Silva's FPS code (px_maxmin.m)


% Procedure:

% -- Perform farthest point sampling. Number of landmarks for FPS 
% is determined by resolution parameter. Output of this process is an
% epsilon-cover of X.
% -- Create cover (using gain parameter along with the epsilon obtained in
% the FPS step). Return points in each element of the cover.

%% Check inputs

if nargin < 2
    error('Not enough inputs for BallMapper')
end

%% Obtain options. If a parameter is missing, switch to a default value.

resolution  = getoptions(options,'resolution',30);
gain        = getoptions(options,'gain',50);


%% Check that helper files have been loaded

if ~exist('px_maxmin.m','file')
    error('Load the "tools" folder')
end

    

%% FPS
[landmk_idx, dist_to_landmk, epsilon] = px_maxmin(dX,'metric',resolution,'n', 1,'seeds');


%% Add points to bigBins

pts_in_bigBin = cell(resolution,1);

for ii = 1:resolution
    tmp = dist_to_landmk(ii,:);
    pt_idx = tmp < max((gain/100)*(4*epsilon), eps);
    % Gain should be at least 25 to make sure we're covering the dataset
    pts_in_bigBin{ii} = find(pt_idx);
end

idx_bigBin = landmk_idx;


end

